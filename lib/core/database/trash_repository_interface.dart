import '../models/trash_item.dart';

abstract class TrashRepositoryInterface {
  Future<void> insertTrashItem(TrashItem item);

  Future<TrashItem?> getTrashItem(String id);

  Future<List<TrashItem>> getAllTrashItems();

  Future<void> deleteTrashItem(String id);

  Future<List<TrashItem>> getExpiredItems(DateTime now);
}