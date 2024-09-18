# Q&A: Giải đáp các câu hỏi chất vấn

Dựa trên phiếu khảo sát người dùng, nhóm đã tổng hợp các câu hỏi chất vấn và đưa ra câu trả lời phù hợp.

## Câu hỏi 1

**Làm thế nào để ứng dụng quản lý chung cư trên Flutter tự động gửi thông báo về các khoản phí đến hạn cho cư dân thông qua các kênh như ứng dụng, SMS và email?**

Ứng dụng quản lý chung cư được phát triển bằng Flutter có khả năng gửi thông báo tự động tới người dùng qua ba kênh: trong ứng dụng, qua SMS và email. 

Để thực hiện điều này, chúng tôi tích hợp các dịch vụ gửi thông báo và tin nhắn từ bên thứ ba vào ứng dụng. Các dịch vụ này cho phép tự động hóa việc thông báo, giảm thiểu sự cần thiết phải can thiệp thủ công và đảm bảo rằng thông tin về các khoản phí đến hạn được cập nhật kịp thời cho người dùng. Backend của ứng dụng được thiết kế để xử lý yêu cầu và phân phối thông báo đến người dùng phù hợp thông qua kênh thích hợp, đồng thời đảm bảo an toàn và bảo mật thông tin.

## Câu hỏi 2

**Ứng dụng quản lý chung cư của bạn hỗ trợ phân quyền cho người dùng như thế nào, đặc biệt là trong trường hợp một người vừa là thành viên ban quản lý vừa là cư dân?**

Ứng dụng quản lý chung cư của chúng tôi được thiết kế để hỗ trợ phân quyền mạnh mẽ và linh hoạt cho người dùng. Các vai trò như quản lý, cư dân, và bên thứ ba đều có quyền hạn và chức năng riêng biệt trên ứng dụng để đảm bảo mỗi nhóm người dùng chỉ truy cập được vào các chức năng phù hợp với nhu cầu và trách nhiệm của họ.

Trong trường hợp một người vừa là thành viên của ban quản lý vừa là cư dân, hệ thống của chúng tôi cho phép cấu hình nhiều vai trò cho một tài khoản người dùng. Người dùng này sẽ có quyền truy cập vào cả hai giao diện: giao diện quản lý với các chức năng quản lý và giao diện cư dân với các chức năng thông thường như theo dõi phí, đặt dịch vụ, v.v. Hệ thống tự động phân biệt và cung cấp quyền truy cập dựa trên vai trò đang hoạt động, và người dùng có thể chuyển đổi giữa các vai trò một cách dễ dàng nếu cần thiết.

## Câu hỏi 3

**Trong bối cảnh sử dụng Firebase Firestore làm hệ quản trị cơ sở dữ liệu, ứng dụng quản lý chung cư của bạn đã giải quyết thế nào các vấn đề về cập nhật và truy xuất dữ liệu cư dân không kịp thời?**

Sử dụng Firebase Firestore trong ứng dụng quản lý chung cư của chúng tôi đã giúp cải thiện đáng kể việc quản lý, cập nhật và truy xuất dữ liệu cư dân. Dưới đây là các bước chúng tôi đã thực hiện:

* Firestore cung cấp khả năng cập nhật dữ liệu theo thời gian thực, điều này giúp đảm bảo rằng mọi thay đổi về thông tin cư dân đều được cập nhật ngay lập tức trên tất cả các thiết bị và giải quyết vấn đề trễ nải trong cập nhật dữ liệu.

* Firestore cho phép lưu trữ dữ liệu dạng NoSQL, điều này tạo điều kiện thuận lợi cho việc lưu trữ và truy xuất các cấu trúc dữ liệu phức tạp. Chúng tôi đã thiết kế cơ sở dữ liệu để tối ưu hóa việc truy xuất, sử dụng các trường được chỉ mục để cải thiện hiệu suất tìm kiếm và lọc dữ liệu.

* Firestore hỗ trợ cấu hình mạnh mẽ về quyền truy cập dữ liệu, cho phép chúng tôi thiết lập các quy tắc phân quyền chi tiết cho ban quản lý, cư dân và các bên thứ ba. Điều này giúp đảm bảo rằng mỗi nhóm người dùng chỉ có thể truy cập vào dữ liệu phù hợp với vai trò và nhu cầu của họ.

* Firestore dễ dàng tích hợp với các dịch vụ khác của Firebase như Firebase Authentication và Firebase Cloud Messaging, điều này hỗ trợ việc xác thực người dùng và gửi thông báo đến người dùng một cách hiệu quả.

## Câu hỏi 4

**Ứng dụng quản lý chung cư của bạn xử lý vấn đề cư dân nợ phí và đóng phí với tần suất khác nhau như thế nào?**

Để giải quyết vấn đề cư dân nợ phí và có các tần suất đóng phí khác nhau, ứng dụng của chúng tôi sử dụng hệ thống quản lý tài chính linh hoạt, tích hợp với cơ sở dữ liệu Firebase Firestore. Cụ thể, chúng tôi thực hiện các bước sau:

* Mỗi cư dân có một hồ sơ thanh toán riêng, bao gồm chi tiết các khoản phí đã đóng, các khoản nợ và tần suất thanh toán. Hệ thống này cập nhật theo thời gian thực, giúp ban quản lý dễ dàng theo dõi trạng thái tài chính của từng cư dân.

* Ứng dụng tự động gửi thông báo nhắc nhở qua ứng dụng, SMS, hoặc email đến cư dân về các khoản phí đến hạn hoặc quá hạn. Điều này giúp giảm tình trạng nợ phí do quên thanh toán.

* Ứng dụng cho phép tùy chỉnh tần suất đóng phí (theo tháng, quý, hoặc năm) dựa trên nhu cầu của từng cư dân, giúp tạo ra một hệ thống thanh toán linh hoạt và phù hợp với khả năng tài chính của mỗi người.

* Firestore cung cấp khả năng tạo báo cáo và thống kê tài chính định kỳ cho ban quản lý, giúp họ có cái nhìn tổng thể về tình trạng nợ phí của cư dân, từ đó đưa ra các biện pháp phù hợp.

Nhờ những tính năng này, ứng dụng của chúng tôi giúp quản lý các khoản phí một cách rõ ràng và minh bạch, đồng thời hỗ trợ cư dân trong việc theo dõi và quản lý tài chính cá nhân.
