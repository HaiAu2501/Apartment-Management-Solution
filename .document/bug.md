# Bản ghi lỗi 

Bản ghi lỗi được sử dụng để ghi lại các lỗi, vấn đề, hoặc yêu cầu hỗ trợ từ người dùng trong quá trình phát triển và vận hành ứng dụng. Mục đích của bản ghi lỗi là giúp nhóm phát triển nắm bắt và giải quyết các vấn đề một cách nhanh chóng và hiệu quả.


## Phiên bản 0.0-alpha

### 1. Thông tin đăng ký đối với bên thứ 3 

> **Mô tả:** Khi đăng ký tài khoản và người dùng chọn loại tài khoản là bên thứ 3, hệ thống vẫn yêu cầu nhập thông tin gồm tên chung cư, số tầng và số căn hộ. Trong khi đó, bên thứ 3 không cần thông tin này.

| Hành vi | Kết quả mong đợi | Kết quả thực tế | Nguyên nhân | Cách xử lý |
|---------|------------------|-----------------|------------|------------|
| Chọn loại tài khoản là bên thứ 3 | Không yêu cầu nhập thông tin về chung cư, số tầng và số căn hộ | Yêu cầu nhập thông tin về chung cư, số tầng và số căn hộ | Hệ thống chưa phân biệt rõ loại tài khoản cư dân và bên thứ 3 | Cập nhật hệ thống để phân biệt rõ loại tài khoản cư dân và bên thứ 3, chỉ yêu cầu nhập thông tin đăng ký đối với tài khoản cư dân |

**Chi tiết chỉnh sửa:**

- Trên cơ sở dữ liệu, toàn bộ người dùng (không phân biệt cư dân và bên thứ 3) được lưu trong collection `users`, mỗi document chứa trường thông tin giống nhau, điều này là không hợp lý.

- Tạo collection `residents` để lưu thông tin cư dân, collection `thirdParties` để lưu thông tin bên thứ 3.

- Mỗi document trong collection `residents` chứa các trường thông tin là: `fullName`, `gender`, `dob` (ngày tháng năm sinh), `phone`, `id` (số CCCD/CMND/hộ chiếu), `floor` (tầng), `apartmentNumber` (số căn hộ), `email` và một sub-collection `userFees` chứa thông tin về các khoản phí.

- Mỗi document trong collection `thirdParties` chứa các trường thông tin là: `fullName`, `gender`, `dob`, `phone`, `id`, `email`, `jobTitle` (chức vụ, chẳng hạn: bảo vệ, nhân viên vệ sinh, nhân viên kỹ thuật, công an, v.v.).

### 2. Hai người dùng cùng thông tin cá nhân

> **Mô tả:** Có thể tồn tại hai người dùng có thông tin cá nhân giống nhau, nhưng với email khác nhau. 

| Hành vi | Kết quả mong đợi | Kết quả thực tế | Nguyên nhân | Cách xử lý |
|---------|------------------|-----------------|------------|------------|
| Tạo tài khoản với thông tin cá nhân giống nhau | Hệ thống không cho phép tạo tài khoản mới | Hệ thống cho phép tạo tài khoản mới | Hệ thống không kiểm tra trùng lặp thông tin cá nhân | Cập nhật hệ thống để kiểm tra trùng lặp thông tin cá nhân khi tạo tài khoản mới |

**Chi tiết chỉnh sửa:**

- Khi người dùng tạo tài khoản mới, hệ thống kiểm tra trùng lặp thông tin cá nhân (số điện thoại, số CCCD/CMND/hộ chiếu) với các tài khoản đã tồn tại.

- Nếu hệ thống phát hiện trùng lặp thông tin cá nhân, thông báo lỗi và không cho phép tạo tài khoản mới.