import 'package:flutter/material.dart';

import '../../../../core/database/trash_repository.dart';
import '../../../../core/models/trash_item.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TrashRepository _repository =
  TrashRepository();

  List<TrashItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final items =
    await _repository.getAllTrashItems();

    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  int _remainingDays(TrashItem item) {
    final difference =
    item.permanentDeleteAt.difference(
      DateTime.now(),
    );

    if (difference.isNegative) {
      return 0;
    }

    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _items.isEmpty
          ? const Center(
        child: Text(
          'Trash is empty.',
        ),
      )
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return ListTile(
            leading: const Icon(
              Icons.delete_outline,
            ),
            title: Text(
              item.trashPath
                  .split('/')
                  .last,
            ),
            subtitle: Text(
              '${_remainingDays(item)} days remaining',
            ),
          );
        },
      ),
    );
  }
}