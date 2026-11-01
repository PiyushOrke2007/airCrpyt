import 'package:flutter/material.dart';

import '../../core/database/trash_repository.dart';
import '../../core/models/trash_item.dart';
import '../../core/services/trash_service.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TrashRepository _repository = TrashRepository();
  final TrashService _trashService = TrashService();

  List<TrashItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    try {
      // Auto-delete items older than 20 days
      await _trashService.cleanupExpiredItems();

      final items = await _repository.getAllTrashItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load trash: $error';
        _isLoading = false;
      });
    }
  }

  int _remainingDays(TrashItem item) {
    final difference = item.permanentDeleteAt.difference(DateTime.now());
    return difference.isNegative ? 0 : difference.inDays;
  }

  Future<void> _restore(TrashItem item) async {
    try {
      await _trashService.restore(item);
      await _loadTrash();
      if (mounted) _showMessage('RECOVERED: ${_fileName(item)}');
    } catch (error) {
      if (mounted) _showMessage('RECOVER FAILED: $error');
    }
  }

  Future<void> _deletePermanently(TrashItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PERMANENT DELETE?'),
        content: Text(
          '${_fileName(item)} will be removed permanently and cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('[ CANCEL ]'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('[ DELETE ]'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _trashService.permanentlyDelete(item);
      await _loadTrash();
      if (mounted) _showMessage('DELETED: ${_fileName(item)}');
    } catch (error) {
      if (mounted) _showMessage('DELETE FAILED: $error');
    }
  }

  String _fileName(TrashItem item) =>
      item.trashPath.split(RegExp(r'[/\\]')).last;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIRCRPYT // TRASH')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AirCryptColors.accentCyan,
                ),
              )
            : _errorMessage != null
            ? EmptyStateView(
                icon: Icons.error_outline,
                title: 'TRASH UNAVAILABLE',
                message: _errorMessage!,
              )
            : _items.isEmpty
            ? const EmptyStateView(
                icon: Icons.delete_outline,
                title: 'TRASH IS EMPTY',
                message: 'Items in trash are automatically deleted after 20 days.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '[ ISOLATED FILES ]',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_items.length.toString().padLeft(2, '0')} ITEMS',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AirCryptColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Items stay in trash for 20 days before automatic deletion.',
                    style: TextStyle(
                      fontSize: 9,
                      color: AirCryptColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in _items)
                    CyberCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fileName(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              CyberBadge(
                                label: '${_remainingDays(item)}D LEFT',
                                color: AirCryptColors.textPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'DELETED: ${MaterialLocalizations.of(context).formatShortDate(item.deletedAt)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AirCryptColors.textSecondary,
                            ),
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _restore(item),
                                    icon: const Icon(
                                      Icons.restore,
                                      size: 14,
                                      color: AirCryptColors.textPrimary,
                                    ),
                                    label: const Text(
                                      'RECOVER',
                                      style: TextStyle(
                                        fontFamily: 'Silkscreen',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AirCryptColors.textPrimary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _deletePermanently(item),
                                    icon: const Icon(
                                      Icons.delete_forever_outlined,
                                      size: 14,
                                      color: AirCryptColors.accentRed,
                                    ),
                                    label: const Text(
                                      'DELETE',
                                      style: TextStyle(
                                        fontFamily: 'Silkscreen',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AirCryptColors.accentRed,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
