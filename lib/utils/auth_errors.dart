/// Utility class to handle Firebase authentication error messages
/// Transforms technical error codes into user-friendly messages
class AuthErrors {
  /// Maps Firebase error codes to user-friendly error messages
  static String getMessageFromCode(String errorCode) {
    switch (errorCode) {
      // Email-related errors
      case 'invalid-email':
        return 'The email address is not valid. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Need to create an account?';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in instead.';

      // Password-related errors
      case 'wrong-password':
        return 'Incorrect password. Please check and try again.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with letters and numbers.';

      // Network-related errors
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      case 'too-many-requests':
        return 'Access temporarily blocked due to too many attempts. Please try again later.';

      // Other common errors
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires a more recent login. Please sign in again.';

      // Default fallback
      default:
        return 'Authentication failed: $errorCode. Please try again.';
    }
  }

  /// Parses Firebase error message string to extract the error code
  static String parseErrorMessage(String errorMessage) {
    // Firebase errors usually have format: [firebase_auth/error-code] message
    RegExp regExp = RegExp(r'\[(firebase_auth\/)?([a-z\-]+)\]');
    final match = regExp.firstMatch(errorMessage);

    if (match != null && match.groupCount >= 2) {
      final errorCode = match.group(2);
      if (errorCode != null) {
        return errorCode;
      }
    }

    // If we can't extract an error code with regex, check for common strings
    if (errorMessage.contains('user-not-found')) {
      return 'user-not-found';
    } else if (errorMessage.contains('wrong-password')) {
      return 'wrong-password';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'email-already-in-use';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'network-request-failed';
    }

    // If no specific error detected, return the full message
    return errorMessage;
  }

  /// Gets a user-friendly error message from a raw Firebase error
  static String getUserFriendlyError(dynamic error) {
    String errorMessage = error.toString();
    String errorCode = parseErrorMessage(errorMessage);
    return getMessageFromCode(errorCode);
  }
}
