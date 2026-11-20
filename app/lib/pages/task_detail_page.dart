import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? _task;
  String? _error;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Api.get('/task/${widget.taskId}');
      setState(() => _task = Map<String, dynamic>.from(data));
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final data = await Api.post('/task/${widget.taskId}/apply');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgElevated,
          title: const Text('报名成功', style: TextStyle(color: AppColors.gold300)),
          content: Text('单号：${data['orderNo']}',
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            )
          ],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
          : _task == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
              : _content(_task!),
      bottomNavigationBar: _task == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              color: AppColors.bgBase,
              child: GoldButton(
                text: '立即报名 ¥${_task!['unitPrice']}',
                loading: _applying,
                onTap: _apply,
              ),
            ),
    );
  }

  Widget _content(Map<String, dynamic> t) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${t['title']}',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('¥${t['unitPrice']}',
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.gold500)),
            const Spacer(),
            Text('剩余 ${t['remainQuota']} / ${t['totalQuota']}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('任务要求',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Text('${t['rules'] ?? '无特殊要求'}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.6, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('完成时限',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Text('报名后 ${t['deadlineMinutes']} 分钟内完成并提交凭证',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
