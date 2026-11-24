# SpiderFoot — Portainer Android — sửa port 5001 thành 18994

**Đây là hướng dẫn cho Stack hiện tại tên `spiderfoot` trong ảnh ngày 24/11/2026.**

## Công dụng
SpiderFoot dùng OSINT để thu thập và đối chiếu dữ liệu công khai từ email, username, số điện thoại, IP và domain. Không kết luận chắc chắn một email/phone đã đăng ký mọi nền tảng.

## Vì sao ảnh của bạn vẫn là 5001:5001?
Stack đang chạy dùng file `docker-compose.yml` gốc, trước đây public `5001:5001` với image/container `spiderfoot`. Việc chỉ sửa `portainer-compose.yml` **không thay đổi** Stack đã tạo từ file gốc.

Đã cập nhật trong fork ở cả nhánh `master` và `main`:
- **`docker-compose.yml`**: là file mặc định Stack hiện tại nhiều khả năng đang dùng, giữ service/image/container `spiderfoot` và tên volume **`spiderfoot-data`**, bỏ host publish 5001; SpiderFoot tự nghe 18994 và Caddy gateway public **`LAN_IP:18994 → 80`**.
- **`Dockerfile`**: `EXPOSE 18994`, mặc định `sf.py -l 0.0.0.0:18994`; để build image mới không mang cổng 5001.
- **`portainer-existing-image.yml`**: cách cập nhật Stack hiện hữu qua **Web editor**, dùng `image: spiderfoot:latest` đã có trên Docker host, **không build** và **không clone Git**.
- **`portainer-compose.yml`**: cho triển khai mới từ Dockerfile.portainer, cũng dùng 18994 cả ứng dụng và host port, và cùng volume `spiderfoot-data`.

## Bắt buộc: kiểm tra trước để giữ dữ liệu
Trên **VM/LXC chạy Docker** (không phải Proxmox host nếu Docker nằm trong VM/LXC):
```bash
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
ss -ltnp '( sport = :18994 )'
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
docker volume ls
docker image inspect spiderfoot:latest --format '{{.Id}}'
```
Xác minh port **18994/TCP** trống cả listener và Docker stopped bindings. Xác minh image `spiderfoot:latest` có thật nếu dùng Web editor. Xem volume đang mount ở **Containers → spiderfoot → Volumes**. **Không chọn Delete Stack/Remove volumes; không chạy `down -v`.** Nên sao lưu volume trước khi thay đổi.

## Cách 1 — Stack đã tạo từ Git và có nút Update/Pull and redeploy
1. Portainer → **Stacks → spiderfoot** (giữ nguyên Stack name).
2. Kiểm tra Git URL `https://github.com/hoangthang0106/spiderfoot.git`; branch **`refs/heads/main`** hoặc **`refs/heads/master`** (cả hai có file mới); **Compose path: `docker-compose.yml`**.
3. Environment variables trong Portainer **nhập tay**:
   - `LAN_IP`: IP thật của Docker VM/LXC.
   - `OSINT_AUTH_USER`: tên đăng nhập tự chọn.
   - `OSINT_AUTH_PASSWORD`: mật khẩu mạnh tự chọn (không hash).
   - `SPIDERFOOT_HOST_PORT` chỉ dùng khi phải đổi khỏi 18994 sau khi kiểm tra.
4. Sau khi kiểm tra port 18994 trống và đã backup, nhấn **Update the stack / Pull and redeploy**.
5. Nếu Git vẫn báo lỗi, không xóa Stack; dùng cách 2 nếu Portainer có phần Editor/Detach from Git.

## Cách 2 — Dùng Web editor trực tiếp trên Stack hiện tại
1. Portainer → **Stacks → spiderfoot → Editor**. Nếu Stack được quản lý từ Git, có thể cần **Detach from Git**, thao tác này làm mất liên kết GitOps, không tự động xóa volume nhưng cần xem rõ xác nhận trước khi bấm.
2. Mở [portainer-existing-image.yml](./portainer-existing-image.yml) bằng điện thoại, sao chép toàn bộ YAML vào **Editor** của **Stack `spiderfoot` hiện có** (không tạo Stack thứ hai vì `container_name: spiderfoot` có thể trùng).
3. Nhập ba biến `LAN_IP`, `OSINT_AUTH_USER`, `OSINT_AUTH_PASSWORD`; kiểm tra port 18994.
4. **Không bật pull latest image**: `spiderfoot:latest` đang là image local trong ảnh, không phải chắc chắn một image Docker Hub.
5. Nhấn **Update the stack** sau khi đã xác nhận. Compose sẽ thay đổi binding, tạo gateway và có thể recreate container; dữ liệu vẫn ở volume nếu giữ nguyên project/volume.
6. Kiểm tra: `spiderfoot` không có host publish 5001; `gateway` có port host **18994**, URL **`http://LAN_IP:18994`**. Nếu có lỗi xem Logs riêng từng container.

## Giới hạn
- Vẫn chưa có kiểm tra trực tiếp cổng **18994** trên Docker host, vì GitHub không thể xem các listener đang chạy.
- Không đổi port hay redeploy các ứng dụng khác khi sửa SpiderFoot.
- Caddy dùng Basic Auth qua HTTP nội bộ, **không được xem là HTTPS**. Chỉ dùng LAN/VPN tin cậy hoặc bật HTTPS nội bộ.
- Dữ liệu tài khoản/nghiên cứu cá nhân không nên lưu trong repository Git công khai. Người quản trị Docker/Portainer có thể xem biến môi trường.

Đối chiếu: [sổ port tập trung](https://github.com/hoangthang0106/thang/blob/main/ports/PORT_REGISTRY.vi.md).
