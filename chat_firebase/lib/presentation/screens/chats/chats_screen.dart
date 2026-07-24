import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/chat_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/screens/chats/chat_detail_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _formatTimestamp(int milliseconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('HH:mm').format(dateTime);
    }

    return DateFormat('dd/MM').format(dateTime);
  }

  String _chatPreview(Map<String, dynamic> chat) {
    final type = MessageTypeX.fromValue(chat['lastMessageType'] as String?);
    final lastMessage = chat['lastMessage'] as String? ?? '';

    switch (type) {
      case MessageType.image:
        return 'Photo';
      case MessageType.video:
        return 'Video';
      case MessageType.text:
        return lastMessage.isEmpty ? 'Say hello' : lastMessage;
    }
  }

  IconData _chatPreviewIcon(Map<String, dynamic> chat) {
    final type = MessageTypeX.fromValue(chat['lastMessageType'] as String?);

    switch (type) {
      case MessageType.image:
        return Icons.image_outlined;
      case MessageType.video:
        return Icons.videocam_outlined;
      case MessageType.text:
        return Icons.message_outlined;
    }
  }

  Future<void> _showChatActions(UserModel user) async {
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
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete chat'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _deleteChat(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text(
                  'Block user',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _blockUser(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteChat(UserModel user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete chat'),
          content: Text(
            'This hides the chat from your chat list until a new message arrives.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _chatService.deleteChat(user.uid);
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Chat deleted from your list.');
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _blockUser(UserModel user) async {
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block user'),
          content: Text(
            'You will stop receiving messages from ${user.displayName}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Block',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldBlock != true) return;

    try {
      await _userService.blockUser(user);
      if (!mounted) return;
      UiHelper.showSnackBar(context, '${user.displayName} blocked.');
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UiHelper.customText(
          text: 'Chats',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          context: context,
        ),
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.myChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: UiHelper.customText(
                text: 'No conversations yet.\nStart chatting with someone!',
                fontSize: 15,
                textAlign: TextAlign.center,
                context: context,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => UiHelper.sectionDivider(context),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(
                chat['participants'] ?? <String>[],
              );

              final otherUid = participants.firstWhere(
                (id) => id != _myUid,
                orElse: () => '',
              );

              if (otherUid.isEmpty) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<UserModel?>(
                stream: _userService.userStream(otherUid),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  if (user == null) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                    );
                  }

                  final lastTimestamp = chat['lastTimestamp'] as int? ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UiHelper.avatar(
                          name: user.displayName,
                          photoUrl: user.photoUrl,
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.isOnline ? Colors.green : Colors.grey,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: UiHelper.customText(
                      text: user.displayName,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      context: context,
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          _chatPreviewIcon(chat),
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: UiHelper.customText(
                            text: _chatPreview(chat),
                            fontSize: 12,
                            context: context,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: lastTimestamp > 0
                        ? UiHelper.customText(
                            text: _formatTimestamp(lastTimestamp),
                            fontSize: 11,
                            context: context,
                            color: Colors.grey,
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(otherUser: user),
                        ),
                      );
                    },
                    onLongPress: () => _showChatActions(user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
