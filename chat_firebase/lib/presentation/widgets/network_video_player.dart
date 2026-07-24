import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NetworkVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double height;
  final BorderRadius borderRadius;
  final bool autoPlay;

  const NetworkVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.autoPlay = false,
  });

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (widget.autoPlay) {
        await controller.play();
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: widget.borderRadius,
        ),
        alignment: Alignment.center,
        child: UiHelper.customText(
          text: 'Video unavailable',
          fontSize: 13,
          context: context,
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return UiHelper.loadingPlaceholder(
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }

    final controller = _controller!;
    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayback,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: isPlaying ? 0.10 : 0.20,
                  ),
                ),
              ),
              Center(
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
