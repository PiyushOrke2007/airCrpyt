import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aircrypt/core/database/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database can be opened', () async {
    final service = DatabaseService(
      databaseName: 'database_service_test.db',
    );

    final database = await service.database;

    expect(database.isOpen, isTrue);

    await service.close();
  });
}