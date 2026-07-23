class AppValidators {
  AppValidators._();

  // ── Email ──────────────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────────────────
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ── Confirm Password ───────────────────────────────────────────────────────
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ── Name ───────────────────────────────────────────────────────────────────
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  // ── Phone ──────────────────────────────────────────────────────────────────
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid Pakistani number (03XXXXXXXXX)';
    }
    return null;
  }

  // ── Address ────────────────────────────────────────────────────────────────
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  // ── Description ────────────────────────────────────────────────────────────
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }
    return null;
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 5) {
      return 'Title must be at least 5 characters';
    }
    return null;
  }

  // ── CNIC ──────────────────────────────────────────────────────────────────
  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC is required';
    }
    final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value.trim())) {
      return 'Invalid format — use: 42101-1234567-1';
    }
    if (_isBlacklistedCnic(value.trim())) {
      return 'Invalid CNIC number';
    }
    if (!_isValidProvinceCode(value.trim())) {
      return 'Invalid province code in CNIC';
    }
    if (!_isValidCnicChecksum(value.trim())) {
      return 'Invalid CNIC — please check and try again';
    }
    return null;
  }

  // ── CNIC Last 6 Digits ────────────────────────────────────────────────────
  static String? validateCnicLast6Digits(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last 6 digits of CNIC are required';
    }
    final cnicLast6Regex = RegExp(r'^\d{6}$');
    if (!cnicLast6Regex.hasMatch(value.trim())) {
      return 'Must be exactly 6 digits';
    }
    const fakePins = ['000000', '111111', '123456', '999999'];
    if (fakePins.contains(value.trim())) {
      return 'Invalid CNIC digits';
    }
    return null;
  }

  // ── Experience ────────────────────────────────────────────────────────────
  static String? validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Experience is required';
    }
    final years = int.tryParse(value.trim());
    if (years == null) {
      return 'Enter a valid number';
    }
    if (years < 0 || years > 50) {
      return 'Experience must be between 0 and 50 years';
    }
    return null;
  }

  // ── Price ─────────────────────────────────────────────────────────────────
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  // ── Generic Required ──────────────────────────────────────────────────────
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  static bool _isValidCnicChecksum(String cnic) {
    try {
      final digits = cnic.replaceAll('-', '');
      if (digits.length != 13) return false;
      final checksumDigit = int.parse(digits[12]);
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(digits[i]);
        if (i % 2 == 1) {
          digit *= 2;
          if (digit > 9) digit -= 9;
        }
        sum += digit;
      }
      return (10 - (sum % 10)) % 10 == checksumDigit;
    } catch (_) {
      return false;
    }
  }

  static bool _isBlacklistedCnic(String cnic) {
    const blacklist = [
      '00000-0000000-0', '11111-1111111-1', '22222-2222222-2',
      '33333-3333333-3', '44444-4444444-4', '55555-5555555-5',
      '66666-6666666-6', '77777-7777777-7', '88888-8888888-8',
      '99999-9999999-9', '12345-1234567-1', '12345-6789012-3',
    ];
    return blacklist.contains(cnic);
  }

  static bool _isValidProvinceCode(String cnic) {
    // 1=ICT, 2=Punjab, 3=Sindh, 4=KPK, 5=Balochistan, 6=AJK, 7=GB
    return ['1', '2', '3', '4', '5', '6', '7'].contains(cnic[0]);
  }
}