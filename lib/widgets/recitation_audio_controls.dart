import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme/app_colors.dart';

/// Shared playlist controls backed by the app-wide AudioService.
class RecitationAudioControls extends StatelessWidget {
  final List<String> playlist;

  const RecitationAudioControls({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audio, _) {
        final isActive =
            audio.currentAsset != null && playlist.contains(audio.currentAsset);
        final isPlaying = isActive && audio.isPlaying;
        final isPaused = isActive && audio.isPaused;

        Future<void> handlePlayPause() async {
          if (isPlaying) {
            await audio.pause();
          } else if (isPaused) {
            await audio.resume();
          } else {
            await audio.playPlaylist(playlist);
          }
        }

        return Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.turquoiseSoft,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: handlePlayPause,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.volume_up_rounded,
                          color: AppColors.turquoise,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isPlaying
                              ? 'Duraklat'
                              : isPaused
                              ? 'Devam Et'
                              : 'Dinle',
                          style: const TextStyle(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 12),
              Material(
                color: AppColors.goldSoft,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: audio.stop,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.stop_rounded, color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
