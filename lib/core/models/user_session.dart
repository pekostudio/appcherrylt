import 'package:flutter/foundation.dart';

class UserSession with ChangeNotifier {

  String _globalToken = '';
  String _userId = '';
  String _userEmail = '';

  String get globalToken => _globalToken;
  String get userId => _userId;
  String get userEmail => _userEmail;

  void setGlobalToken(String token) {
    _globalToken = token;
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setuserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }

  // Optionally, add a method to update all at once
  void updateUserSession(String token, String id, String email) {
    _globalToken = token;
    _userId = id;
    _userEmail = email;
    notifyListeners();
  }
}
