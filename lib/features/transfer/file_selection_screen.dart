import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('Select Files to Send'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add),
                label: const Text('Add Files'),
              ),
              const SizedBox(height: 16),
              if (_selectedFiles.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No files selected yet.\nTap "Add Files" to choose files to send.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                Text(
                  'Selected Files (${_selectedFiles.length}) — ${_formatSize(_totalSizeBytes)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      final name = file.uri.pathSegments.last;
                      int size = 0;
                      try {
                        size = file.existsSync() ? file.lengthSync() : 0;
                      } catch (_) {}

                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatSize(size)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeFile(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
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
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  _selectedFiles.isEmpty
                      ? 'Select Files First'
                      : 'Next: Choose Recipients (${_selectedFiles.length})',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
