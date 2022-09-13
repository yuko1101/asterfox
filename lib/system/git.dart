import 'package:easy_app/utils/pair.dart';
import 'package:flutter/services.dart';

Pair<String, String>? _gitInfo;

/// Returns a pair of branch and commit id.
Future<Pair<String, String>> getGitInfo() async {
  if (_gitInfo == null) {
    final _head = await rootBundle.loadString('.git/HEAD');
    final _commitId = await rootBundle.loadString('.git/ORIG_HEAD');

    final branch = _head.split('/').last.replaceAll("\n", "");
    final commitId = _commitId.replaceAll("\n", "");

    _gitInfo = Pair(branch, commitId);
  }

  return _gitInfo!;
}
