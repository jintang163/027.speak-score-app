import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/screens/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _orgFormKey = GlobalKey<OrganizationFormSectionState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _nicknameController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final orgData = _orgFormKey.currentState?.validate();
    if (orgData == null) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.register(
      phone: _phoneController.text.trim(),
      code: _smsCodeController.text.trim(),
      nickname: _nicknameController.text.trim(),
      roleCode: orgData.roleCode,
      schoolId: orgData.schoolId,
      classCode: orgData.classCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showError('注册失败，请检查信息后重试');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注册账号'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: '请输入昵称',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入昵称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                OrganizationFormSection(key: _orgFormKey),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
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
                            '注册',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
