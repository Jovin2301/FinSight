import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);

  String? _token;
  Map<String, dynamic>? _user;

  // any screen can read these
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  // called after successful login
  // Future<void> setSession(String token, Map<String, dynamic> user) async {
  //   _token = token;
  //   _user = user;
  //   await _storage.write(key: 'token', value: token);
  //   notifyListeners(); // tells all screens "hey, something changed"
  // }c

  /*Future<void> setSession(String token, String userId) async {
    try {
      const storage = FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      await storage.write(key: 'token', value: token);
    } catch (e) {
      if (kDebugMode) {
        // Simulator fallback - never use in production
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        print('Used SharedPreferences fallback (simulator only)');
      } else {
        rethrow; // Let production errors surface
      }
    }
  }*/

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    
    try {
      await _storage.write(key: 'token', value: token);
    } catch (e) {
      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        print('Used SharedPreferences fallback (simulator only)');
      } else {
        rethrow;
      }
    }

    notifyListeners(); // ← this is what tells the rest of the app "user is now logged in"
  }

  void updateUser(Map<String, dynamic> updatedUser) {
    print("UPDATED USER:");
    print(updatedUser);

    _user = {
      ..._user ?? {},
      ...updatedUser,
    };
    notifyListeners();
  }

  // called on logout
  Future<void> logout() async {
    _token = null;
    _user = null;

    try {
      await _storage.delete(key: 'token');
    } catch (e) {
      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        print('Used SharedPreferences fallback for logout (simulator only)');
      } else {
        rethrow;
      }
    }

    notifyListeners();
  }

  // called on app launch — restores session if user was already logged in
  Future<void> tryAutoLogin() async {
    try {
      final savedToken = await _storage.read(key: 'token');
      if (savedToken == null) return;
      _token = savedToken;
    } catch (e) {
      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        final savedToken = prefs.getString('token');
        if (savedToken == null) return;
        _token = savedToken;
        print('Used SharedPreferences fallback for autoLogin (simulator only)');
      } else {
        rethrow;
      }
    }

    notifyListeners();
  }
}