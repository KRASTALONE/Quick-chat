import 'package:chatappui/data/models/status_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/presentation/widgets/network_video_player.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusViewerScreen extends StatefulWidget {
  final UserModel user;
  final List<StatusModel> statuses;

  const StatusViewerScreen({
    super.key,
    required this.user,
    required this.statuses,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = widget.statuses[_currentIndex];
    final mediaHeight = MediaQuery.of(context).size.height * 0.55;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UiHelper.avatar(
              name: widget.user.displayName,
              photoUrl: widget.user.photoUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiHelper.customText(
                    text: widget.user.displayName,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    context: context,
                  ),
                  UiHelper.customText(
                    text: DateFormat(
                      'dd MMM, hh:mm a',
                    ).format(activeStatus.timestamp),
                    fontSize: 11,
                    context: context,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: List.generate(
                widget.statuses.length,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index == widget.statuses.length - 1 ? 0 : 6,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.statuses.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final status = widget.statuses[index];
                final borderRadius = BorderRadius.circular(24);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: status.type == StatusType.image
                      ? ClipRRect(
                          borderRadius: borderRadius,
                          child: Image.network(
                            status.mediaUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return UiHelper.loadingPlaceholder(
                                height: mediaHeight,
                                borderRadius: borderRadius,
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: mediaHeight,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: borderRadius,
                              ),
                              alignment: Alignment.center,
                              child: UiHelper.customText(
                                text: 'Status could not be loaded',
                                fontSize: 13,
                                context: context,
                              ),
                            ),
                          ),
                        )
                      : NetworkVideoPlayer(
                          videoUrl: status.mediaUrl,
                          height: mediaHeight,
                          borderRadius: borderRadius,
                          autoPlay: true,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
