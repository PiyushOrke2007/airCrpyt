class TrashItem {
  final String id;
  final String fileId;
  final String originalPath;
  final String trashPath;
  final DateTime deletedAt;
  final DateTime permanentDeleteAt;

  const TrashItem({
    required this.id,
    required this.fileId,
    required this.originalPath,
    required this.trashPath,
    required this.deletedAt,
    required this.permanentDeleteAt,
  });
}