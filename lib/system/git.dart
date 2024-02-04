import 'package:flutter/services.dart';

import '../utils/pair.dart';

Pair<String, String>? _gitInfo;

/// Returns a pair of branch and commit id.
Future<Pair<String, String>> getGitInfo() async {
  if (_gitInfo == null) {
    final headBranch = await rootBundle.loadString(".git/HEAD");
    final branch = headBranch.split('/').last.replaceAll("\n", "");

    late String commitId;
    try {
      final headCommit = await rootBundle.loadString(".git/refs/heads/$branch");
      commitId = headCommit.replaceAll("\n", "");
    } catch (e) {
      commitId = "Unknown";
    }

    _gitInfo = Pair(branch, commitId);
  }

  return _gitInfo!;
}
