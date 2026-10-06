import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/file_storage_service.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';

class ReceivedFilesScreen extends StatefulWidget {
  const ReceivedFilesScreen({super.key});

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  final FileStorageService _storageService = FileStorageService();

  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory = await _storageService.getReceivedDirectory();

    final entities = await directory
        .list(recursive: true)
        .where(
          (entity) => entity is File,
        )
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _files = entities;
      _isLoading = false;
    });
  }

  String _fileName(FileSystemEntity entity) {
    return entity.path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RECEIVED VAULT'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AirCryptColors.accentCyan),
              )
            : _files.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 56,
                          color: AirCryptColors.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'NO RECEIVED FILES IN VAULT',
                          style: TextStyle(
                            color: AirCryptColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Files transferred from nearby peers will appear here.',
                          style: TextStyle(
                            color: AirCryptColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];

                      return CyberCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AirCryptColors.accentCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AirCryptColors.accentCyan,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName(file),
                                    style: const TextStyle(
                                      color: AirCryptColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    file.path,
                                    style: const TextStyle(
                                      color: AirCryptColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
