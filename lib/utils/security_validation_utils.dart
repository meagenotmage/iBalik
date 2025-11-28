import 'dart:core';

class SecurityValidationUtils {
  /// Validates WVSU email addresses
  static Map<String, dynamic> validateWvsuEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    
    if (trimmedEmail.isEmpty) {
      return {
        'isValid': false,
        'message': 'Email address is required'
      };
    }
    
    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return {
        'isValid': false,
        'message': 'Please enter a valid email address'
      };
    }
    
    // Check for WVSU domain
    final wvsuDomains = [
      '@wvsu.edu.ph',
      '@student.wvsu.edu.ph',
      '@faculty.wvsu.edu.ph',
      '@staff.wvsu.edu.ph'
    ];
    
    final hasValidDomain = wvsuDomains.any((domain) => trimmedEmail.endsWith(domain));
    
    if (!hasValidDomain) {
      return {
        'isValid': false,
        'message': 'Please use a valid WVSU email address (@wvsu.edu.ph, @student.wvsu.edu.ph, etc.)'
      };
    }
    
    return {
      'isValid': true,
      'message': 'Valid WVSU email address'
    };
  }
  
  /// Validates username format and requirements
  static Map<String, dynamic> validateUsername(String username) {
    final trimmedUsername = username.trim();
    
    if (trimmedUsername.isEmpty) {
      return {
        'isValid': false,
        'message': 'Username is required'
      };
    }
    
    if (trimmedUsername.length < 3) {
      return {
        'isValid': false,
        'message': 'Username must be at least 3 characters long'
      };
    }
    
    if (trimmedUsername.length > 20) {
      return {
        'isValid': false,
        'message': 'Username must be less than 20 characters long'
      };
    }
    
    // Allow alphanumeric characters, underscores, and hyphens
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(trimmedUsername)) {
      return {
        'isValid': false,
        'message': 'Username can only contain letters, numbers, underscores, and hyphens'
      };
    }
    
    // Must start with a letter or number
    final startsWithAlphanumeric = RegExp(r'^[a-zA-Z0-9]');
    if (!startsWithAlphanumeric.hasMatch(trimmedUsername)) {
      return {
        'isValid': false,
        'message': 'Username must start with a letter or number'
      };
    }
    
    return {
      'isValid': true,
      'message': 'Valid username'
    };
  }
  
  /// Validates password strength and requirements
  static Map<String, dynamic> validatePassword(String password) {
    if (password.isEmpty) {
      return {
        'isValid': false,
        'message': 'Password is required'
      };
    }
    
    if (password.length < 8) {
      return {
        'isValid': false,
        'message': 'Password must be at least 8 characters long'
      };
    }
    
    if (password.length > 128) {
      return {
        'isValid': false,
        'message': 'Password must be less than 128 characters long'
      };
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return {
        'isValid': false,
        'message': 'Password must contain at least one uppercase letter'
      };
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return {
        'isValid': false,
        'message': 'Password must contain at least one lowercase letter'
      };
    }
    
    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return {
        'isValid': false,
        'message': 'Password must contain at least one number'
      };
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return {
        'isValid': false,
        'message': 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)'
      };
    }
    
    // Check for common weak passwords
    final commonPasswords = [
      'password', 'password123', '12345678', 'qwerty123',
      'letmein', 'welcome123', 'admin123', 'iloveyou'
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      return {
        'isValid': false,
        'message': 'This password is too common. Please choose a stronger password'
      };
    }
    
    return {
      'isValid': true,
      'message': 'Strong password'
    };
  }
  
  /// Validates Philippine phone number format
  static Map<String, dynamic> validatePhoneNumber(String phoneNumber) {
    final trimmedPhone = phoneNumber.trim().replaceAll(' ', '').replaceAll('-', '');
    
    if (trimmedPhone.isEmpty) {
      return {
        'isValid': false,
        'message': 'Phone number is required'
      };
    }
    
    // Philippine mobile number patterns
    final mobilePatterns = [
      RegExp(r'^(09)\d{9}$'), // 09XXXXXXXXX format
      RegExp(r'^(\+639)\d{9}$'), // +639XXXXXXXXX format
      RegExp(r'^(639)\d{9}$'), // 639XXXXXXXXX format
    ];
    
    final isValidMobile = mobilePatterns.any((pattern) => pattern.hasMatch(trimmedPhone));
    
    if (!isValidMobile) {
      return {
        'isValid': false,
        'message': 'Please enter a valid Philippine mobile number (e.g., 09XXXXXXXXX or +639XXXXXXXXX)'
      };
    }
    
    return {
      'isValid': true,
      'message': 'Valid Philippine mobile number'
    };
  }
  
  /// Validates full name format
  static Map<String, dynamic> validateFullName(String fullName) {
    final trimmedName = fullName.trim();
    
    if (trimmedName.isEmpty) {
      return {
        'isValid': false,
        'message': 'Full name is required'
      };
    }
    
    if (trimmedName.length < 2) {
      return {
        'isValid': false,
        'message': 'Full name must be at least 2 characters long'
      };
    }
    
    if (trimmedName.length > 100) {
      return {
        'isValid': false,
        'message': 'Full name must be less than 100 characters long'
      };
    }
    
    // Allow letters, spaces, hyphens, apostrophes, and periods
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!nameRegex.hasMatch(trimmedName)) {
      return {
        'isValid': false,
        'message': 'Full name can only contain letters, spaces, hyphens, apostrophes, and periods'
      };
    }
    
    // Must contain at least one space (first and last name)
    if (!trimmedName.contains(' ')) {
      return {
        'isValid': false,
        'message': 'Please enter your full name (first and last name)'
      };
    }
    
    return {
      'isValid': true,
      'message': 'Valid full name'
    };
  }
  
  /// Sanitizes input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>&"' + "'" + r'`]'), '') // Remove potentially harmful characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }
  
  /// Validates that a string doesn't contain potentially harmful content
  static bool containsMaliciousContent(String input) {
    final maliciousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];
    
    return maliciousPatterns.any((pattern) => pattern.hasMatch(input));
  }
}