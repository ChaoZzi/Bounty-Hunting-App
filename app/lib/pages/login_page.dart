import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import 'hall_page.dart';
import 'server_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController(text: '');
  final _code = TextEditingController(text: '');
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      setState(() => _err = '请输入正确的手机号');
      return;
    }
    try {
      await Api.post('/auth/sms/send', data: {'phone': phone, 'scene': 'LOGIN'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本地环境验证码固定为 123456')),
      );
    } catch (e) {
      setState(() => _err = e.toString());
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final data = await Api.post('/auth/login', data: {
        'phone': _phone.text.trim(),
        'code': _code.text.trim(),
      });
      await AppConfig.saveLogin(
        data['token'].toString(),
        (data['nickname'] ?? '').toString(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HallPage()),
      );
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              const Text(
                '悬赏',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold300,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text('做任务 · 拿赏金', style: TextStyle(color: AppColors.textTertiary)),
              const SizedBox(height: 56),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '手机号'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '验证码（本地固定 123456）'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _sendCode,
                    child: const Text('获取验证码', style: TextStyle(color: AppColors.gold500)),
                  ),
                ],
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 32),
              GoldButton(text: '登 录', loading: _loading, onTap: _login),
              const Spacer(),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ServerPage()),
                    );
                    setState(() {});
                  },
                  icon: const Icon(Icons.wifi_tethering, size: 16, color: AppColors.textTertiary),
                  label: Text(
                    '服务器 ${AppConfig.baseUrl}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
