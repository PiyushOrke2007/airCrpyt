import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/services/file_storage_service.dart';
import '../../core/services/trash_service.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_screen.dart';

class ReceivedFilesScreen extends StatefulWidget {
  const ReceivedFilesScreen({super.key});

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  final FileStorageService _storageService = FileStorageService();
  final TrashService _trashService = TrashService();

  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory = await _storageService.getReceivedDirectory();
    final files = await directory
        .list(recursive: true)
        .where((entity) => entity is File)
        .toList();

    if (!mounted) return;
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  String _fileName(FileSystemEntity entity) =>
      entity.path.split(Platform.pathSeparator).last;

  String _fileDetails(FileSystemEntity entity) {
    try {
      final stat = entity.statSync();
      final size = _formatSize(stat.size);
      final date = MaterialLocalizations.of(context)
          .formatShortDate(stat.modified);
      return '$size · $date';
    } on FileSystemException {
      return entity.path;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _openFile(FileSystemEntity file) async {
    final filePath = file.path;
    final fileName = _fileName(file);
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';

    try {
      final result = await OpenFilex.open(filePath);
      if (!mounted) return;

      if (result.type == ResultType.noAppToOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No application found on device to open .$extension files.',
            ),
            backgroundColor: AirCryptColors.accentRed,
          ),
        );
      } else if (result.type == ResultType.fileNotFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found or has been moved.'),
            backgroundColor: AirCryptColors.accentRed,
          ),
        );
      } else if (result.type == ResultType.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: AirCryptColors.accentRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open file: $e'),
          backgroundColor: AirCryptColors.accentRed,
        ),
      );
    }
  }

  Future<void> _moveToTrash(FileSystemEntity file) async {
    final fileName = _fileName(file);
    try {
      await _trashService.moveToTrash(
        fileId: fileName,
        filePath: file.path,
      );
      await _loadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved "$fileName" to Trash.'),
          action: SnackBarAction(
            label: 'VIEW TRASH',
            textColor: AirCryptColors.accentCyan,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not move to trash: $e'),
          backgroundColor: AirCryptColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleFiles = _files
        .where((file) => _fileName(file).toLowerCase().contains(_filter))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRCRPYT // RECEIVED'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AirCryptColors.accentCyan,
                ),
              )
            : _files.isEmpty
            ? const EmptyStateView(
                icon: Icons.folder_off_outlined,
                title: 'VAULT EMPTY',
                message: 'Files received from nearby devices will appear here.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: visibleFiles.isEmpty ? 3 : visibleFiles.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECEIVED FILES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                            ),
                          ),
                          Text(
                            '${_files.length} files',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AirCryptColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        onChanged: (value) => setState(
                          () => _filter = value.trim().toLowerCase(),
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 18),
                          hintText: 'Filter files...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    );
                  }
                  if (visibleFiles.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: EmptyStateView(
                        icon: Icons.search_off,
                        title: 'NO MATCHES',
                        message: 'Try another file name.',
                      ),
                    );
                  }

                  final file = visibleFiles[index - 2];
                  final extension = _fileName(file).contains('.')
                      ? _fileName(file).split('.').last.toUpperCase()
                      : 'FILE';

                  return CyberCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AirCryptColors.cardBgElevated,
                                border: Border.all(
                                  color: AirCryptColors.cardBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 20,
                                color: AirCryptColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName(file),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fileDetails(file),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AirCryptColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            CyberBadge(
                              label: extension,
                              color: AirCryptColors.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () => _moveToTrash(file),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: AirCryptColors.accentRed,
                                ),
                                label: const Text(
                                  'TRASH',
                                  style: TextStyle(
                                    fontFamily: 'Silkscreen',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: AirCryptColors.accentRed,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                    color: AirCryptColors.accentRed,
                                    width: 1.2,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  backgroundColor: AirCryptColors.bgSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () => _openFile(file),
                                icon: const Icon(
                                  Icons.launch,
                                  size: 14,
                                  color: AirCryptColors.textPrimary,
                                ),
                                label: const Text(
                                  'OPEN',
                                  style: TextStyle(
                                    fontFamily: 'Silkscreen',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: AirCryptColors.textPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                    color: AirCryptColors.cardBorder,
                                    width: 1.2,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  backgroundColor: AirCryptColors.bgSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
