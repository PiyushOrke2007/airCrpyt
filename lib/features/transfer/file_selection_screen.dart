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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick files: $e')),
        );
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
      appBar: AppBar(
        title: const Text('SELECT FILES'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add Files Action
              CyberCard(
                showGlow: _selectedFiles.isEmpty,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.note_add_outlined,
                      size: 36,
                      color: AirCryptColors.accentCyan,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'STAGE FILES FOR TRANSFER',
                      style: TextStyle(
                        color: AirCryptColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select files from local storage to send securely.',
                      style: TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CyberButton(
                      label: 'BROWSE / ADD FILES',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: AirCryptColors.textMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No files staged for transmission.',
                          style: TextStyle(color: AirCryptColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // File count summary header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STAGED FILES (${_selectedFiles.length})',
                      style: const TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AirCryptColors.accentCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AirCryptColors.accentCyan,
                                size: 20,
                              ),
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
                                      fontSize: 14,
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

                // Pre-encryption status visualizer
                CyberCard(
                  borderColor: AirCryptColors.accentGreen.withOpacity(0.3),
                  backgroundColor: AirCryptColors.accentGreen.withOpacity(0.06),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.enhanced_encryption_outlined,
                        color: AirCryptColors.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ENCRYPTION PREPARATION READY',
                              style: TextStyle(
                                color: AirCryptColors.accentGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'Files will be encrypted with AES-256 before network transmission.',
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
                    ? 'SELECT FILES FIRST'
                    : 'NEXT: CHOOSE RECIPIENTS (${_selectedFiles.length})',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
