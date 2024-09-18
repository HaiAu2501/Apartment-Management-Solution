**“Super-user” Vũ Thị Hương Giang (VTHG):**

\* Các yêu cầu rất cần thiết bao gồm: 

- Gửi thông báo tự động cho cư dân về các khoản phí đến hạn, qua ứng dụng, SMS hoặc email.

- Theo dõi trạng thái thanh toán của từng hộ gia đình.

- Quản lý chi tiết các khoản phí (dịch vụ, quản lý, gửi xe).

- Hỗ trợ thanh toán trực tuyến cho cư dân qua ứng dụng.

- Tự động tạo báo cáo chi tiết về các khoản thu và chi của chung cư.

- Phân quyền người dùng trong ứng dụng (quản lý, cư dân, bảo vệ...).

-> Dựa trên những yêu cầu trên, nhóm quyết định tổ chức menu phân quyền cho các tài khoản bao gồm admin, cư dân, bên thứ 3. Sau khi đăng nhập thành công, tài khoản sẽ được điều hướng đến trang bị giới hạn các quyền hạn, đối với những tài khoản có nhiều hơn 1 mục đích sử dụng (chẳng hạn vừa là cư dân, vừa là admin) thì sẽ có lựa chọn thay đổi giữa 2 màn hình.

Ngoài ra, nhóm sẽ đặc biệt chú ý đến các yêu cầu liên quan đến thanh toán cũng như báo cáo chi tiết về các khoản thu và chi của chung cư.

Ở giao diện màn hình admin có tính năng đặt lịch thông báo tự động, điều này giúp việc thông báo các khoản thu chi dễ dàng hơn khi đến hạn, ngoài ra còn có thể thông báo đến khu dân cư các sự kiện, cũng như các phí tình nguyện phát sinh một cách dễ dàng hơn. Hơn nữa nhóm có ý tưởng cư dân cũng khi nhận hoặc đọc được thông báo có thể hiển thị lại ở bên phía màn hình admin, giúp ban quản lí nắm bắt được tình hình kịp thời.

Về việc lập báo cáo tự động, theo định kì các dữ liệu về khoản thu, cũng như ý kiến của cư dân được ghi lại và lưu lại, sau đó thống kê cụ thể qua một bản ghi. Ngoài ra còn có thống kê sơ bộ tình hình của khu dân cư ở một trang dashboard, giúp ban quản lí luôn luôn có cái nhìn tổng quan về khu dân cư.

\* Về một số vấn đề mà user gặp phải:

- Dữ liệu của cư dân không được cập nhật kịp thời, thiếu thông tin quan trọng và khó khăn trong việc lưu trữ và tìm kiếm dữ liệu.

- Vấn đề cư dân nợ phí và đóng phí với các tần suất khác nhau.

-> Giải pháp nhóm đưa ra là cần phải trình bày giao diện dễ sử dụng và thân thiện với người dùng (đây cũng là một trong những yêu cầu của user VTHG), khi cư dân cần thay đổi dữ liệu có thể liên lạc với admin và admin sẽ tìm kiếm thông tin của cư dân một cách nhanh chóng và thay đổi một cách dễ dàng. 

Về vấn đề cư dân nợ phí và đóng phí với các tần suất khác nhau, thông tin các loại phí sẽ được hiển thị rõ ràng trên màn hình của người dùng, cũng như bên phía admin sẽ có thể cập nhật số tiền còn thiếu của từng hộ dân về từng loại khoản phí một cách dễ dàng. Chẳng hạn, tổ chức thông tin dưới dạng bảng, một cột là thông tin để phân biệt các người dùng (có thể là id), các cột tiếp theo là các khoản thu, ở mỗi ô sẽ điền tình trạng của khoản thu đó, bao gồm cần đóng, đã đóng và chưa đóng, các trường thông tin này sẽ có thể chỉnh sửa khi người dùng.

Cụ thể hơn về phần giao diện, để tránh việc render quá nhiều thông tin cùng lúc trên màn hình, gây ảnh hưởng đến hiệu suất cũng như trải nghiệm của người dùng thì nhóm dự kiến sẽ trình bày theo cách phân trang, hiển thị từ 5 đến 10 user cùng lúc.


