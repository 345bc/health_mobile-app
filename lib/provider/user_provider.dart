import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? getUser() {
    return _currentUser;
  }

  void setUser(Map<String, dynamic> user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;
}
