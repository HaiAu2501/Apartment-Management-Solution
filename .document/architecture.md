# Kiến trúc ứng dụng

Kiến trúc ứng dụng là cách tổ chức và cấu trúc các thành phần bên trong một ứng dụng phần mềm, bao gồm:

* Các module: Các phần nhỏ hơn của ứng dụng có thể tái sử dụng.
* Thành phần giao tiếp: Cách các module và dịch vụ trao đổi dữ liệu với nhau.
* Mối quan hệ giữa các phần: Xác định cách các phần của ứng dụng tương tác và hỗ trợ lẫn nhau.

## Giới thiệu các kiến trúc ứng dụng phổ biến

**1. Monolithic Architecture (Kiến trúc nguyên khối)**

* Toàn bộ ứng dụng được triển khai dưới dạng một khối duy nhất. Tất cả các thành phần như giao diện người dùng, logic nghiệp vụ, truy cập dữ liệu, và các dịch vụ khác đều nằm trong một ứng dụng duy nhất.

* Tương tác nội bộ trong ứng dụng diễn ra trực tiếp, không qua giao tiếp qua mạng hay giao thức riêng.

**2. Microservices Architecture (Kiến trúc vi dịch vụ)**

* Chia ứng dụng thành nhiều dịch vụ nhỏ độc lập, mỗi dịch vụ phụ trách một phần của nghiệp vụ.

* Các dịch vụ này giao tiếp thông qua API, thường là qua các giao thức HTTP, gRPC, hoặc các hệ thống message broker như Kafka hoặc RabbitMQ.

* Mỗi dịch vụ có thể được phát triển bằng ngôn ngữ lập trình khác nhau và sử dụng cơ sở dữ liệu riêng biệt, cho phép sự linh hoạt tối đa.

**3. Modular Monolith (Kiến trúc nguyên khối dạng module)**

* Một biến thể của kiến trúc nguyên khối, nơi ứng dụng vẫn là một khối duy nhất, nhưng được chia thành các module độc lập về logic, mỗi module đảm nhận một nhiệm vụ riêng.

* Giao tiếp nội bộ giữa các module không qua mạng, mà thông qua lời gọi hàm nội bộ hoặc các cơ chế message passing trong bộ nhớ.

**4. Service-Oriented Architecture (SOA) (Kiến trúc hướng dịch vụ)**

* SOA chia hệ thống thành nhiều dịch vụ độc lập có thể giao tiếp với nhau qua các giao thức như SOAP, XML, hoặc gRPC.

* Mỗi dịch vụ có thể chứa nhiều chức năng nghiệp vụ khác nhau, trái ngược với kiến trúc Microservices, nơi mỗi dịch vụ chỉ phụ trách một nghiệp vụ.

**5. Event-Driven Architecture (Kiến trúc hướng sự kiện)**

* Hoạt động dựa trên các sự kiện. Khi một sự kiện xảy ra (ví dụ: một đơn hàng được tạo), các thành phần của hệ thống sẽ được kích hoạt để thực hiện các hành động liên quan (ví dụ: cập nhật kho, xử lý thanh toán).

* Hệ thống có thể có hai thành phần chính:

  * Event Producer: Các thành phần tạo ra sự kiện.
  * Event Consumer: Các thành phần lắng nghe và phản ứng với sự kiện.

## So sánh các kiến trúc ứng dụng

| Tiêu chí                             | Monolithic Architecture (Kiến trúc nguyên khối)                                | Microservices Architecture (Kiến trúc vi dịch vụ)                            | Modular Monolith (Kiến trúc nguyên khối dạng module)                          |
|--------------------------------------|---------------------------------------------------------------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| **Cấu trúc tổng thể**                | Toàn bộ ứng dụng nằm trong một khối duy nhất                                    | Ứng dụng được chia thành các dịch vụ nhỏ, hoạt động độc lập                 | Ứng dụng vẫn là một khối duy nhất, nhưng được tổ chức thành các module độc lập |
| **Tính độc lập giữa các phần**       | Các thành phần phụ thuộc chặt chẽ vào nhau                                      | Các dịch vụ hoàn toàn độc lập, giao tiếp qua API                            | Các module độc lập về logic, nhưng vẫn phụ thuộc vào một hệ thống chung        |
| **Triển khai**                       | Cả ứng dụng phải được triển khai cùng lúc                                       | Mỗi dịch vụ có thể được triển khai riêng biệt                               | Ứng dụng được triển khai toàn bộ, nhưng với các module có thể quản lý dễ hơn  |
| **Tính mở rộng**                     | Hạn chế, khó mở rộng vì phải thay đổi toàn hệ thống                             | Dễ dàng mở rộng từng dịch vụ riêng biệt                                     | Mở rộng được, nhưng không tách biệt hoàn toàn như Microservices               |
| **Bảo trì và nâng cấp**              | Khó khăn khi ứng dụng lớn, thay đổi một phần có thể ảnh hưởng toàn bộ hệ thống  | Dễ dàng bảo trì từng dịch vụ mà không ảnh hưởng các phần khác               | Bảo trì dễ hơn Monolithic, nhưng không linh hoạt như Microservices            |
| **Quản lý đội ngũ phát triển**       | Đội ngũ nhỏ dễ quản lý, nhưng khó cho các đội ngũ lớn                            | Dễ dàng phân chia công việc cho các đội ngũ khác nhau                       | Đội ngũ nhỏ có thể quản lý, nhưng dễ tổ chức hơn nhờ module hóa                |
| **Hiệu năng**                        | Hiệu năng tốt khi ứng dụng nhỏ, nhưng giảm khi ứng dụng lớn                      | Hiệu năng tốt cho hệ thống lớn, mỗi dịch vụ có thể được tối ưu riêng        | Hiệu năng tốt hơn Monolithic nhờ tách module, nhưng không bằng Microservices  |
| **Phức tạp triển khai**              | Đơn giản, chỉ triển khai một ứng dụng                                           | Phức tạp, cần quản lý nhiều dịch vụ riêng biệt                               | Đơn giản hơn Microservices, nhưng phức tạp hơn Monolithic                     |
| **Khả năng tích hợp**                | Dễ dàng tích hợp, nhưng khó với hệ thống lớn hoặc tích hợp bên ngoài            | Dễ dàng tích hợp với các dịch vụ và hệ thống bên ngoài                      | Tích hợp dễ hơn Monolithic nhờ module hóa, nhưng không mạnh bằng Microservices |
| **Phù hợp cho ứng dụng quản lý chung cư** | Phù hợp cho hệ thống nhỏ đến trung bình, dễ quản lý và phát triển ban đầu      | Phù hợp cho hệ thống lớn, nhiều dịch vụ riêng biệt (nhiều module độc lập)   | Phù hợp với quy mô vừa, dễ tổ chức và phát triển, có thể nâng cấp lên Microservices |

## Ứng dụng Quản lý Chung cư

Chúng tôi quyết định chọn **Modular Monolith** vì kiến trúc này mang lại sự cân bằng giữa tính đơn giản trong phát triển và triển khai, đồng thời vẫn giữ được tính linh hoạt nhờ tổ chức các thành phần thành những module độc lập. Điều này rất phù hợp với quy mô của đội ngũ chúng tôi và mức độ phức tạp của ứng dụng quản lý chung cư.

### Tổ chức các module

Để tổ chức các module trong ứng dụng, trước hết chúng tôi xác định các chức năng chính của ứng dụng, bao gồm:

* **Quản lý cư dân:** Bao gồm việc lưu trữ, cập nhật thông tin cư dân, danh sách các căn hộ, và người sống trong từng căn hộ.
* **Quản lý thanh toán:** Quản lý các khoản phí (như phí quản lý, phí nước, phí dịch vụ), theo dõi trạng thái thanh toán của cư dân.
* **Quản lý thông báo:** Gửi thông báo đến cư dân về các sự kiện, phí, bảo trì, hoặc cập nhật quan trọng từ ban quản lý.
* **Quản lý bảo trì:** Xử lý yêu cầu bảo trì từ cư dân, lên lịch sửa chữa, theo dõi trạng thái công việc bảo trì.
* **Quản lý phân quyền người dùng:** Xác định các quyền hạn của từng loại người dùng, như ban quản lý, cư dân, hoặc bên thứ ba (dịch vụ bảo vệ, vệ sinh, sửa chữa).

### Chia các chức năng thành các module độc lập

**a. Module quản lý cư dân**

Chức năng: Xử lý việc thêm, sửa, xóa, và xem thông tin của cư dân và căn hộ.

Thành phần:

* Models: Các class hoặc đối tượng đại diện cho thông tin cư dân, căn hộ.
* Services: Các chức năng xử lý logic như thêm cư dân, sửa thông tin cư dân.
* Repositories: Lớp chịu trách nhiệm giao tiếp với cơ sở dữ liệu để lưu trữ và truy xuất thông tin cư dân.
* User Interface (UI): Các màn hình quản lý cư dân dành cho ban quản lý.

**b. Module quản lý thanh toán**

Chức năng: Quản lý hóa đơn, thanh toán của cư dân, xử lý các khoản phí.

Thành phần:

* Models: Đại diện cho các hóa đơn, giao dịch thanh toán.
* Services: Các dịch vụ tính toán phí, tạo hóa đơn, xử lý thanh toán.
* Repositories: Xử lý việc lưu trữ và truy xuất dữ liệu hóa đơn, giao dịch từ cơ sở dữ liệu.
* UI: Giao diện cho ban quản lý xem và quản lý các khoản phí, giao diện cư dân để xem và thanh toán hóa đơn.

**c. Module quản lý thông báo**

Chức năng: Gửi thông báo đến cư dân về các sự kiện, cập nhật, hoặc phí đến hạn.

Thành phần:

* Models: Đại diện cho các thông báo (nội dung, thời gian, đối tượng nhận thông báo).
* Services: Xử lý việc tạo, gửi thông báo qua các phương tiện như email, SMS, hoặc thông báo ứng dụng.
* UI: Giao diện cho ban quản lý gửi thông báo, xem lại lịch sử thông báo đã gửi.

**d. Module quản lý bảo trì**

Chức năng: Quản lý yêu cầu bảo trì của cư dân, lịch sửa chữa và theo dõi trạng thái bảo trì.

Thành phần:

* Models: Đại diện cho các yêu cầu bảo trì, công việc bảo trì, trạng thái.
* Services: Xử lý logic tạo yêu cầu, lên lịch bảo trì, cập nhật trạng thái sửa chữa.
* Repositories: Lưu trữ và truy xuất thông tin bảo trì từ cơ sở dữ liệu.
* UI: Giao diện cư dân gửi yêu cầu bảo trì, giao diện ban quản lý xem và xử lý yêu cầu.

**e. Module phân quyền người dùng**

Chức năng: Quản lý các loại người dùng khác nhau trong hệ thống (ban quản lý, cư dân, bên thứ ba).

Thành phần:

* Models: Đại diện cho vai trò (role) của từng loại người dùng và quyền hạn tương ứng.
* Services: Xử lý logic xác thực, phân quyền và quản lý phiên người dùng (session management).
* UI: Giao diện cho việc quản lý phân quyền và thông tin tài khoản của từng người dùng.

---

Thay vì giao tiếp qua mạng hoặc API như Microservices, các module này có thể giao tiếp với nhau thông qua service calls hoặc function calls bên trong cùng một ứng dụng.

Ví dụ:

* Module quản lý thanh toán có thể gọi đến module quản lý cư dân để lấy thông tin về cư dân khi tạo hóa đơn.
* Module thông báo có thể sử dụng thông tin từ module bảo trì để gửi thông báo về lịch sửa chữa cho cư dân.

### Cấu trúc thư mục

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
│   ├── notifications/ (optional)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/ (optional) 
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```
