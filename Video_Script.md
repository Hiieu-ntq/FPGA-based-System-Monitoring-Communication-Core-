# Kịch Bản Quay Video Demo Hệ Thống MissU SoC

## 🎬 Thông tin chuẩn bị (Setup)
*   **Thiết bị:** Mạch **Gowin-Kiwi-1P5**, cáp USB Type-C, Máy tính.
*   **Phần mềm PC:** Mở phần mềm Terminal UART (như Hercules, Docklight...). Cài đặt Baudrate `115200`. Lưu sẵn mã Hex của các lệnh để copy/paste hoặc bấm gửi cho nhanh.
*   **Góc quay:** Dùng điện thoại quay từ trên xuống, khung hình bao gồm nửa trên là màn hình máy tính (hiển thị Terminal), nửa dưới là bo mạch Gowin (thấy rõ 2 nút nhấn và 2 đèn LED xanh lá).

---

## 🎥 KỊCH BẢN CHI TIẾT

### 📍 Scene 1: Giới thiệu hệ thống (0:00 - 0:20)
*   **Hành động:** Quay bao quát tổng thể mạch cắm vào PC. Chỉ ngón tay hoặc bút vào các thành phần trên mạch: Nút `btn_wdi`, nút `btn_en`, và 2 đèn LED xanh lá (`led_wdo` và `led_enout`).
*   **Phụ đề / Thuyết minh:** 
    > "Chào thầy cô, đây là hệ thống System-on-Chip (SoC) 'MissU' tích hợp Hardware Watchdog và gia tốc GCD trên FPGA Gowin-Kiwi-1P5. Giao tiếp với máy tính hoàn toàn qua giao thức UART tốc độ 115200 bps."

### 📍 Scene 2: Demo tính năng Giám sát & Xử lý khi có Lỗi (Timeout) (0:20 - 0:50)
*   **Hành động:** 
    1. Bấm nút `btn_en` (hoặc gửi lệnh từ PC) để bật hệ thống. Trỏ tay vào đèn `led_enout` đang **sáng màu xanh lá**, báo hiệu Watchdog đang trong trạng thái giám sát bình thường.
    2. Rút tay ra, **cố tình không tác động gì thêm**. Đồng hồ bấm giờ trên video đếm ~1.6 giây.
    3. Hiện tượng xảy ra: Đèn `led_enout` lập tức **tắt ngấm**. Đèn `led_wdo` kế bên bắt đầu **nhấp nháy màu xanh lá**.
*   **Phụ đề / Thuyết minh:** 
    > "Giả lập trường hợp phần mềm bị treo. Hệ thống không nhận được tín hiệu làm mới (Kick). Đúng sau 1600ms (Timeout), lõi phần cứng lập tức phản ứng: Tắt tín hiệu hoạt động (led_enout tắt) và phát xung cảnh báo lỗi liên tục (led_wdo nhấp nháy)."

### 📍 Scene 3: Demo tính năng Khóa an toàn & Nạp lại (KICK) chống lỗi (0:50 - 1:30)
*   **Hành động:**
    1. **(Test Khóa an toàn):** Trong lúc hệ thống đang báo lỗi (Timeout), cố tình lấy tay bấm nút KICK (`btn_wdi`). Trỏ tay chỉ vào mạch: Đèn `led_enout` VẪN TẮT ngấm, đèn báo lỗi vẫn nhấp nháy.
    2. Gửi gói tin lệnh `CLR_FAULT` (từ máy tính) để xóa lỗi. Trạng thái mới trở lại bình thường (`led_enout` sáng xanh lại, `led_wdo` tắt hẳn).
    3. **(Test Hard-Kick):** Lấy tay bấm đều đặn nút `btn_wdi` khoảng 1 giây/lần. Quan sát: Đèn `led_enout` luôn sáng ổn định, KHÔNG xảy ra Timeout.
    4. **(Test Soft-Kick):** Dừng bấm nút. Quay sát màn hình máy tính, nhấp liên tục nút gửi mã Hex lệnh Command `0x03` (KICK WDT) từ phần mềm Terminal. Quay lại mạch: Hệ thống vẫn duy trì ổn định.
*   **Phụ đề / Thuyết minh:** 
    > "Khi Timeout đã xảy ra, cơ chế Khóa an toàn (Fault Latch) được kích hoạt. Việc cố tình bấm nút KICK vật lý lúc này là vô tác dụng (led_enout vẫn tắt). Bắt buộc phải gửi lệnh CLR_FAULT từ hệ thống giám sát trung tâm để khôi phục. Sau khi khôi phục, ta có thể duy trì hệ thống bằng cách Kick vật lý hoặc Soft-Kick qua UART."

### 📍 Scene 4: Demo Khối gia tốc phần cứng GCD (1:30 - 2:10)
*   **Hành động:** (Cảnh này tập trung chủ yếu vào màn hình PC hiển thị log UART).
    1. Gửi lệnh Write (Cmd `0x01`): Nạp số 24 (Hex: `0x18`) vào thanh ghi `GCD_A`.
    2. Gửi lệnh Write (Cmd `0x01`): Nạp số 36 (Hex: `0x24`) vào thanh ghi `GCD_B`.
    3. Gửi lệnh Start (Cmd `0x05`).
    4. Phóng to (Zoom) vào khung Receive của Terminal. Bôi đen gói tin UART trả về ngay lập tức, trong đó chứa byte kết quả là `0x0C` (tương đương giá trị 12).
*   **Phụ đề / Thuyết minh:** 
    > "Kiểm thử luồng dữ liệu song song với bộ tính GCD. Nạp 2 số 24 và 36. Ngay khi gửi lệnh START (0x05), khối Hardware Accelerator lập tức tính toán và phản hồi kết quả Ước chung lớn nhất là 12 qua cổng UART TX."

### 📍 Scene 5: Lời kết (2:10 - 2:20)
*   **Hành động:** Quay lại toàn cảnh hệ thống đang sáng đèn ổn định.
*   **Phụ đề / Thuyết minh:** 
    > "Hệ thống phản hồi thời gian thực, giao thức Command ổn định và tối ưu tài nguyên tốt trên Gowin FPGA. Cảm ơn thầy cô đã theo dõi!"

---
### 💡 Mẹo nhỏ khi quay video kỹ thuật:
1.  **Đừng thu âm trực tiếp:** Tiếng lạch cạch chuột phím và quạt máy tính rất ồn. Hãy quay toàn bộ video không có tiếng, sau đó dùng phần mềm (như Capcut) để chèn **nhạc nền nhỏ + Dòng chữ phụ đề (Subtitles)** chạy bên dưới. Cực kỳ chuyên nghiệp!
2.  Hãy chuẩn bị sẵn một file `.txt` chứa các chuỗi Hex của các lệnh `CLR_FAULT`, `KICK`, `WRITE GCD_A`, `WRITE GCD_B`, `START GCD`. Khi quay chỉ cần copy-paste để gửi nhanh, tránh gõ nhầm mất thời gian.
