import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/presentation/widgets/network_video_player.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        isMine ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final timeLabel = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.all(message.type == MessageType.text ? 12 : 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMessageBody(context, textColor),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.75),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? Colors.lightBlueAccent
                          : textColor.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return NetworkVideoPlayer(
          videoUrl: message.mediaUrl ?? '',
          height: 220,
        );
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(color: textColor, fontSize: 14, height: 1.35),
        );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: 220,
        height: 260,
        child: Image.network(
          message.mediaUrl ?? '',
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return UiHelper.loadingPlaceholder(
              height: 260,
              width: 220,
              borderRadius: borderRadius,
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: UiHelper.customText(
              text: 'Image unavailable',
              fontSize: 13,
              context: context,
            ),
          ),
        ),
      ),
    );
  }
}
