// coverage:ignore-file
import 'package:origna_gta/utils/constants.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:video_player/video_player.dart';

/// Full-screen video player dialog with Chewie.
class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: _hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: DesignTokens.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'product.video_not_playable'.tr(),
                        style: const TextStyle(color: DesignTokens.white),
                      ),
                    ],
                  )
                : (_chewieController != null &&
                          _chewieController!
                              .videoPlayerController
                              .value
                              .isInitialized
                      ? AspectRatio(
                          aspectRatio:
                              _videoPlayerController!.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        )
                      : const ModernLoadingIndicator()),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'common.close'.tr(),
                icon:
                    const Icon(Icons.close, color: DesignTokens.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      _videoPlayerController = controller;
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        placeholder: const Center(child: ModernLoadingIndicator()),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: DesignTokens.white),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }
}
