import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/wechat_service.dart';
import 'package:speak_score_flutter/screens/register_screen.dart';
import 'package:speak_score_flutter/screens/wechat_register_screen.dart';
import 'package:speak_score_flutter/screens/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  StreamSubscription<String>? _wechatAuthSubscription;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _wechatAuthSubscription?.cancel();
    super.dispose();
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return phone.length == 11;
  }

  Future<bool> _sendSmsCode() async {
    if (!_isPhoneValid) {
      _showError('请输入正确的11位手机号');
      return false;
    }
    final authService = context.read<AuthService>();
    final success = await authService.sendSmsCode(_phoneController.text.trim());
    if (!success && mounted) {
      _showError('发送验证码失败，请稍后重试');
    }
    return success;
  }

  Future<void> _loginByPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.loginByPhone(
      _phoneController.text.trim(),
      _smsCodeController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      _showError('登录失败，请检查手机号和验证码');
    }
  }

  Future<void> _loginByWechat() async {
    final wechatService = WechatService();
    final installed = await wechatService.isWeChatInstalled();
    if (!installed) {
      if (mounted) _showError('请先安装微信');
      return;
    }

    final sent = await wechatService.sendWeChatAuth();
    if (!sent) {
      if (mounted) _showError('微信授权失败');
      return;
    }

    _wechatAuthSubscription?.cancel();
    _wechatAuthSubscription = wechatService.authCodeStream.listen((code) async {
      _wechatAuthSubscription?.cancel();

      if (!mounted) return;

      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();
      final success = await authService.loginByWechat(code);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!success) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WechatRegisterScreen(wechatCode: code),
            ),
          );
        }
      }
    });
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.record_voice_over,
                    size: 72,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '英语打卡',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      prefixText: '+86 ',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                      hintText: '请输入手机号',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入手机号';
                      }
                      if (value.trim().length != 11) {
                        return '请输入正确的11位手机号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _smsCodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            prefixIcon: Icon(Icons.sms),
                            border: OutlineInputBorder(),
                            hintText: '请输入验证码',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入验证码';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SmsSendButton(
                        onSend: _sendSmsCode,
                        enabled: _isPhoneValid,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _loginByPhone,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '手机号登录',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '或',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginByWechat,
                      icon: const Icon(Icons.chat_bubble, color: Color(0xFF07C160)),
                      label: const Text(
                        '微信登录',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF07C160),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF07C160)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _navigateToRegister,
                    child: const Text(
                      '新用户注册',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
