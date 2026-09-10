import 'package:flutter_test/flutter_test.dart';
import 'package:court_case_tracker/models/index.dart';
import 'package:court_case_tracker/utils/helpers.dart';
import 'package:court_case_tracker/utils/validators.dart';

void main() {
  group('CaseModel', () {
    test('copyWith preserves unspecified fields', () {
      final created = DateTime(2024, 1, 1);
      final c = CaseModel(
        id: 'c1',
        caseNumber: '101',
        year: '2024',
        category: 'civil',
        caseSummary: 'ملخص القضية',
        partyOneName: 'الطرف الأول',
        partyOnePersons: const ['أحمد', 'محمد'],
        status: 'active',
        createdAt: created,
        createdBy: 'u1',
      );

      final updated = c.copyWith(status: 'ended');

      expect(updated.id, 'c1');
      expect(updated.status, 'ended');
      expect(updated.caseNumber, '101');
      expect(updated.partyOneName, 'الطرف الأول');
      expect(updated.partyOnePersons, ['أحمد', 'محمد']);
      expect(updated.createdAt, created, reason: 'copyWith must preserve createdAt');
      expect(updated.createdBy, 'u1');
    });

    test('displayName formats correctly', () {
      final c = CaseModel(id: 'c1', caseNumber: '55', year: '2020');
      expect(c.displayName, 'قضية رقم 55 لسنة 2020');
    });
  });

  group('TransferModel', () {
    test('isReturned reflects returnedAt', () {
      final t = TransferModel(
        id: 't1',
        caseId: 'c1',
        fromUserId: 'a',
        fromUserName: 'A',
        toUserId: 'b',
        toUserName: 'B',
        type: 'toClerk',
      );
      expect(t.isReturned, isFalse);

      final returned = t.copyWith(returnedAt: DateTime.now());
      expect(returned.isReturned, isTrue);
    });

    test('verified flags update via copyWith', () {
      final t = TransferModel(
        id: 't1',
        caseId: 'c1',
        fromUserId: 'a',
        fromUserName: 'A',
        toUserId: 'b',
        toUserName: 'B',
        type: 'toJudge',
      );
      final verified = t.copyWith(verified: true, verifiedBy: 'B');
      expect(verified.verified, isTrue);
      expect(verified.verifiedBy, 'B');
    });
  });

  group('UserModel', () {
    test('admin defaults include manageUsers', () {
      final admin = UserModel(id: 'u1', email: 'a@a.com', name: 'مدير', role: 'admin');
      expect(admin.permissions['manageUsers'], isTrue);
      expect(admin.permissions['transferFolder'], isTrue);
    });

    test('clerk defaults lack changeStatus', () {
      final clerk = UserModel(id: 'u2', email: 'b@b.com', name: 'أمين', role: 'clerk');
      expect(clerk.permissions['changeStatus'], isFalse);
      expect(clerk.permissions['manageUsers'], isFalse);
    });
  });

  group('Helpers', () {
    test('categoryLabel returns Arabic label', () {
      expect(Helpers.categoryLabel('civil'), 'مدني');
      expect(Helpers.categoryLabel('unknown'), 'unknown');
    });

    test('formatDate handles null', () {
      expect(Helpers.formatDate(null), '');
    });

    test('calculatePeriod returns day count', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 1, 2);
      expect(Helpers.calculatePeriod(from, to), 'يوم واحد');
      final to3 = DateTime(2024, 1, 3);
      expect(Helpers.calculatePeriod(from, to3), '2 يوم');
    });
  });

  group('Validators', () {
    test('required rejects empty', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('text'), isNull);
    });

    test('year validates range', () {
      expect(Validators.year('999'), isNotNull);
      expect(Validators.year('2024'), isNull);
      expect(Validators.year(''), isNotNull);
    });
  });
}
