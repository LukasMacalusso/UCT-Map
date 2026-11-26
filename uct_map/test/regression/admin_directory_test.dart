import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/application/directory/filter_users.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/managed_user.dart';
import 'package:uct_map/domain/repositories/identity_repository.dart';
import 'package:uct_map/presentation/screens/roles/admin_users_screen.dart';
import 'package:uct_map/presentation/screens/roles/admin_user_detail_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

class Identity implements IdentityRepository {
  int reads = 0;
  final users = List.generate(
    25,
    (i) => ManagedUser(
      id: 'u$i',
      name: 'Cuenta $i',
      email: 'u$i@uct.cl',
      role: i.isEven ? 'Student' : 'Teacher',
      isSuspended: i % 3 == 0,
    ),
  );
  @override
  Future<List<ManagedUser>> getUsers() async => users;
  @override
  Future<ManagedUser> getUserById(String id) async {
    reads++;
    return users.firstWhere((u) => u.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'filtra rol, suspensión y correo de manera combinada antes de paginar',
    () {
      final users = Identity().users;
      expect(
        filterUsers(users, role: 'Teacher', suspended: true).map((u) => u.id),
        ['u3', 'u9', 'u15', 'u21'],
      );
      expect(filterUsers(users, query: 'U24@').single.id, 'u24');
    },
  );
  testWidgets(
    'administración pagina y muestra perfil real del usuario elegido',
    (tester) async {
      final session = SessionController(storage: MemoryStorage());
      await session.ready;
      await account(session, 'admin', 'Admin');
      ApiClientProvider.reset(session: session);
      final repository = Identity();
      await tester.pumpWidget(
        MaterialApp(home: AdminUsersScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 de 2'), findsNothing); // pie fuera del viewport
      await tester.scrollUntilVisible(
        find.byTooltip('Página siguiente'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 10000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cuenta 20'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cuenta 0'), findsNothing);
      final profile = find.text('Ver perfil').first;
      await tester.ensureVisible(profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.byType(AdminUserDetailScreen), findsOneWidget);
      expect(repository.reads, 1);
      expect(find.text('Cuenta 20'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      ApiClientProvider.reset();
    },
  );
  testWidgets('otra función no consulta perfiles administrativos', (
    tester,
  ) async {
    final session = SessionController(storage: MemoryStorage());
    await session.ready;
    await account(session, 'student', 'Student');
    ApiClientProvider.reset(session: session);
    final repository = Identity();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminUserDetailScreen(userId: 'u1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.reads, 0);
    expect(find.text('Cuenta 1'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    ApiClientProvider.reset();
  });
}
