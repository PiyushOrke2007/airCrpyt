import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/file_storage_service.dart';

class ReceivedFilesScreen extends StatefulWidget {
  const ReceivedFilesScreen({super.key});

  @override
  State<ReceivedFilesScreen> createState() =>
      _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState
    extends State<ReceivedFilesScreen> {
  final FileStorageService _storageService =
  FileStorageService();

  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory =
    await _storageService.getReceivedDirectory();

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
        title: const Text('Received Files'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _files.isEmpty
          ? const Center(
        child: Text(
          'No files received yet.',
        ),
      )
          : ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];

          return ListTile(
            leading: const Icon(
              Icons.insert_drive_file,
            ),
            title: Text(
              _fileName(file),
            ),
            subtitle: Text(
              file.path,
            ),
          );
        },
      ),
    );
  }
}