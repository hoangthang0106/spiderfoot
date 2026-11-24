# KHẮC PHỤC PORTAINER: Git "reference not found" — SpiderFoot (Android)

*Cập nhật ngày 24/11/2026. Chỉ xử lý SpiderFoot. Chưa triển khai hoặc kiểm tra port thực tế trên Docker host.*

## Chẩn đoán từ ảnh

Portainer hiển thị:
```
Failed to download git repository: unable to clone git repository:
failed to clone git repository: reference not found
```

Nguồn Git `https://github.com/hoangthang0106/spiderfoot` đúng và công khai; **Authentication None** phù hợp; **Polling Disabled** không gây lỗi clone.
Nhánh mặc định GitHub là `master`. Trước đó repository **không có** nhánh `main` nên Source/Stack có thể đang trỏ nhầm. Tôi đã tạo thêm nhánh `main` cùng commit với `master` ngày 24/11/2026; giữ nguyên `master`.

Cả hai ref sau hiện hợp lệ:
- `refs/heads/main` (mới tạo để tương thích cấu hình mặc định của một số Portainer)
- `refs/heads/master` (nhánh mặc định GitHub, **không bị xóa**)

## Tạo lại thử trên điện thoại

1. Portainer → **Environments** → chọn Docker endpoint đang sử dụng.
2. **Stacks → Add stack**. Nếu đã tạo một Git Source lỗi, hãy mở phần tạo mới; không cần xóa container nào.
3. Chọn **Repository / Git repository** (không chọn Docker Compose gốc).
4. **Name:** `osint-spiderfoot` hoặc `spiderfoot` nếu tên chưa có.
5. **Repository URL:** `https://github.com/hoangthang0106/spiderfoot.git`.
6. **Repository reference:** `refs/heads/main` (**chọn chính xác**, tránh ref cũ tự điền).
7. **Compose path:** `portainer-compose.yml` (chữ thường, ở thư mục gốc).
8. **Authentication:** None (repo public). **GitOps auto-update:** tắt trong khi cài thử.
9. **Environment variables** (nhập bằng tay, không đưa lên GitHub):
   - `LAN_IP`: IP LAN **của VM/LXC Docker**, không đoán từ URL khác.
   - `OSINT_AUTH_USER`: username tự đặt.
   - `OSINT_AUTH_PASSWORD`: mật khẩu mạnh **tự đặt**, không dùng `OSINT_AUTH_HASH`. Container tự hash mật khẩu.
   - `SPIDERFOOT_HOST_PORT`: chỉ nhập khi đã xác minh 29001 trùng và có port khác trống.
10. **Kiểm tra port 29001** trên Docker host trước khi Deploy:
    ```bash
    ss -ltnp '( sport = :29001 )'
    docker ps -a --format 'table {{.Names}}\t{{.Ports}}'
    docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
    ```
11. Sau khi xác minh IP/port và biến nhập, nhấn **Deploy the stack**.

Nếu Source cũ vẫn báo `reference not found`: hãy chỉnh ref nguồn Git sang `refs/heads/main` nếu UI có mục này, hoặc tạo nguồn Git **mới** trỏ đến cùng repo với ref main rồi thử, thay vì khởi động lại Docker/xóa các ứng dụng khác. Nếu vẫn lỗi, chụp màn hình có **Repository reference** và **Compose path** của form tạo Stack.

## Nếu qua được bước Git nhưng xuất hiện lỗi build image

`portainer-compose.yml` **build image từ mã nguồn SpiderFoot fork**. Docker endpoint qua Portainer Agent/remote có thể không build được trực tiếp từ Git, hoặc thư viện Python cũ báo lỗi. Đây là lỗi **khác** với `reference not found`.

Không chuyển sang `portainer-image-only.yml` trước khi image `local/osint-spiderfoot:portainer` được build trên **đúng Docker VM/LXC**; không pull image tên gần giống từ nguồn không rõ.

## Kết quả mong đợi

- Khi đã Deploy thành công và cả app + gateway Running: `http://LAN_IP:29001`.
- Nhập `OSINT_AUTH_USER` và `OSINT_AUTH_PASSWORD` đã đặt.
- Caddy chỉ publish cổng host `LAN_IP:29001`; SpiderFoot lắng nghe trên 5001 **bên trong Docker network**, không xung đột với cổng host 5001 của ứng dụng khác.
- **HTTP LAN Basic Auth chưa mã hóa**, chỉ dùng trong mạng tin cậy hoặc sau khi có HTTPS nội bộ; không NAT ra Internet.
- Port 29001 mới *giữ chỗ trong sổ*, chưa xác minh thực tế trống.

Đối chiếu sổ port: https://github.com/hoangthang0106/thang/blob/main/ports/PORT_REGISTRY.vi.md.
