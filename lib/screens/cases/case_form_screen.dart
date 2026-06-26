import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class CaseFormScreen extends ConsumerStatefulWidget {
  final String? editCaseId;
  const CaseFormScreen({super.key, this.editCaseId});

  @override
  ConsumerState<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends ConsumerState<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseSummaryCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _partyOneNameCtrl = TextEditingController();
  final _partyTwoNameCtrl = TextEditingController();
  final _partyOnePersonsCtrl = TextEditingController();
  final _partyTwoPersonsCtrl = TextEditingController();

  String _category = 'other';
  String _assignedJudgeId = '';
  String _assignedJudgeName = '';
  String _assignedClerkId = '';
  String _assignedClerkName = '';

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editCaseId != null) {
      _loadCase();
    }
  }

  Future<void> _loadCase() async {
    final c = await ref.read(firestoreServiceProvider).getCase(widget.editCaseId!);
    if (c != null && mounted) {
      setState(() {
        _caseSummaryCtrl.text = c.caseSummary;
        _numberCtrl.text = c.caseNumber;
        _yearCtrl.text = c.year;
        _category = c.category;
        _partyOneNameCtrl.text = c.partyOneName;
        _partyTwoNameCtrl.text = c.partyTwoName;
        _partyOnePersonsCtrl.text = c.partyOnePersons.join('، ');
        _partyTwoPersonsCtrl.text = c.partyTwoPersons.join('، ');
        _assignedJudgeId = c.assignedJudgeId;
        _assignedJudgeName = c.assignedJudgeName;
        _assignedClerkId = c.assignedClerkId;
        _assignedClerkName = c.assignedClerkName;
      });
    }
  }

  @override
  void dispose() {
    _caseSummaryCtrl.dispose();
    _numberCtrl.dispose();
    _yearCtrl.dispose();
    _partyOneNameCtrl.dispose();
    _partyTwoNameCtrl.dispose();
    _partyOnePersonsCtrl.dispose();
    _partyTwoPersonsCtrl.dispose();
    super.dispose();
  }

  List<String> _parsePersons(String text) {
    if (text.trim().isEmpty) return [];
    return text.split('،').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = ref.read(authStateProvider);
    final service = ref.read(firestoreServiceProvider);
    final now = DateTime.now();

    final c = CaseModel(
      id: widget.editCaseId ?? Helpers.generateId(),
      caseNumber: _numberCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      category: _category,
      caseSummary: _caseSummaryCtrl.text.trim(),
      partyOneName: _partyOneNameCtrl.text.trim(),
      partyOnePersons: _parsePersons(_partyOnePersonsCtrl.text),
      partyTwoName: _partyTwoNameCtrl.text.trim(),
      partyTwoPersons: _parsePersons(_partyTwoPersonsCtrl.text),
      assignedJudgeId: _assignedJudgeId,
      assignedJudgeName: _assignedJudgeName,
      assignedClerkId: _assignedClerkId,
      assignedClerkName: _assignedClerkName,
      createdAt: now,
      createdBy: user?.id ?? '',
    );

    await service.addCase(c);

    if (widget.editCaseId == null && user != null) {
      await service.addHistory(HistoryModel(
        id: Helpers.generateId(),
        caseId: c.id,
        type: 'edit',
        description: 'إضافة قضية جديدة: ${c.caseSummary}',
        performedBy: user.id,
        performedByName: user.name,
        newValue: c.caseSummary,
      ));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final judgesAsync = ref.watch(judgesProvider);
    final clerksAsync = ref.watch(clerksProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editCaseId != null ? 'تعديل قضية' : 'إضافة قضية'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('بيانات القضية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caseSummaryCtrl,
                decoration: const InputDecoration(labelText: 'ملخص القضية'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(labelText: 'رقم القضية'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearCtrl,
                decoration: const InputDecoration(labelText: 'السنة'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: AppConstants.caseCategories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(AppConstants.categoryLabels[c] ?? c));
                }).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'other'),
              ),
              const SizedBox(height: 24),
              Text('الاطراف', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyOneNameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الطرف الأول'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyOnePersonsCtrl,
                decoration: const InputDecoration(
                  labelText: 'أشخاص الطرف الأول',
                  hintText: 'محمد، أحمد، علي',
                  helperText: 'افصل بين الأسماء بعلامة الفاصلة العربية',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partyTwoNameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الطرف الثاني'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyTwoPersonsCtrl,
                decoration: const InputDecoration(
                  labelText: 'أشخاص الطرف الثاني',
                  hintText: 'محمد، أحمد، علي',
                  helperText: 'افصل بين الأسماء بعلامة الفاصلة العربية',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Text('التخصيص', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              judgesAsync.when(
                data: (judges) => DropdownButtonFormField<String>(
                  value: _assignedJudgeId.isEmpty ? null : _assignedJudgeId,
                  decoration: const InputDecoration(labelText: 'القاضي'),
                  items: judges.map((j) {
                    return DropdownMenuItem(value: j.id, child: Text(j.name));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final judge = judges.firstWhere((j) => j.id == v);
                      setState(() {
                        _assignedJudgeId = v;
                        _assignedJudgeName = judge.name;
                      });
                    }
                  },
                ),
                error: (e, _) => const Text('خطأ'),
                loading: () => const Text('جار التحميل...'),
              ),
              const SizedBox(height: 16),
              clerksAsync.when(
                data: (clerks) => DropdownButtonFormField<String>(
                  value: _assignedClerkId.isEmpty ? null : _assignedClerkId,
                  decoration: const InputDecoration(labelText: 'أمين السر'),
                  items: clerks.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final clerk = clerks.firstWhere((c) => c.id == v);
                      setState(() {
                        _assignedClerkId = v;
                        _assignedClerkName = clerk.name;
                      });
                    }
                  },
                ),
                error: (e, _) => const Text('خطأ'),
                loading: () => const Text('جار التحميل...'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(widget.editCaseId != null ? 'حفظ التغييرات' : 'إضافة القضية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
