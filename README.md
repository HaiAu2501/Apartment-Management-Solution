# Apartment Management Solution

## Mô tả đề tài

Ứng dụng Quản lý chung cư được thiết kế để hỗ trợ ba nhóm đối tượng người dùng chính: ban quản lý, cư dân và khách. Sử dụng ngôn ngữ lập trình Dart và framework Flutter, ứng dụng được xây dựng dựa trên kiến trúc Modular Monolith, kết hợp phương pháp thiết kế Domain-Driven Design để đảm bảo tính tổ chức và khả năng mở rộng.

## Phân công nhiệm vụ

| Họ và tên            | Tổng hợp công việc thực hiện                           |
|---------------------|-------------------------------------------------------|
| Lưu Thịnh Khang     | Tích hợp cơ sở dữ liệu với các chức năng của ứng dụng    |
| Nguyễn Viết Tuấn Kiệt | Thiết lập cơ sở dữ liệu, thiết kế giao diện tổng thể, đảm bảo tính đồng bộ |
| Bùi Quang Phong      | Thu thập và phân tích thông tin, xây dựng giao diện hiển thị |

## Hướng dẫn sử dụng

Truy cập đường dẫn [sau đây](https://github.com/HaiAu2501/Apartment-Management-Solution).

## Cấu trúc thư mục

```bash
lib/
├── core/
│   ├── constants/
│   ├── utils/
│   ├── themes/
│   └── widgets/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── resident_management/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── fee_management/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```