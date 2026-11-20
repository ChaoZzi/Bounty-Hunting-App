import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late final TextEditingController _ctrl =
      TextEditingController(text: AppConfig.baseUrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务器地址')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '电脑局域网 IP 变了的话，在这里改就行，不用重新打包。',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'http://192.168.1.23:8080'),
            ),
            const SizedBox(height: 12),
            const Text(
              '查看电脑 IP：在电脑上运行 ipconfig，找「IPv4 地址」\n'
              '手机必须和电脑连同一个 WiFi',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 24),
            GoldButton(
              text: '保存',
              onTap: () async {
                await AppConfig.setBaseUrl(_ctrl.text.trim());
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
