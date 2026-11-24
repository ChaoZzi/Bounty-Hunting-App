import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import 'my_orders_page.dart';
import 'server_page.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _wallet;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await Api.get('/user/profile');
      final w = await Api.get('/wallet/summary');
      setState(() {
        _profile = Map<String, dynamic>.from(p);
        _wallet = Map<String, dynamic>.from(w);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
          : _profile == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold700.withValues(alpha: 0.3),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF1A1206), size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_profile!['nickname']}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('ID ${_profile!['id']} · ${_profile!['phone']}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _stat('余额', '${_wallet!['available'] ?? '0.00'}'),
                        _stat('待结算', '${_wallet!['pending'] ?? '0.00'}'),
                        _stat('累计收入', '${_wallet!['totalIncome'] ?? '0.00'}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DarkCard(
                      child: Column(
                        children: [
                          _row('信誉分', '${_profile!['creditScore']} / ${_profile!['creditMax']}'),
                          const Divider(height: 24),
                          _row('实名状态', _realnameText(_profile!['realnameStatus'])),
                          const Divider(height: 24),
                          _row('我的邀请码', '${_profile!['inviteCode'] ?? '-'}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 我的任务：报名记录的入口
                    DarkCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Text('我的任务',
                              style: TextStyle(color: AppColors.textPrimary)),
                          Spacer(),
                          Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DarkCard(
                      onTap: () async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ServerPage()));
                        setState(() {});
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_tethering, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Text('服务器地址', style: TextStyle(color: AppColors.textPrimary)),
                          Spacer(),
                          Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () async {
                        await AppConfig.logout();
                        if (context.mounted) Navigator.of(context).pop('logout');
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: const Text('退出登录',
                            style: TextStyle(color: AppColors.danger, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _realnameText(dynamic v) => switch (v) {
        0 => '未认证',
        1 => '审核中',
        2 => '已认证',
        _ => '未通过',
      };

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gold500)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Row(
      children: [
        Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(v, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      ],
    );
  }
}
