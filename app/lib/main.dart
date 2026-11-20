import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_config.dart';
import 'core/theme.dart';
import 'pages/hall_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const BountyApp());
}

class BountyApp extends StatelessWidget {
  const BountyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '悬赏',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Entry(),
    );
  }
}

class _Entry extends StatefulWidget {
  const _Entry();

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  bool? _logged;

  @override
  void initState() {
    super.initState();
    AppConfig.hasToken().then((v) {
      if (mounted) setState(() => _logged = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_logged == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      );
    }
    return _logged! ? const HallPage() : const LoginPage();
  }
}
