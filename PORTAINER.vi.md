# SpiderFoot — Portainer Android — 18894:18894

**Chỉ cấu hình GitHub đã cập nhật. Không có bằng chứng port 18894/TCP thực tế trống hoặc container đã triển khai thành công trên VM/LXC Docker.**

## Công dụng

Thu thập/đối chiếu dữ liệu công khai liên quan email, username, số điện thoại, IP/domain; không xác nhận được mọi tài khoản đăng ký.

## Cấu hình

- Fork: https://github.com/hoangthang0106/spiderfoot
- Git reference: `refs/heads/main`
- Compose path: **`docker-compose.yml`** (file mặc định đã đồng bộ với `portainer-compose.yml`)
- Stack name: `spiderfoot` — GIỮ NGUYÊN tên Stack đang chạy, không tạo trùng
- **Published Ports dự kiến:** `18894:18894/tcp` trên container gateway. Ứng dụng cũng nghe `18894` bên trong Docker network, nhưng **không publish trực tiếp**.
- Host port ở trên thuộc dãy 18894–18898, tiếp sau **18893 (Synaplan Lite)** do người dùng xác nhận là cổng đã sử dụng.
- Docker Compose mặc định sử dụng lại image spiderfoot:latest và volume spiderfoot-data của Stack spiderfoot đang có, không bắt build lại. Bản ảnh trước còn chạy 5001:5001; phải UPDATE Stack hiện tại, KHÔNG tạo Stack thứ hai.

## Bước 1 — Kiểm tra đúng máy Docker, lệnh chỉ đọc

```bash
hostname -I
ss -ltnp '( sport = :18894 )'
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
```

Kiểm tra listener và cả port được khai báo cho container đang dừng; không tự kết luận từ sổ GitHub. **Không dừng dịch vụ cũ để lấy port**. Nếu 18894 bị chiếm, không Deploy; kiểm kê rồi cấp cổng khác và sửa sổ port trước.

## Bước 2 — Mở Portainer bằng điện thoại

1. Chọn đúng **Environment / Docker endpoint**.
2. Vào **Stacks → spiderfoot** đang có. Giữ Stack này và volume cũ, chỉ cập nhật thông qua Git / Editor sau khi kiểm tra và sao lưu.
3. Repository URL: `https://github.com/hoangthang0106/spiderfoot.git`.
4. Reference: `refs/heads/main`. Compose path: `docker-compose.yml`.
5. Git authentication: `None` nếu repo công khai; tắt GitOps auto-update khi thử.
6. Phần **Environment variables**: nhập tay
   - `LAN_IP` = IP LAN thật của đúng VM/LXC có Docker (không đoán theo IP đã nhắc trong cuộc trò chuyện).
   - `OSINT_AUTH_USER` = tên đăng nhập bạn tự đặt.
   - `OSINT_AUTH_PASSWORD` = mật khẩu mạnh bạn tự đặt (KHÔNG cần hash).
   - `SPIDERFOOT_HOST_PORT` = tùy chọn, **không nhập** nếu dùng 18894. Nếu phải đổi port, vế bên trong gateway vẫn là 18894 và mapping không còn N:N; cần cập nhật sổ.
7. Chỉ sau khi kiểm tra port, volume và tài nguyên, mới **Deploy / Update the stack**.

Nếu Portainer đã quản lý Stack qua Git, cập nhật nguồn Git trên Stack hiện hữu. Nếu dùng Web editor, sao chép portainer-existing-image.yml và cập nhật đúng Stack spiderfoot. Giữ nguyên project/volume; đừng Remove volumes hay Pull image local từ Docker Hub.

## Bước 3 — Xác minh sau Deploy

- Portainer → Stacks → `spiderfoot` → Containers: xem container ứng dụng và `gateway` có Running không.
- Published Ports dự kiến: gateway **`18894:18894`**; backend không publish cổng ngoài host.
- Truy cập: **`http://LAN_IP:18894`**.
- Nhập tên đăng nhập / mật khẩu tự đặt trong Environment variables.
- Nếu `reference not found`: kiểm tra URL Git, ref và Compose path. `port is already allocated`: kiểm tra đúng Docker host. `502 Bad Gateway`: đọc logs backend. Lỗi build: xem Dockerfile và Docker endpoint.

**Bảo mật:** Caddy Basic Auth qua HTTP LAN chưa mã hóa, đừng NAT ra Internet hoặc dùng mạng không tin cậy. Người có quyền quản trị Docker/Portainer có thể đọc biến môi trường. Đừng đưa mật khẩu, email, số điện thoại cá nhân hay API key lên GitHub công khai.

[Sổ quản lý port tập trung](https://github.com/hoangthang0106/thang/blob/main/ports/PORT_REGISTRY.vi.md). Cổng tiếp theo dự kiến là **18899**, chỉ cấp sau khi kiểm tra thực tế.
