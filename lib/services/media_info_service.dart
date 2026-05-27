import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';

import '../models/media_file.dart';

class MediaInfoService {
  Future<MediaFile> getMediaInfo(String path) async {
    final session = await FFprobeKit.getMediaInformationAsync(path);
    final info = session.getMediaInformation();

    final basic = await MediaFile.fromPath(path);

    if (info == null) return basic;

    final format = info.format ?? basic.format;

    double? durationSeconds;
    if (info.duration != null) {
      durationSeconds = double.tryParse(info.duration!);
    }

    int? overallBitrate;
    if (info.bitrate != null) {
      overallBitrate = int.tryParse(info.bitrate!);
    }

    String? videoCodec;
    String? audioCodec;
    int? width;
    int? height;
    int? videoBitrate;
    int? audioBitrate;

    for (final stream in info.streams) {
      if (stream.type == 'video') {
        videoCodec = stream.codec;
        width = stream.width;
        height = stream.height;
        if (stream.bitrate != null) {
          videoBitrate = int.tryParse(stream.bitrate!);
        }
      } else if (stream.type == 'audio') {
        audioCodec = stream.codec;
        if (stream.bitrate != null) {
          audioBitrate = int.tryParse(stream.bitrate!);
        }
      }
    }

    return MediaFile(
      path: basic.path,
      name: basic.name,
      sizeBytes: basic.sizeBytes,
      format: format,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      videoBitrate: videoBitrate ?? overallBitrate,
      audioBitrate: audioBitrate,
    );
  }
}
