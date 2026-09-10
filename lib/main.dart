import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline_queue');
  await Hive.openBox('local_data');
  await Hive.openBox('app_state');
  await Hive.openBox('overdue_alerts');

  Widget app;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    app = const ProviderScope(child: CourtCaseApp());
  } catch (e) {
    app = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('خطأ في تشغيل التطبيق: $e'),
        ),
      ),
    );
  }

  runApp(app);
}
