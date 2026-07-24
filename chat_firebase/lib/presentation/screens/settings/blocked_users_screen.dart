import 'package:chatappui/data/models/blocked_user_model.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _confirmUnblock(
    BuildContext context,
    UserService userService,
    BlockedUserModel user,
  ) async {
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unblock user'),
          content: Text('Allow ${user.displayName} to message you again?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Unblock'),
            ),
          ],
        );
      },
    );

    if (shouldUnblock != true) return;

    await userService.unblockUser(user.uid);
    if (!context.mounted) return;
    UiHelper.showSnackBar(context, '${user.displayName} unblocked.');
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: UiHelper.customText(
          text: 'Blocked Users',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          context: context,
        ),
      ),
      body: StreamBuilder<List<BlockedUserModel>>(
        stream: userService.blockedUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final blockedUsers = snapshot.data ?? [];
          if (blockedUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: UiHelper.customText(
                  text: 'You have not blocked anyone.',
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  context: context,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blockedUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: UiHelper.avatar(
                    name: user.displayName,
                    photoUrl: user.photoUrl,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.username}'),
                  trailing: TextButton(
                    onPressed: () => _confirmUnblock(
                      context,
                      userService,
                      user,
                    ),
                    child: const Text('Unblock'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
