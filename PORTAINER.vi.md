# SpiderFoot trên Portainer Android — một container, không có reverse proxy

**Đã sửa cấu hình trong fork. Chưa cập nhật container đang chạy trên máy thực.**

## Công dụng
SpiderFoot thu thập và đối chiếu dữ liệu OSINT công khai qua email, username, domain, IP, số điện thoại và các nguồn liên quan. Không chứng minh được toàn bộ tài khoản của một cá nhân.

## Cấu hình đang dùng
- Git repository: `https://github.com/hoangthang0106/spiderfoot.git`
- Git branch: `refs/heads/main` (hoặc `refs/heads/master`).
- Git compose path: **`docker-compose.yml`**.
- Docker image: **`spiderfoot:latest`** (image local đã thấy trong ảnh).
- Stack: **`spiderfoot`** (giữ tên).
- Số container mong muốn sau cập nhật: **1 — `spiderfoot`**.
- Host publish: **`LAN_IP:18894 -> SpiderFoot:18894/tcp`**, không có host 5001.
- Volume giữ nguyên: **`spiderfoot-data:/var/lib/spiderfoot`**, giữ dữ liệu/scan.
- **Xác thực:** SpiderFoot đã có native HTTP Digest authentication, tự đọc `/var/lib/spiderfoot/passwd`. Compose ghi `username:password` vào file volume bằng quyền 0600 ở mỗi lần khởi động; không cần container proxy.
- Không tự cài đặt thêm container, gateway, web server.

## Trước khi Update Stack (bắt buộc)
Chạy trên **VM/LXC Docker thực tế**, các lệnh chỉ đọc:
```bash
hostname -I
ss -ltnp '( sport = :18894 )'
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
docker inspect spiderfoot --format '{{json .Mounts}}'
```
Nếu cổng 18894 có listener hoặc binding của container khác, **không Update** trước khi chọn port trống và sửa sổ port. Xác minh volume có dữ liệu, nên sao lưu nếu quan trọng. Không xóa Stack/volume cũ.

## Cập nhật bằng điện thoại
1. Portainer → **Stacks → spiderfoot** (Stack đang chạy, đừng tạo Stack thứ hai).
2. **Managed by Git**: `https://github.com/hoangthang0106/spiderfoot` → `refs/heads/main` → **`docker-compose.yml`**. Nếu file khác, sửa `Edit stack settings` về đúng file.
3. Environment variables trong Stack (không ghi vào GitHub): 
   - `LAN_IP`: địa chỉ LAN thực tế trên VM/LXC chạy Docker.
   - `OSINT_AUTH_USER`: username do bạn tự chọn.
   - `OSINT_AUTH_PASSWORD`: mật khẩu mạnh bạn tự đặt. Không cần hash.
   - `SPIDERFOOT_HOST_PORT`: chỉ cần nếu 18894 không dùng được, sau khi đã kiểm tra.
4. Sau khi kiểm tra port trống và backup, chọn **Pull and redeploy / Update the stack**. **Không bật luôn pull image `spiderfoot:latest` nếu đó là image local**, không xóa volumes. Update sẽ tái tạo container (có gián đoạn ngắn).
5. Kiểm tra **Containers**. `spiderfoot` Running, Published Ports `18894:18894`. Không còn gateway trong Stack.
6. Nếu `spiderfoot-gateway-1` vẫn tồn tại ngoài Stack như container mồ côi, xác minh nó chỉ thuộc SpiderFoot cũ trước khi chủ động dừng/xóa đúng container đó; không xóa bất kỳ volume nào.
7. Android trong cùng LAN: mở `http://LAN_IP:18894`, nhập username/password đã chọn. Nếu không thấy màn hình login, xem `Containers → spiderfoot → Logs`, tìm thông báo `Enabling authentication based on supplied passwd file`.

Nếu Portainer Git Clone tiếp tục lỗi, **không xóa Stack**: xem file [portainer-existing-image.yml](./portainer-existing-image.yml) dùng Web editor của Stack hiện tại (không cần build, dùng image local đã có).

## Bảo mật
- SpiderFoot native Digest auth dùng file **username:password dạng plaintext** trong volume (quyền 0600 theo shell `umask 077`); người có quyền Docker/root vẫn đọc được. Password cũng đi qua biến môi trường Docker.
- HTTP Digest bảo vệ mật khẩu hơn HTTP Basic, nhưng **không mã hóa dữ liệu web**; chỉ truy cập LAN tin cậy, nên dùng HTTPS/VPN nếu nội dung nhạy cảm.
- Không NAT 18894 ra Internet.
- Không tự động cập nhật container chỉ vì file trên GitHub thay đổi (trừ khi GitOps auto update đang bật).

**Trạng thái:** GitHub đã đổi cấu hình; **ảnh cuối cho thấy hệ thống còn 2 container**, chưa có ảnh xác nhận sau khi cập nhật.
