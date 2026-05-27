import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/media_file.dart';
import 'ffmpeg_checker.dart';

class MediaInfoService {
  Future<MediaFile> getMediaInfo(String path) async {
    debugPrint('MediaInfoService.getMediaInfo: path=$path');

    final basic = await MediaFile.fromPath(path);

    try {
      final ffprobe = FfmpegChecker.ffprobePath ?? 'ffprobe';
      final result = await Process.run(ffprobe, [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        path,
      ],
        environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'},
      );

      if (result.exitCode != 0) {
        debugPrint('ffprobe failed: ${result.stderr}');
        return basic;
      }

      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      final format = json['format'] as Map<String, dynamic>?;
      final streams = json['streams'] as List<dynamic>?;

      double? durationSeconds;
      int? overallBitrate;
      String? fmtName;

      if (format != null) {
        fmtName = format['format_name'] as String?;
        if (format['duration'] != null) {
          durationSeconds = double.tryParse(format['duration'].toString());
        }
        if (format['bit_rate'] != null) {
          overallBitrate = int.tryParse(format['bit_rate'].toString());
        }
      }

      String? videoCodec;
      String? audioCodec;
      int? width;
      int? height;
      int? videoBitrate;
      int? audioBitrate;

      if (streams != null) {
        for (final s in streams) {
          final stream = s as Map<String, dynamic>;
          final type = stream['codec_type'] as String?;

          if (type == 'video') {
            videoCodec = stream['codec_name'] as String?;
            width = stream['width'] as int?;
            height = stream['height'] as int?;
            if (stream['bit_rate'] != null) {
              videoBitrate = int.tryParse(stream['bit_rate'].toString());
            }
          } else if (type == 'audio') {
            audioCodec = stream['codec_name'] as String?;
            if (stream['bit_rate'] != null) {
              audioBitrate = int.tryParse(stream['bit_rate'].toString());
            }
          }
        }
      }

      return MediaFile(
        path: basic.path,
        name: basic.name,
        sizeBytes: basic.sizeBytes,
        format: fmtName ?? basic.format,
        videoCodec: videoCodec,
        audioCodec: audioCodec,
        width: width,
        height: height,
        durationSeconds: durationSeconds,
        videoBitrate: videoBitrate ?? overallBitrate,
        audioBitrate: audioBitrate,
      );
    } catch (e, s) {
      debugPrint('ffprobe error: $e\n$s');
      return basic;
    }
  }
}
