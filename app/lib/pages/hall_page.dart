import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import 'login_page.dart';
import 'mine_page.dart';
import 'server_page.dart';
import 'task_detail_page.dart';

class HallPage extends StatefulWidget {
  const HallPage({super.key});

  @override
  State<HallPage> createState() => _HallPageState();
}

class _HallPageState extends State<HallPage> {
  final List<dynamic> _tasks = [];
  bool _loading = true;
  String? _error;
  String _sort = 'comprehensive';

  static const _sorts = {
    'comprehensive': '综合',
    'latest': '最新',
    'price': '高价',
    'simple': '简单',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Api.get('/task/hall', query: {'sort': _sort, 'pageNum': 1, 'pageSize': 20});
      setState(() {
        _tasks
          ..clear()
          ..addAll((data['list'] as List?) ?? []);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _sortBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          const Text('悬赏大厅',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          IconButton(
            onPressed: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ServerPage()));
              _load();
            },
            icon: const Icon(Icons.wifi_tethering, color: AppColors.textTertiary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sortBar() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _sorts.entries.map((e) {
          final active = _sort == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _sort = e.key);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.gold500.withValues(alpha: 0.16) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? AppColors.gold500 : AppColors.hairline,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? AppColors.gold300 : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold500));
    }
    if (_error != null) {
      return _errorView(_error!);
    }
    if (_tasks.isEmpty) {
      return const Center(
        child: Text('暂时没有任务', style: TextStyle(color: AppColors.textTertiary)),
      );
    }
    return RefreshIndicator(
      color: AppColors.gold500,
      backgroundColor: AppColors.bgElevated,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _taskCard(_tasks[i]),
      ),
    );
  }

  Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: _load, child: const Text('重试')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ServerPage()));
                    _load();
                  },
                  child: const Text('改服务器地址'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(dynamic t) {
    final remain = t['remainQuota'] ?? 0;
    return DarkCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: t['id'] as int)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt, color: AppColors.gold500, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t['title']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${t['takenQuota'] ?? 0}人已赚',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(width: 12),
                    Text(
                      '剩余 $remain',
                      style: TextStyle(
                        fontSize: 12,
                        color: remain <= 20 ? AppColors.warning : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '¥${t['unitPrice']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.gold500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          _tab(Icons.home_outlined, '首页', true, () {}),
          _tab(Icons.card_giftcard_outlined, '悬赏大厅', false, () {}),
          _tab(Icons.person_outline, '我的', false, () async {
            final back = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MinePage()),
            );
            if (back == 'logout' && mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: active ? AppColors.gold500 : AppColors.textTertiary),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: active ? AppColors.gold500 : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
