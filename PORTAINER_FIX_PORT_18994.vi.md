# SpiderFoot: đổi 5001:5001 → LAN 18994, giữ nguyên dữ liệu

**Đã phát hiện từ ảnh Portainer 24/11/2026:** Stack `spiderfoot`, một container `spiderfoot`, image `spiderfoot`, publish `5001:5001`. Nguyên nhân: Stack thực tế dùng file `docker-compose.yml` gốc thay vì `portainer-compose.yml` đã chuẩn bị.

## Các file đã sửa
- `docker-compose.yml`: thay thế Compose gốc của fork. Giữ **service `spiderfoot`**, `container_name: spiderfoot`, **image `spiderfoot`**, và **volume `spiderfoot-data`** để bảo toàn dữ liệu của Stack hiện tại. Thêm gateway Caddy và auth tự nhập. SpiderFoot chạy `18994` bên trong container, không còn listener `5001` trong config. Chỉ gateway publish **LAN_IP:18994 → gateway 80**, không publish port SpiderFoot riêng.
- `portainer-existing-image.yml`: cách thay thế qua Web editor dùng **image `spiderfoot:latest` đã có trên endpoint**, không yêu cầu clone Git hay Docker build. Chỉ áp dụng cho **Stack spiderfoot hiện hữu**, không tạo Stack trùng container name.
- `portainer-compose.yml`, `Dockerfile.portainer`, `portainer-image-only.yml`: đồng bộ port 18994 cho các cách cài khác.

## Kiểm tra bắt buộc trước khi Update
Trên **đúng Docker VM/LXC**:
```bash
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
ss -ltnp '( sport = :18994 )'
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
docker volume ls
docker image inspect spiderfoot:latest --format '{{.Id}}'
```
Nếu port 18994 đã chiếm, **không triển khai**; phải chọn port khác và cập nhật lại sổ. Có thể port 18994 đã được chuẩn bị cho SpiderFoot trước đó nhưng chưa xác minh trực tiếp.

## Cập nhật trên Portainer Android — ưu tiên GIỮ Stack đang có
1. Vào `Stacks → spiderfoot`, kiểm tra còn **một** container app và volume hiện hữu (không xóa Stack).
2. Nếu Stack dùng Git: kiểm tra repo `https://github.com/hoangthang0106/spiderfoot.git`, reference `refs/heads/main` hoặc `refs/heads/master`, Compose path `docker-compose.yml` (file này đã được sửa). Chọn **Update the stack / Pull and redeploy** theo UI Portainer sau khi chuẩn bị env. Nếu nguồn Git vẫn lỗi, xem hướng Web editor bên dưới.
3. Env variables nhập thủ công: `LAN_IP` = IP VM/LXC Docker thực, `OSINT_AUTH_USER` = tên đăng nhập, `OSINT_AUTH_PASSWORD` = mật khẩu tự đặt. Không cần hash.
4. Nếu Stack dùng Web editor: vào **Editor**, thay nội dung Compose bằng `portainer-existing-image.yml` (đừng tạo Stack mới), lưu và nhấn **Update the stack**. Phải kiểm tra image `spiderfoot:latest` thực sự có sẵn trước, giữ nguyên project name `spiderfoot`.
5. **Không dùng Re-pull image** với image địa phương `spiderfoot:latest`; không chọn Remove volumes, không dùng `down -v`.
6. Sau Update, cần thấy app `spiderfoot` Running (không có host port 5001) và container gateway publish `18994:80`. Truy cập `http://LAN_IP:18994` rồi nhập username/password.
7. Nếu Logs gateway báo Caddyfile lỗi hoặc 502, chụp Logs. Nếu Portainer nói `port is already allocated`, kiểm tra 18994 trên đúng host. Nếu có lỗi build, thử `portainer-existing-image.yml` trong editor (chỉ trên Stack hiện tại).

**Quan trọng:** thay Compose gây recreate container của Stack hiện có, dự kiến có gián đoạn ngắn; volume vẫn được giữ nếu giữ nguyên project name và volume. Kiểm tra và sao lưu trước khi Update. Không có thao tác nào trên GitHub tự cập nhật container trừ khi Portainer được cấu hình GitOps polling.
**Bảo mật:** HTTP Basic Auth trên LAN không mã hóa đường truyền. Không NAT ra Internet; cân nhắc HTTPS nội bộ trước khi sử dụng dữ liệu nhạy cảm.
