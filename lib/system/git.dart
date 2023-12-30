import 'package:easy_app/utils/pair.dart';
import 'package:flutter/services.dart';

Pair<String, String>? _gitInfo;

/// Returns a pair of branch and commit id.
Future<Pair<String, String>> getGitInfo() async {
  if (_gitInfo == null) {
    final headBranch = await rootBundle.loadString(".git/HEAD");
    final branch = headBranch.split('/').last.replaceAll("\n", "");

    final headCommit = await rootBundle.loadString(".git/refs/heads/$branch");
    final commitId = headCommit.replaceAll("\n", "");

    _gitInfo = Pair(branch, commitId);
  }

  return _gitInfo!;
}
