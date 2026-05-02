# THÔNG SỐ KỸ THUẬT VÀ PHƯƠNG THỨC GIAO TIẾP UART - WATCHDOG & GCD SYSTEM

Tài liệu này hướng dẫn chi tiết cách sử dụng giao diện UART để cấu hình, điều khiển và giám sát hệ thống Watchdog tích hợp module GCD trên mạch FPGA.

## 1. Thông số cấu hình UART
- **Baudrate:** 115200 bps
- **Data bits:** 8
- **Stop bits:** 1
- **Parity:** None
- **Flow Control:** None

## 2. Cấu trúc Gói tin (Protocol Frame)
Hệ thống sử dụng gói tin cố định **9 byte** để đảm bảo tính đồng bộ và an toàn dữ liệu.

| Byte STT | Tên trường | Mô tả |
|:---:|:---|:---|
| 0 | Header | Luôn là **0x55** |
| 1 | CMD | Mã lệnh (01: Write, 02: Read, 03: Kick, 04: Status, 05: GCD Start) |
| 2 | ADDR | Địa chỉ thanh ghi đích |
| 3 | LEN | Độ dài dữ liệu (Mặc định là 0x04 cho 32-bit) |
| 4 | DATA_B3 | Byte dữ liệu cao nhất (MSB) |
| 5 | DATA_B2 | Byte dữ liệu thứ 2 |
| 6 | DATA_B1 | Byte dữ liệu thứ 3 |
| 7 | DATA_B0 | Byte dữ liệu thấp nhất (LSB) |
| 8 | CHECKSUM | Phép toán XOR từ Byte 1 đến Byte 7 |

---

## 3. Bản đồ Địa chỉ Thanh ghi (Register Map)
| Địa chỉ (HEX) | Tên | Chức năng |
|:---:|:---|:---|
| **0x00** | CTRL | Thanh ghi điều khiển (Bit 0: Enable, Bit 2: Clear Fault) |
| **0x04** | TWD | Thời gian chờ Watchdog (ms) |
| **0x08** | TRST | Thời gian giữ tín hiệu Reset (ms) |
| **0x0C** | ARM | Thời gian chờ khởi động an toàn (us) |
| **0x10** | STATUS | Đọc trạng thái các chân I/O và lõi Watchdog |
| **0x14** | GCD_A | Số hạng A cho phép tính GCD |
| **0x18** | GCD_B | Số hạng B cho phép tính GCD |
| **0x1C** | GCD_RES | Kết quả tính toán GCD (Chỉ đọc) |

---

## 4. Các lệnh điều khiển Watchdog
Dưới đây là các chuỗi mã HEX mẫu đưa vào phần mềm Terminal để giao tiếp với Watchdog:

| Chức năng | Chuỗi mã HEX | Ý nghĩa |
|:---|:---|:---|
| **Bật Watchdog** | `55 01 00 04 00 00 00 01 04` | Kích hoạt hệ thống giám sát |
| **Tắt Watchdog** | `55 01 00 04 00 00 00 00 05` | Vô hiệu hóa watchdog |
| **Nuôi chó (Kick)** | `55 03 00 04 00 00 00 00 07` | Lệnh tương đương bấm nút S1 |
| **Đặt tWD = 1s** | `55 01 04 04 00 00 03 E8 E9` | Đặt timeout là 1000ms |
| **Đặt tRST = 5s** | `55 01 08 04 00 00 13 88 96` | Giữ đèn báo lỗi trong 5 giây |
| **Xóa lỗi ngay** | `55 01 00 04 00 00 00 05 00` | Nhả Reset (WDO) ngay lập tức |

---

## 5. Các lệnh điều khiển module GCD
Quy trình thực hiện qua UART để tính GCD(48, 18):

1. **Ghi A = 48:** `55 01 14 04 00 00 00 30 21`
2. **Ghi B = 18:** `55 01 18 04 00 00 00 12 0F`
3. **Lệnh Start:** `55 05 00 04 00 00 00 00 01`
4. **Nhận kết quả:** FPGA sẽ tự động trả về gói tin: `55 05 1C 04 00 00 00 06 1B` (Giá trị 0x06).

---

## 6. Giải mã Trạng thái hệ thống (Status Decoding)
Khi gửi lệnh Đọc Status (`55 04 10 04 00 00 00 00 10`), hãy nhìn vào **Byte thứ 7** trong gói tin phản hồi. Đổi giá trị HEX này sang nhị phân (8 bit) để kiểm tra:

### 6.1. Bảng ý nghĩa các Bit
| Bit | Tên tín hiệu | Trạng thái khi = 1 | Trạng thái khi = 0 |
|:---:|:---:|:---|:---|
| **0** | **EN_Eff** | Watchdog **ĐANG CHẠY** (Đang đếm ngược) | Watchdog đang nghỉ (Tắt) |
| **1** | **Fault** | **CÓ LỖI** (Hết thời gian nuôi) | Hệ thống an toàn (Không lỗi) |
| **2** | **ENOUT** | Cổng ENOUT cho phép tải hoạt động | Cổng ENOUT ngắt tải |
| **3** | **WDO** | Chân Reset ở mức cao (Bình thường) | **ĐANG RESET** thiết bị (Mức thấp) |

### 6.2. Các mã HEX trạng thái thường gặp
- **`08` (0000 1000):** Watchdog đang **TẮT**, chân WDO bình thường (Mức 1). Đây là trạng thái mặc định khi vừa khởi động.
- **`0D` (0000 1101):** Watchdog **ĐANG CHẠY** bình thường, mọi thứ ổn định.
- **`03` (0000 0011):** **đang RESET.** Hệ thống báo lỗi và đang trong giai đoạn duy trì tín hiệu Reset (**tRST**), chân WDO bị kéo xuống mức 0.
- **`0B` (0000 1011):** **sau RESET.** Giai đoạn tRST đã kết thúc, chân WDO đã nhả về mức 1 để thiết bị khởi động lại, nhưng hệ thống vẫn treo cờ lỗi (Fault=1) để cảnh báo.

---


