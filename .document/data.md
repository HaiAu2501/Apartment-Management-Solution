# Tổ chức dữ liệu trong Firebase Database

Firestore là cơ sở dữ liệu NoSQL dựa trên mô hình collections và documents:

* Collections: Tập hợp các documents, tương tự như bảng trong SQL.
* Documents: Chứa dữ liệu dưới dạng cặp key-value, tương tự như một hàng trong bảng.

## Đối với ứng dụng Quản lý Chung cư

### Các collections chính

* `admin`: Thông tin về người quản trị hệ thống.

* `queue`: Danh sách các yêu cầu đăng ký tài khoản cư dân.

* `residents`: Thông tin về cư dân.

* `thirdParties`: Thông tin về bên thứ 3 (nhân viên bảo vệ, nhân viên vệ sinh, v.v.).

* `fees`: Thông tin về các khoản phí (tiền điện, tiền nước, phí quản lý, v.v.).

### Cấu trúc dữ liệu chi tiết

* users Collection:
  * Document ID: Sử dụng UID từ Firebase Authentication.
  * Fields:
    * `email`: String
    * `role`: String (admin, resident, third_party)
    * `status`: String (active, pending, inactive)
    * `associatedApartment`: Reference đến document trong apartments (nếu là resident)

* buildings Collection:
  * Document ID: Tạo tự động hoặc dựa trên tên tòa nhà.
  * Fields:
    * `name`: String
    * `numberOfApartments`: Number
    * `createdBy`: Reference đến users (admin)

* apartments Collection:
  * Document ID: Tạo tự động hoặc dựa trên mã căn hộ.
  * Fields:
    * `buildingId`: Reference đến buildings
    * `apartmentNumber`: String
    * `residentId`: Reference đến users (nếu đã có cư dân)
    * `status`: String (occupied, vacant)

* residents Collection:
  * Document ID: Sử dụng UID từ users collection.
  * Fields:
    * `fullName`: String
    * `phoneNumber`: String
    * `email`: String
    * `apartmentId`: Reference đến apartments
    * `additionalInfo`: Map (các thông tin bổ sung)

### Ví dụ 

```plaintext
users (collection)
├── userId1 (document)
│   ├── email: "admin@example.com"
│   ├── role: "admin"
│   └── status: "active"
├── userId2 (document)
    ├── email: "resident1@example.com"
    ├── role: "resident"
    ├── status: "active"
    └── associatedApartment: reference to apartments/apartmentId1

buildings (collection)
├── buildingId1 (document)
│   ├── name: "Tòa A"
│   ├── numberOfApartments: 100
│   └── createdBy: reference to users/userId1

apartments (collection)
├── apartmentId1 (document)
│   ├── buildingId: reference to buildings/buildingId1
│   ├── apartmentNumber: "A101"
│   ├── residentId: reference to users/userId2
│   └── status: "occupied"

residents (collection)
├── userId2 (document)
    ├── fullName: "Nguyễn Văn A"
    ├── phoneNumber: "0123456789"
    ├── email: "resident1@example.com"
    ├── apartmentId: reference to apartments/apartmentId1
    └── additionalInfo: {...}
```

## Thông tin cư dân cung cấp

Khi cư dân đăng nhập lần đầu và được yêu cầu nhập thông tin, họ sẽ cung cấp:
* Họ và tên (fullName)
* Số điện thoại (phoneNumber)
* Email (email) (nếu chưa có)
* Mật khẩu mới (thay đổi từ mật khẩu tạm thời)
* Thông tin bổ sung khác (nếu cần), ví dụ:
  * Ngày sinh (dateOfBirth)
  * Giới tính (gender)
  * Số CMND/CCCD (identityNumber)