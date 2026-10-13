import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import 'finder/device_screen.dart';

class FileSelectionScreen extends StatefulWidget {
  const FileSelectionScreen({super.key});

  @override
  State<FileSelectionScreen> createState() => _FileSelectionScreenState();
}

class _FileSelectionScreenState extends State<FileSelectionScreen> {
  final List<File> _selectedFiles = [];

  Future<void> _pickFiles() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(type: FileType.any);

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final platformFile in pickedFiles) {
            final path = platformFile.path;
            if (path != null) {
              final file = File(path);
              if (!_selectedFiles.any((f) => f.path == file.path)) {
                _selectedFiles.add(file);
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick files: $e')));
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  int get _totalSizeBytes {
    int total = 0;
    for (final file in _selectedFiles) {
      try {
        if (file.existsSync()) {
          total += file.lengthSync();
        }
      } catch (_) {}
    }
    return total;
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
    return Scaffold(
      appBar: AppBar(title: const Text('AIRCRYPT // SEND')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                title: 'BROADCAST / SEND FILES',
                subtitle: 'Stage a payload, then choose a nearby recipient.',
                icon: Icons.outbox_outlined,
              ),
              CyberCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.note_add_outlined,
                      size: 28,
                      color: AirCryptColors.textPrimary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '[ STAGE PAYLOAD ]',
                      style: TextStyle(
                        color: AirCryptColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select files to stage your local transfer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CyberButton(
                      label: '[ SELECT FILES ]',
                      icon: Icons.add,
                      isPrimary: false,
                      width: double.infinity,
                      onPressed: _pickFiles,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_selectedFiles.isEmpty)
                const Expanded(
                  child: Center(
                    child: EmptyStateView(
                      icon: Icons.folder_open_outlined,
                      title: 'NO PAYLOAD STAGED',
                      message: 'Select files above to prepare a transfer.',
                    ),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '[ STAGED FILES: ${_selectedFiles.length.toString().padLeft(2, '0')} ]',
                      style: const TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.2,
                      ),
                    ),
                    CyberBadge(
                      label: _formatSize(_totalSizeBytes),
                      color: AirCryptColors.accentCyan,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      final name = file.uri.pathSegments.last;
                      int size = 0;
                      try {
                        size = file.existsSync() ? file.lengthSync() : 0;
                      } catch (_) {}

                      return CyberCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file_outlined,
                              color: AirCryptColors.textPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AirCryptColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatSize(size),
                                    style: const TextStyle(
                                      color: AirCryptColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AirCryptColors.accentRed,
                                size: 20,
                              ),
                              onPressed: () => _removeFile(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                CyberCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.enhanced_encryption_outlined,
                        color: AirCryptColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '[ PAYLOAD READY ]',
                              style: TextStyle(
                                color: AirCryptColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'Files are encrypted before they leave this device.',
                              style: TextStyle(
                                color: AirCryptColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              CyberButton(
                onPressed: _selectedFiles.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeviceScreen(
                              selectedFiles: List.unmodifiable(_selectedFiles),
                            ),
                          ),
                        );
                      },
                icon: Icons.arrow_forward,
                label: _selectedFiles.isEmpty
                    ? '[ ADD FILES TO CONTINUE ]'
                    : '[ CHOOSE RECIPIENTS // ${_selectedFiles.length} ]',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
