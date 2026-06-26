import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/helpers.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? editUserId;
  const UserFormScreen({super.key, this.editUserId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();

  String _role = 'clerk';
  bool _active = true;
  Map<String, bool> _permissions = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editUserId != null) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final u = await ref.read(firestoreServiceProvider).getUser(widget.editUserId!);
    if (u != null && mounted) {
      setState(() {
        _nameCtrl.text = u.name;
        _departmentCtrl.text = u.department;
        _role = u.role;
        _active = u.active;
        _permissions = Map.from(u.permissions);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = ref.read(authStateProvider);

    final u = UserModel(
      id: widget.editUserId ?? Helpers.generateId(),
      name: _nameCtrl.text.trim(),
      role: _role,
      department: _departmentCtrl.text.trim(),
      active: _active,
      permissions: Map.from(_permissions),
      createdBy: user?.id ?? '',
    );

    await ref.read(firestoreServiceProvider).addUser(u);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editUserId != null ? 'تعديل مستخدم' : 'إضافة مستخدم'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentCtrl,
                decoration: const InputDecoration(labelText: 'القسم'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: ['admin', 'judge', 'clerk'].map((r) {
                  return DropdownMenuItem(value: r, child: Text(Helpers.roleLabel(r)));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _role = v ?? 'clerk';
                    _permissions = {
                      'transferFolder': _role == 'admin' || _role == 'judge',
                      'editCase': true,
                      'changeStatus': _role == 'admin' || _role == 'judge',
                      'manageUsers': _role == 'admin',
                      'viewDashboard': true,
                      'printCase': true,
                    };
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('نشط'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const Divider(),
              Text('الصلاحيات', style: Theme.of(context).textTheme.titleMedium),
              ...['transferFolder', 'editCase', 'changeStatus', 'manageUsers', 'viewDashboard', 'printCase'].map((perm) {
                return CheckboxListTile(
                  title: Text(_permissionLabel(perm)),
                  value: _permissions[perm] ?? false,
                  onChanged: (v) {
                    setState(() => _permissions[perm] = v ?? false);
                  },
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(widget.editUserId != null ? 'حفظ التغييرات' : 'إضافة المستخدم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _permissionLabel(String perm) {
    switch (perm) {
      case 'transferFolder':
        return 'نقل الملفات';
      case 'editCase':
        return 'تعديل القضايا';
      case 'changeStatus':
        return 'تغيير الحالة';
      case 'manageUsers':
        return 'إدارة المستخدمين';
      case 'viewDashboard':
        return 'عرض لوحة التحكم';
      case 'printCase':
        return 'طباعة القضية';
      default:
        return perm;
    }
  }
}
