import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _checking = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkForUsers();
  }

  Future<void> _checkForUsers() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .limit(1)
        .get();
    if (!mounted) return;
    if (snap.docs.isEmpty) {
      Navigator.pushReplacementNamed(context, '/setup');
      return;
    }
    setState(() => _checking = false);
  }

  Future<void> _selectUser(String userId) async {
    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    final user = await authService.login(userId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (user == null) return;

    ref.read(authStateProvider.notifier).state = user;
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_special,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نظام تتبع ملفات القضايا',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),
                const Text('اختر مستخدم للدخول'),
                const SizedBox(height: 16),
                _UsersList(onUserTap: _selectUser),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final ValueChanged<String> onUserTap;
  const _UsersList({required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('خطأ: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const Text('لا يوجد مستخدمين نشطين');
        }
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final role = data['role'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      role == 'admin'
                          ? Icons.admin_panel_settings
                          : role == 'judge'
                              ? Icons.gavel
                              : Icons.person,
                    ),
                  ),
                  title: Text(data['name'] as String? ?? ''),
                  subtitle: Text(Helpers.roleLabel(role)),
                  trailing: const Icon(Icons.login),
                  onTap: () => onUserTap(doc.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
