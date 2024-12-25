# Giải Pháp Quản Lý Chung Cư

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Tính Năng Chính](#tính-năng-chính)
   - [Dành cho Ban Quản Lý](#dành-cho-ban-quản-lý)
   - [Dành cho Cư Dân](#dành-cho-cư-dân)
   - [Dành cho Khách](#dành-cho-khách)
3. [Phân Công Nhiệm Vụ](#phân-công-nhiệm-vụ)
4. [Bắt Đầu](#bắt-đầu)
   - [Yêu Cầu Tiên Quyết](#yêu-cầu-tiên-quyết)
   - [Cài Đặt](#cài-đặt)
5. [Cấu Trúc Thư Mục](#cấu-trúc-thư-mục)
6. [Giới Thiệu Các Mô-đun](#giới-thiệu-các-mô-đun)
   - [Core](#core)
   - [Features](#features)
7. [Hướng Dẫn Phát Triển](#hướng-dẫn-phát-triển)
   - [Chiến Lược Nhánh](#chiến-lược-nhánh)
   - [Quy Chuẩn Viết Mã](#quy-chuẩn-viết-mã)
8. [Đóng Góp](#đóng-góp)
9. [Giấy Phép](#giấy-phép)

---

## Tổng Quan

Giải pháp Quản Lý Chung Cư là một ứng dụng toàn diện được thiết kế để phục vụ 3 nhóm người dùng chính:
1. **Ban Quản Lý**: Quản lý công việc hành chính và vận hành.
2. **Cư Dân**: Truy cập dịch vụ và thông tin quan trọng.
3. **Khách**: Bao gồm công an, nhân viên vệ sinh, bảo vệ và các khách tham quan khác.

Ứng dụng được phát triển bằng **Dart** và framework **Flutter**, vận hành theo kiến trúc Modular Monolith và áp dụng nguyên tắc **Domain-Driven Design (DDD)** để đảm bảo tính mở rộng và bảo trì.

## Tính Năng Chính

### Dành cho Ban Quản Lý:
- **Bảng Điều Khiển**: Truy cập nhanh các thông tin và tóm tắt quan trọng.
- **Quản Lý Người Dùng**: Quản lý hồ sơ cư dân và khách.
- **Quản Lý Phí**: Quản lý các khoản thu chi và tình hình tài chính.
- **Xử Lý Khiếu Nại**: Tiếp nhận và theo dõi tiến trình giải quyết khiếu nại.
- **Quản Lý Sự Kiện**: Tổ chức và hiển thị các sự kiện cộng đồng.

### Dành cho Cư Dân:
- **Thông Báo**: Nhận thông báo và cập nhật quan trọng.
- **Thanh Toán**: Xem và thanh toán các khoản phí ngay trong ứng dụng.
- **Gửi Phản Hồi**: Khiếu nại hoặc gửi góp ý kiến.
- **Tham Gia Sự Kiện**: Đăng ký tham gia và xem chi tiết các sự kiện cộng đồng.

### Dành cho Khách:
- **Kiểm Soát Truy Cập**: Quá trình check-in và check-out nhanh chóng cho nhân viên được phép.

## Phân Công Nhiệm Vụ

| Họ và Tên            | Nhiệm vụ                                           |
|------------------------|--------------------------------------------------|
| **Lưu Thịnh Khang**   | Tích hợp cơ sở dữ liệu và các chức năng trong ứng dụng. |
| **Nguyễn Viết Tuấn Kiệt** | Thiết lập cơ sở dữ liệu, thiết kế giao diện tổng thể và đảm bảo tính đồng bộ. |
| **Bùi Quang Phong**    | Thu thập thông tin, phân tích và phát triển giao diện hiển thị.      |

## Bắt Đầu

### Yêu Cầu Tiên Quyết

Hãy đảm bảo cài đặt các công cụ sau:
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- Trình soạn thảo mã (vd: [Visual Studio Code](https://code.visualstudio.com/))

### Cài Đặt

1. Clone repository:
   ```bash
   git clone https://github.com/HaiAu2501/Apartment-Management-Solution.git
   cd Apartment-Management-Solution
   ```

2. Cài đặt các thư viện phụ thuộc:
    ```bash
    flutter pub get
    ```

3. Chạy ứng dụng:
    ```bash
    flutter run
    ```

## Cấu Trúc Thư Mục

```
lib/
├── core/
│   ├── constants/
│   ├── utils/
│   ├── themes/
│   └── widgets/
├── features/
│   ├── .authentication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── admin/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── resident/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── guest/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

## Giới Thiệu Các Mô-đun

### Core

Chứa các tài nguyên chia sẻ như constants, hàm tiện ích, themes và các widgets dùng chung.

### Features

* Authentication: Quản lý đăng nhập và xác thực người dùng.
* Admin Management: Quản lý thông tin hệ thống và xử lý các chức năng quản trị.
* Resident Management: Quản lý thông tin cư dân và hộ gia đình.
* Guest Management: Xử lý thông tin khách và kiểm soát truy cập.
* Fee Management: Hiển thị tóm tắt phí, lịch sử thanh toán và báo cáo tài chính.
* Notifications: Gửi thông báo quan trọng đến người dùng.

## Hướng Dẫn Phát Triển

### Chiến Lược Nhánh

* Sử dụng nhánh main cho mã nguồn đã sẵn sàng sản xuất.
* Phát triển tính năng mới trong các nhánh `feature/<ten-tinh-nang>`.
* Gửi pull request để xem xét trước khi gộp nhánh.

### Quy Chuẩn Viết Mã

* Sử dụng Dart và Flutter theo quy chuẩn [Effective Dart](https://dart.dev/guides/language/effective-dart).
* Đảm bảo các thành phần giao diện tương thích và đáp ứng tốt với nhiều kích thước màn hình.

## Đóng Góp

Chúng tôi hoan nghênh các đóng góp để cải thiện dự án! Vui lòng:

1. Fork repository.
2. Tạo nhánh cho tính năng.
3. Commit thay đổi với tin nhắn miêu tả chi tiết.
4. Gửi pull request.

## Giấy Phép

Dự án này được cấp phép theo giấy phép MIT. Xem tệp `LICENSE` để biết thêm chi tiết.