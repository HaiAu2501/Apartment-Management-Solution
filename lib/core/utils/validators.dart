// Đây là file chứa các hàm kiểm tra dữ liệu nhập vào từ người dùng
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    // Thêm regex kiểm tra email nếu cần
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên';
    }
    return null;
  }

  static String? validateNumber(String? value) {
    if (value == null || int.tryParse(value) == null) {
      return 'Vui lòng nhập số hợp lệ';
    }
    return null;
  }
}
