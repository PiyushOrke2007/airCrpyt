import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/core/database/database_service.dart';
import 'package:aircrypt/core/database/trash_repository.dart';
import 'package:aircrypt/core/services/trash_service.dart';

import 'fake_file_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Database initialization is handled by the
    // SQLite FFI setup used by the repository tests.
  });

  test('trash service can be created', () {
    final storage = FakeFileStorage();
    final repository = TrashRepository(
      databaseService: DatabaseService(),
    );

    final service = TrashService(
      storage: storage,
      repository: repository,
    );

    expect(service, isNotNull);
  });
}