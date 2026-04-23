import 'package:flutter/foundation.dart';
import 'package:frontend/data/models/user.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;

  User? getUser() {
    return _currentUser;
  }

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;
}
