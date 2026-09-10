import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cases_provider.dart';
import '../../utils/helpers.dart';

class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({super.key});

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterCategory = 'all';
  String _filterLocation = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(casesStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('القضايا'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'بحث بالرقم، الملخص، الطرف...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {},
                child: casesAsync.when(
                  data: (cases) {
                    final filtered = cases.where((c) {
                      if (_filterStatus != 'all' && c.status != _filterStatus) return false;
                      if (_filterCategory != 'all' && c.category != _filterCategory) return false;
                      if (_filterLocation != 'all' && c.location != _filterLocation) return false;
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        return c.caseNumber.toLowerCase().contains(q) ||
                            c.caseSummary.toLowerCase().contains(q) ||
                            c.year.toLowerCase().contains(q) ||
                            c.partyOneName.toLowerCase().contains(q) ||
                            c.partyTwoName.toLowerCase().contains(q) ||
                            c.partyOnePersons.any((p) => p.toLowerCase().contains(q)) ||
                            c.partyTwoPersons.any((p) => p.toLowerCase().contains(q)) ||
                            c.assignedJudgeName.toLowerCase().contains(q) ||
                            c.assignedClerkName.toLowerCase().contains(q);
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              cases.isEmpty ? 'لا توجد قضايا' : 'لا توجد نتائج للبحث',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (cases.isEmpty) ...[
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/cases/form'),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة قضية'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'عدد النتائج: ${filtered.length}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const Spacer(),
                              if (_searchQuery.isNotEmpty || _filterStatus != 'all' || _filterCategory != 'all' || _filterLocation != 'all')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _filterStatus = 'all';
                                      _filterCategory = 'all';
                                      _filterLocation = 'all';
                                    });
                                    _searchCtrl.clear();
                                  },
                                  child: const Text('مسح الفلتر'),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final c = filtered[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _statusColor(c.status),
                                    child: Text(
                                      c.caseNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(c.caseSummary),
                                  subtitle: Text(
                                    'رقم ${c.caseNumber} | سنة ${c.year} | ${Helpers.locationLabel(c.location)}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Helpers.statusLabel(c.status),
                                        style: TextStyle(
                                          color: _statusColor(c.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        Helpers.locationLabel(c.location),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/cases/detail',
                                    arguments: c.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/cases/form'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('فلترة القضايا'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _filterStatus,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'ended', child: Text('منتهي')),
                  DropdownMenuItem(value: 'archived', child: Text('مؤرشف')),
                ],
                onChanged: (v) => setDialogState(() => _filterStatus = v ?? 'all'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _filterCategory,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'civil', child: Text('مدني')),
                  DropdownMenuItem(value: 'criminal', child: Text('جنائي')),
                  DropdownMenuItem(value: 'personnel', child: Text('شخصي')),
                  DropdownMenuItem(value: 'commercial', child: Text('تجاري')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (v) => setDialogState(() => _filterCategory = v ?? 'all'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _filterLocation,
                decoration: const InputDecoration(labelText: 'الموقع'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'dataCenter', child: Text('مركز البيانات')),
                  DropdownMenuItem(value: 'withClerk', child: Text('عند أمين السر')),
                  DropdownMenuItem(value: 'withJudge', child: Text('عند القاضي')),
                ],
                onChanged: (v) => setDialogState(() => _filterLocation = v ?? 'all'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'ended':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
