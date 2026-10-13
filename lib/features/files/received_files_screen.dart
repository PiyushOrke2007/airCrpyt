import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/file_storage_service.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import '../settings/settings_screen.dart';

class ReceivedFilesScreen extends StatefulWidget {
  const ReceivedFilesScreen({super.key});

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  final FileStorageService _storageService = FileStorageService();
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

  @override
  Widget build(BuildContext context) {
    final visibleFiles = _files
        .where((file) => _fileName(file).toLowerCase().contains(_filter))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRCRYPT // RECEIVED'),
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
                  return CyberCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: AirCryptColors.textPrimary,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fileDetails(file),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AirCryptColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CyberBadge(
                          label: _fileName(file).split('.').last.toUpperCase(),
                          color: AirCryptColors.textPrimary,
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
