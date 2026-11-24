# SpiderFoot — Cài qua Portainer Git (mạng LAN)

Dùng fork [hoangthang0106/spiderfoot](https://github.com/hoangthang0106/spiderfoot), nhánh **`portainer-lan`**; không thay đổi Compose gốc.
**Cổng 18994/TCP là đề xuất chưa kiểm tra trên VM/LXC thật.** Backend nội bộ 5001/TCP không public.

## 1. Kiểm tra trước bằng lệnh chỉ đọc trên đúng VM/LXC Docker

```bash
hostname -I
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose ls -a
sudo ss -lntup
sudo ss -ltnp '( sport = :18994 )'
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
```

Không coi port trống nếu chưa xem listener và port được đặt cho container đang dừng. Nếu 18994 trùng, đặt `SPIDERFOOT_HOST_PORT` thành cổng TCP khác đã xác minh trống. Không dừng/xóa container cũ.

## 2. Tạo mật khẩu đã băm bằng Caddy

Trên Docker host, người quản trị **chủ động chạy** `docker run --rm -it caddy:2 caddy hash-password --algorithm bcrypt` và nhập mật khẩu khi chương trình hỏi (không ghi mật khẩu trong lệnh hoặc Git).
Sao chép chuỗi bcrypt (`$2a$` hoặc `$2b$`) để nhập vào Portainer. **OSINT_AUTH_HASH là hash, không phải mật khẩu thuần.**

## 3. Portainer → Stacks → Add stack → Repository

- **Stack name:** `osint-spiderfoot`
- **Repository URL:** `https://github.com/hoangthang0106/spiderfoot`
- **Reference:** `refs/heads/portainer-lan`
- **Compose path:** `portainer-compose.yml`
- **Environment variables** (nhập tay trước Deploy):
  - `LAN_IP`: IP thật trên interface của VM/LXC đang chạy Docker, không mặc định dùng IP Proxmox host.
  - `OSINT_AUTH_USER`: username dùng để mở web UI (ví dụ `itadmin`).
  - `OSINT_AUTH_HASH`: chuỗi bcrypt vừa tạo.
  - `SPIDERFOOT_HOST_PORT`: **tùy chọn**, chỉ nhập nếu cần đổi host port 18994.

**Có bước build image từ fork:** Repo dùng `build:` (context thư mục gốc). Portainer ở remote endpoint có thể **không hỗ trợ** build theo Compose. Nếu thất bại, không tự thay đổi service cũ; cần build image trên đúng VM/LXC bằng lệnh Docker Compose hoặc cấu hình Portainer local Docker endpoint, rồi Deploy lại. Hãy xem Logs trước khi xử lý. Dockerfile gốc dùng Alpine 3.12/3.13; Dockerfile.portainer dùng Python 3.11, tuy nhiên dependency cũ có thể gặp lỗi cần xem log.

## 4. Kiểm tra sau khi Deploy (chỉ khi đã chủ động xác nhận)

- Đợi cả container ứng dụng và **gateway** Running, xem **Logs** nếu có lỗi.
- Mở **http://LAN_IP:18994** (thay port nếu đã đổi), nhập username và **mật khẩu gốc** bạn dùng tạo hash.
- Kiểm tra khả năng truy vấn dữ liệu bạn sở hữu hoặc được ủy quyền. Không có công cụ nào biết hết nền tảng mà một email/số điện thoại đã đăng ký.

## 5. Bảo mật & giới hạn

Gateway dùng Caddy `basic_auth`, backend không publish `ports:` ra host. Tuy nhiên **HTTP Basic Auth trên mạng LAN không mã hóa**; không mở cổng ra Internet, cần firewall giới hạn LAN; khi sử dụng dữ liệu nhạy cảm hãy chuyển sang HTTPS nội bộ. Người có quyền quản trị Portainer/Docker có thể xem biến môi trường. Không lưu khóa API, bí mật, dữ liệu nhạy cảm trong fork công khai.
SpiderFoot có thể dùng nhiều mô-đun chủ động; xem xét loại truy vấn và nguồn dữ liệu trước khi bật quét.
Dữ liệu ở Docker named volume (nếu có) không tự được backup. Không xóa volume hoặc bật tự cập nhật mà chưa kiểm tra. **Đây chỉ là cấu hình trên GitHub, không phải xác nhận máy chủ đã triển khai.**
