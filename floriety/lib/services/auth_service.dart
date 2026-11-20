import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ValueNotifier<bool> authState = ValueNotifier(false);

  String? _token;
  String? _email;
  String? _name;
  int? _userId;
  int _avatarIndex = 1;
  bool _isDark = true;
  String _nickname = '';
  String _description = '';

  String? get token => _token;
  String? get email => _email;
  String? get name => _name;
  int? get userId => _userId;
  int get avatarIndex => _avatarIndex;
  bool get isDark => _isDark;
  String get nickname => _nickname;
  String get description => _description;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _email = prefs.getString('auth_email');
    _name = prefs.getString('auth_name');
    _userId = prefs.getInt('auth_user_id');
    _avatarIndex = prefs.getInt('auth_avatar_index') ?? 1;
    _isDark = prefs.getBool('auth_is_dark') ?? true;
    _nickname = prefs.getString('auth_nickname') ?? '';
    _description = prefs.getString('auth_description') ?? '';
    authState.value = isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    final result = await ApiService.login(email, password);
    _token = result['token'] as String?;
    _email = result['email'] as String?;
    _name = result['name'] as String?;
    _userId = result['user_id'] as int?;
    _nickname = result['nickname'] as String? ?? '';
    _description = result['description'] as String? ?? '';
    _avatarIndex = result['avatar_index'] as int? ?? 1;
    _isDark = result['is_dark'] as bool? ?? true;
    await _savePrefs();
    authState.value = true;
  }

  Future<void> register(String email, String password) async {
    final result = await ApiService.register(email, password);
    _token = result['token'] as String?;
    _email = result['email'] as String?;
    _name = result['name'] as String?;
    _userId = result['user_id'] as int?;
    _nickname = result['nickname'] as String? ?? '';
    _description = result['description'] as String? ?? '';
    _avatarIndex = result['avatar_index'] as int? ?? 1;
    _isDark = result['is_dark'] as bool? ?? true;
    await _savePrefs();
    authState.value = true;
  }

  Future<void> updateProfile({
    String? name,
    String? nickname,
    String? description,
    int? avatarIndex,
    bool? isDark,
  }) async {
    if (!isLoggedIn || token == null) return;
    await ApiService.updateProfile(
      token!,
      name: name,
      nickname: nickname,
      description: description,
      avatarIndex: avatarIndex,
      isDark: isDark,
    );
    if (name != null) _name = name;
    if (nickname != null) _nickname = nickname;
    if (description != null) _description = description;
    if (avatarIndex != null) _avatarIndex = avatarIndex;
    if (isDark != null) _isDark = isDark;
    await _savePrefs();
  }

  Future<void> logout() async {
    final oldToken = _token;
    if (oldToken != null && oldToken.isNotEmpty) {
      await ApiService.logout(oldToken);
    }
    _token = null;
    _email = null;
    _name = null;
    _userId = null;
    _avatarIndex = 1;
    _isDark = true;
    _nickname = '';
    _description = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    authState.value = false;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token ?? '');
    await prefs.setString('auth_email', _email ?? '');
    await prefs.setString('auth_name', _name ?? '');
    if (_userId != null) await prefs.setInt('auth_user_id', _userId!);
    await prefs.setInt('auth_avatar_index', _avatarIndex);
    await prefs.setBool('auth_is_dark', _isDark);
    await prefs.setString('auth_nickname', _nickname);
    await prefs.setString('auth_description', _description);
  }
}
