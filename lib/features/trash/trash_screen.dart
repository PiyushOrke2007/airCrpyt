import 'package:flutter/material.dart';

import '../../core/database/trash_repository.dart';
import '../../core/models/trash_item.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TrashRepository _repository = TrashRepository();

  List<TrashItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final items = await _repository.getAllTrashItems();

    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  int _remainingDays(TrashItem item) {
    final difference = item.permanentDeleteAt.difference(
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
        title: const Text('SECURE TRASH RECOVERY'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AirCryptColors.accentCyan),
              )
            : _items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 56,
                          color: AirCryptColors.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'TRASH IS EMPTY',
                          style: TextStyle(
                            color: AirCryptColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Deleted items are held temporarily before permanent shredding.',
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
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final remaining = _remainingDays(item);

                      return CyberCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        borderColor: AirCryptColors.accentRed.withOpacity(0.3),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AirCryptColors.accentRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: AirCryptColors.accentRed,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.trashPath.split('/').last,
                                    style: const TextStyle(
                                      color: AirCryptColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$remaining days remaining before permanent deletion',
                                    style: const TextStyle(
                                      color: AirCryptColors.accentAmber,
                                      fontSize: 11,
                                    ),
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
