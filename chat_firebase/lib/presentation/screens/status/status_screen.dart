import 'package:chatappui/data/models/status_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/status_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/screens/status/status_viewer_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:chatappui/providers/status_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final StatusService _statusService = StatusService();
  final UserService _userService = UserService();
  late final StatusProvider _statusProvider;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _statusProvider = StatusProvider();
    _statusProvider.cleanupExpiredStatuses();
  }

  @override
  void dispose() {
    _statusProvider.dispose();
    super.dispose();
  }

  Future<void> _handleCreateStatus(Future<bool> Function() action) async {
    try {
      final created = await action();
      if (!mounted || !created) return;
      UiHelper.showSnackBar(context, 'Status uploaded successfully.');
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _showStatusOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Upload image status'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleCreateStatus(_statusProvider.createImageStatus);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Upload video status'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleCreateStatus(_statusProvider.createVideoStatus);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<StatusModel>> _groupStatuses(List<StatusModel> statuses) {
    final grouped = <String, List<StatusModel>>{};

    for (final status in statuses) {
      grouped.putIfAbsent(status.userId, () => []).add(status);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return grouped;
  }

  String _formatStatusTime(DateTime timestamp) {
    final now = DateTime.now();
    final sameDay = now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    if (sameDay) {
      return 'Today, ${DateFormat('hh:mm a').format(timestamp)}';
    }

    return DateFormat('dd MMM, hh:mm a').format(timestamp);
  }

  void _openViewer(UserModel user, List<StatusModel> statuses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusViewerScreen(user: user, statuses: statuses),
      ),
    );
  }

  Widget _buildUploadBanner() {
    return Selector<StatusProvider, bool>(
      selector: (_, provider) => provider.isUploading,
      builder: (context, isUploading, _) {
        if (!isUploading) return const SizedBox.shrink();

        return Consumer<StatusProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: provider.uploadProgress),
                  const SizedBox(height: 8),
                  UiHelper.customText(
                    text:
                        'Uploading status... ${(provider.uploadProgress * 100).round()}%',
                    fontSize: 12,
                    context: context,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatusProvider>.value(
      value: _statusProvider,
      child: Scaffold(
        appBar: AppBar(
          title: UiHelper.customText(
            text: 'Status',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            context: context,
          ),
          actions: [UiHelper.darkModeToggle(context)],
        ),
        floatingActionButton: Consumer<StatusProvider>(
          builder: (context, provider, _) {
            return FloatingActionButton(
              onPressed: provider.isUploading ? null : _showStatusOptions,
              child: const Icon(Icons.add),
            );
          },
        ),
        body: Column(
          children: [
            _buildUploadBanner(),
            Expanded(
              child: StreamBuilder<List<StatusModel>>(
                stream: _statusService.activeStatusesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final grouped = _groupStatuses(snapshot.data ?? []);
                  final myStatuses = grouped.remove(_myUid) ?? [];
                  final otherUsers = grouped.entries.toList()
                    ..sort(
                      (a, b) => b.value.last.timestamp
                          .compareTo(a.value.last.timestamp),
                    );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      StreamBuilder<UserModel?>(
                        stream: _userService.userStream(_myUid),
                        builder: (context, userSnapshot) {
                          final currentUser = userSnapshot.data;

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: UiHelper.avatar(
                                name: currentUser?.displayName ?? 'You',
                                photoUrl: currentUser?.photoUrl,
                                radius: 28,
                              ),
                              title: UiHelper.customText(
                                text: 'My Status',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                context: context,
                              ),
                              subtitle: UiHelper.customText(
                                text: myStatuses.isEmpty
                                    ? 'Tap the button below to add image or video status'
                                    : _formatStatusTime(
                                        myStatuses.last.timestamp),
                                fontSize: 12,
                                context: context,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed:
                                    context.watch<StatusProvider>().isUploading
                                        ? null
                                        : _showStatusOptions,
                              ),
                              onTap: currentUser != null &&
                                      myStatuses.isNotEmpty
                                  ? () => _openViewer(currentUser, myStatuses)
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      UiHelper.customText(
                        text: 'Recent Updates',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        context: context,
                      ),
                      const SizedBox(height: 8),
                      if (otherUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: UiHelper.customText(
                            text:
                                'No active status updates right now. Ask a friend to post one.',
                            fontSize: 13,
                            textAlign: TextAlign.center,
                            context: context,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        )
                      else
                        ...otherUsers.map(
                          (entry) => StreamBuilder<UserModel?>(
                            stream: _userService.userStream(entry.key),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;
                              if (user == null) {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: UiHelper.avatar(
                                      name: user.displayName,
                                      photoUrl: user.photoUrl,
                                      radius: 24,
                                    ),
                                  ),
                                  title: UiHelper.customText(
                                    text: user.displayName,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    context: context,
                                  ),
                                  subtitle: UiHelper.customText(
                                    text: _formatStatusTime(
                                      entry.value.last.timestamp,
                                    ),
                                    fontSize: 12,
                                    context: context,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  trailing: UiHelper.customText(
                                    text:
                                        '${entry.value.length} update${entry.value.length > 1 ? 's' : ''}',
                                    fontSize: 11,
                                    context: context,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onTap: () => _openViewer(user, entry.value),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
