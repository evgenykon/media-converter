import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../models/conversion_job.dart';

class HistoryService {
  List<ConversionJob>? _cached;
  String? _filePath;

  Future<String> get _path async {
    if (_filePath != null) return _filePath!;
    final dir = await getApplicationSupportDirectory();
    _filePath = '${dir.path}/${AppConstants.historyFileName}';
    return _filePath!;
  }

  Future<List<ConversionJob>> load() async {
    if (_cached != null) return _cached!;
    try {
      final file = File(await _path);
      if (!await file.exists()) {
        _cached = [];
        return _cached!;
      }
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _cached = list
          .map((e) => ConversionJob.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cached!;
    } catch (_) {
      _cached = [];
      return _cached!;
    }
  }

  Future<void> save(List<ConversionJob> jobs) async {
    _cached = jobs;
    try {
      final file = File(await _path);
      await file.create(recursive: true);
      final content = jsonEncode(jobs.map((j) => j.toJson()).toList());
      await file.writeAsString(content);
    } catch (_) {}
  }
}
