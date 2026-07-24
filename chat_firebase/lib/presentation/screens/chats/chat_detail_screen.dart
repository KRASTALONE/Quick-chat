import 'package:chatappui/data/models/block_status.dart';
import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/chat_service.dart';
import 'package:chatappui/data/services/download_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/widgets/chat_message_bubble.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:chatappui/providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatDetailScreen({super.key, required this.otherUser});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final DownloadService _downloadService = DownloadService();
  late final ChatProvider _chatProvider;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _chatService.markAsRead(widget.otherUser.uid);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }

    _scrollController.jumpTo(offset);
  }

  void _scheduleAutoScroll(int messageCount) {
    if (messageCount == _lastMessageCount) return;
    _lastMessageCount = messageCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: messageCount > 1);
    });
  }

  String _presenceLabel(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    }

    if (user.lastSeen <= 0) {
      return 'Offline';
    }

    final lastSeen = DateTime.fromMillisecondsSinceEpoch(user.lastSeen);
    return 'Last seen ${DateFormat('hh:mm a').format(lastSeen)}';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatProvider.sendTextMessage(
        receiverId: widget.otherUser.uid,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _showAttachmentOptions() async {
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
                title: const Text('Send image'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendMedia(
                    () => _chatProvider.pickAndSendImage(
                      receiverId: widget.otherUser.uid,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Send video'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sendMedia(
                    () => _chatProvider.pickAndSendVideo(
                      receiverId: widget.otherUser.uid,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMedia(Future<bool> Function() action) async {
    try {
      final sent = await action();
      if (!mounted || !sent) return;
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _showMessageActions(MessageModel message) async {
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
              if (message.type == MessageType.text &&
                  (message.text ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copy text'),
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: message.text ?? ''),
                    );
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    UiHelper.showSnackBar(context, 'Message copied.');
                  },
                ),
              if (message.type.isMedia &&
                  (message.mediaUrl ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(
                    message.type == MessageType.image
                        ? 'Download image'
                        : 'Download video',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _downloadMedia(message);
                  },
                ),
              if (message.senderId == _myUid)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _deleteMessage(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadMedia(MessageModel message) async {
    try {
      final filePath = await _downloadService.downloadFile(
        url: message.mediaUrl ?? '',
      );
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Saved to $filePath');
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('This message will be removed from the chat.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _chatService.deleteMessage(
        otherUserId: widget.otherUser.uid,
        message: message,
      );
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Message deleted.');
    } catch (error) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Widget _buildUploadBanner() {
    return Selector<ChatProvider, bool>(
      selector: (_, provider) => provider.isUploading,
      builder: (context, isUploading, _) {
        if (!isUploading) return const SizedBox.shrink();

        return Consumer<ChatProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: provider.uploadProgress),
                  const SizedBox(height: 8),
                  UiHelper.customText(
                    text:
                        'Uploading media... ${(provider.uploadProgress * 100).round()}%',
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

  Widget _buildComposer(BlockStatus blockStatus) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final isComposerEnabled =
            blockStatus.canSendMessage && !provider.isUploading;

        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerTheme.color?.withValues(
                          alpha: 0.5,
                        ) ??
                    Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: isComposerEnabled ? _showAttachmentOptions : null,
                icon: const Icon(Icons.attach_file_rounded),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    enabled: blockStatus.canSendMessage,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: blockStatus.canSendMessage
                          ? 'Type a message...'
                          : blockStatus.description,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isComposerEnabled ? _sendMessage : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isComposerEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>.value(
      value: _chatProvider,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: StreamBuilder<UserModel?>(
            stream: _userService.userStream(widget.otherUser.uid),
            builder: (context, snapshot) {
              final otherUser = snapshot.data ?? widget.otherUser;

              return Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UiHelper.avatar(
                        name: otherUser.displayName,
                        photoUrl: otherUser.photoUrl,
                        radius: 18,
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                otherUser.isOnline ? Colors.green : Colors.grey,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiHelper.customText(
                          text: otherUser.displayName,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          context: context,
                        ),
                        UiHelper.customText(
                          text: _presenceLabel(otherUser),
                          fontSize: 11,
                          context: context,
                          color:
                              otherUser.isOnline ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [UiHelper.darkModeToggle(context)],
        ),
        body: StreamBuilder<BlockStatus>(
          stream: _userService.blockStatusStream(widget.otherUser.uid),
          builder: (context, blockSnapshot) {
            final blockStatus = blockSnapshot.data ?? const BlockStatus();

            return Column(
              children: [
                if (!blockStatus.canSendMessage)
                  Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              blockStatus.description,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          if (blockStatus.blockedByMe)
                            TextButton(
                              onPressed: () async {
                                await _userService
                                    .unblockUser(widget.otherUser.uid);
                                if (!mounted) return;
                                UiHelper.showSnackBar(
                                  context,
                                  'User unblocked.',
                                );
                              },
                              child: const Text('Unblock'),
                            ),
                        ],
                      ),
                    ),
                  ),
                _buildUploadBanner(),
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.messagesStream(widget.otherUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];
                      if (messages.any(
                        (message) =>
                            message.receiverId == _myUid && !message.isRead,
                      )) {
                        _chatService.markAsRead(widget.otherUser.uid);
                      }

                      _scheduleAutoScroll(messages.length);

                      if (messages.isEmpty) {
                        return Center(
                          child: UiHelper.customText(
                            text:
                                'Start chatting with ${widget.otherUser.firstName.isEmpty ? widget.otherUser.username : widget.otherUser.firstName} today.',
                            fontSize: 14,
                            context: context,
                            color: Colors.grey,
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];

                          return ChatMessageBubble(
                            message: message,
                            isMine: message.senderId == _myUid,
                            onLongPress: () => _showMessageActions(message),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildComposer(blockStatus),
              ],
            );
          },
        ),
      ),
    );
  }
}
