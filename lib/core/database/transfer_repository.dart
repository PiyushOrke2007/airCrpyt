import 'package:sqflite/sqflite.dart';
import '../models/transfer_file.dart';
import '../models/transfer.dart';
import 'database_service.dart';

class TransferRepository {
  final DatabaseService _databaseService;

  TransferRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  Future<void> insertTransfer(Transfer transfer) async {
    final database = await _databaseService.database;

    await database.insert(
      'transfers',
      {
        'id': transfer.id,
        'type': transfer.type.name,
        'status': transfer.status.name,
        'peer_device_id': transfer.peerDeviceId,
        'peer_device_name': transfer.peerDeviceName,
        'created_at': transfer.createdAt.toIso8601String(),
        'completed_at': transfer.completedAt?.toIso8601String(),
        'total_size': transfer.totalSize,
      },
    );
  }

  Future<Transfer?> getTransfer(String id) async {
    final database = await _databaseService.database;

    final results = await database.query(
      'transfers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return _fromMap(results.first);
  }

  Transfer _fromMap(Map<String, Object?> map) {
    return Transfer(
      id: map['id']! as String,
      type: TransferType.values.byName(
        map['type']! as String,
      ),
      status: TransferStatus.values.byName(
        map['status']! as String,
      ),
      peerDeviceId: map['peer_device_id']! as String,
      peerDeviceName: map['peer_device_name']! as String,
      createdAt: DateTime.parse(
        map['created_at']! as String,
      ),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(
        map['completed_at']! as String,
      ),
      totalSize: map['total_size']! as int,
    );
  }

  Future<void> insertTransferFile(
      TransferFile transferFile,
      ) async {
    final database = await _databaseService.database;

    await database.insert(
      'transfer_files',
      {
        'id': transferFile.id,
        'transfer_id': transferFile.transferId,
        'file_name': transferFile.fileName,
        'relative_path': transferFile.relativePath,
        'file_size': transferFile.fileSize,
        'status': transferFile.status.name,
        'source_path': transferFile.sourcePath,
        'saved_path': transferFile.savedPath,
      },
    );
  }

  Future<List<TransferFile>> getTransferFiles(
      String transferId,
      ) async {
    final database = await _databaseService.database;

    final results = await database.query(
      'transfer_files',
      where: 'transfer_id = ?',
      whereArgs: [transferId],
      orderBy: 'file_name ASC',
    );

    return results.map(_fileFromMap).toList();
  }

  TransferFile _fileFromMap(
      Map<String, Object?> map,
      ) {
    return TransferFile(
      id: map['id']! as String,
      transferId: map['transfer_id']! as String,
      fileName: map['file_name']! as String,
      relativePath: map['relative_path'] as String?,
      fileSize: map['file_size']! as int,
      status: TransferFileStatus.values.byName(
        map['status']! as String,
      ),
      sourcePath: map['source_path'] as String?,
      savedPath: map['saved_path'] as String?,
    );
  }



}