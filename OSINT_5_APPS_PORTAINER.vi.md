# BỘ 5 OSINT WEB — PROXMOX / DOCKER / PORTAINER

**Sổ port chính:** https://github.com/hoangthang0106/thang/blob/main/ports/PORT_REGISTRY.vi.md (mỗi lần cài app mới cần kiểm tra và cập nhật sổ).\n\nĐã tạo Compose riêng **trong từng fork** trên nhánh `portainer-lan`. Không chỉnh Compose upstream, không có port hoặc mật khẩu mới nào được cấu hình trên VM/LXC thực tế.

## Cài lần lượt, không Deploy cùng lúc khi chưa kiểm tra tài nguyên

| Thứ tự | Git Repository | Port host mặc định (ứng viên) | Internal | Build? |
|---|---|---:|---:|---|
| 1 | [SpiderFoot](https://github.com/hoangthang0106/spiderfoot/tree/portainer-lan) | **29001** | 5001 | Có |
| 2 | [OpenOSINT](https://github.com/hoangthang0106/OpenOSINT/tree/portainer-lan) | **29002** | 8080 | Có |
| 3 | [Maigret](https://github.com/hoangthang0106/maigret/tree/portainer-lan) | **29003** | 5000 | Không |
| 4 | [PhoneInfoga](https://github.com/hoangthang0106/phoneinfoga/tree/portainer-lan) | **29004** | 5000 | Không |
| 5 | [Social Analyzer](https://github.com/hoangthang0106/social-analyzer/tree/portainer-lan) | **29005** | 9005 | Có |

Đã thấy trong hồ sơ IT-MANAGER: QRForge 18889 (có URL), qrframe 18890 (cấu hình), n8n 18891 (dự kiến), Immich 18892 (cấu hình), Stirling-PDF 18993 (dự kiến), GLPI 9090, Snipe-IT 8080, IT Knowledge Hub 8787, Caddy 8088, Portainer 9443/9000/9001, Proxmox 8006. **Không xác nhận bất cứ port nào đang chạy.** Các port 29001–29005 được giữ chỗ trong GitHub (chưa kiểm tra thực tế). **29006 là số tiếp theo dự kiến** cho OSINT; ứng dụng web mới khác sử dụng **29100** trở đi sau khi kiểm tra.

## Kiểm kê không sửa máy chủ

Script [CHECK_PORTS.sh](./CHECK_PORTS.sh) chỉ chạy `docker ps`, `docker inspect`, `ss`, `ip`; không dừng/start/xóa container. Xem nội dung trước khi chạy.

## Nhập tay trong Portainer

Mỗi fork đều sử dụng:
- **Git branch:** `refs/heads/portainer-lan`
- **Compose path:** `portainer-compose.yml` (hoặc `portainer-image-only.yml` sau khi build tay nếu Portainer dùng remote Agent)
- **Variables:** `LAN_IP` (IP thật VM/LXC Docker), `OSINT_AUTH_USER` (tên đăng nhập), `OSINT_AUTH_HASH` (bcrypt hash password), một biến riêng `*_HOST_PORT` nếu phải đổi cổng.

Để tạo bcrypt hash mà **không đặt mật khẩu trên command line**: `docker run --rm -it caddy:2 caddy hash-password --algorithm bcrypt` rồi nhập password khi được hỏi. Dán hash vào Portainer; khi mở website sẽ gõ mật khẩu gốc.

**Lưu ý:** Basic Auth qua HTTP chỉ phù hợp mạng LAN tin cậy; không mở NAT. Nếu tra cứu dữ liệu nhạy cảm, nên bảo vệ kết nối bằng HTTPS nội bộ, firewall/VPN. Caddy gateway là một container nhỏ nằm trong mỗi Stack, không thay đổi Caddy hiện có.

## Luồng triển khai

1. Kiểm tra đúng Docker endpoint và RAM/dung lượng.
2. Chạy các lệnh chỉ đọc trong README của từng fork, xem ứng viên host port có trống trên IP LAN không; kiểm tra cả port khai báo của container đang dừng.
3. Cài SpiderFoot, kiểm tra Logs và UI. Làm tương tự với các bước 2 → 5 sau khi xác nhận đủ tài nguyên.
4. Các image cần build: nếu Portainer remote không hỗ trợ `build:`, xem cách build thủ công ở `PORTAINER.vi.md` của repo, dùng `portainer-image-only.yml` sau khi build. Không cố chuyển qua image ngẫu nhiên.
5. Không nhập bất kỳ mật khẩu hoặc API key nào vào repository công khai. Không tự động quét đối tượng hoặc triển khai Docker từ GitHub.

**Giới hạn thực tế:** Maigret, Social Analyzer chủ yếu tra username; PhoneInfoga tập trung phone metadata; SpiderFoot và OpenOSINT kết hợp nhiều nguồn. Không công cụ nào chứng minh email/phone đăng ký *tất cả* nền tảng. Trạng thái hiện tại chỉ là **đã tạo code trên GitHub**, không phải đã vận hành trên máy bạn.
