class Result<T> {
  Result({this.data, this.status = ResultStatus.successful, this.reason}) {
    assert((status == ResultStatus.failed && reason != null) ||
        status != ResultStatus.failed);
  }
  final ResultStatus status;
  final T? data;
  final ResultFailedReason? reason;

  T get() {
    if (status != ResultStatus.successful) throw ResultNotFailedException();
    return data!;
  }

  ResultFailedReason getReason() {
    if (status != ResultStatus.failed) throw ResultNotFailedException();
    return reason!;
  }

  factory Result.successful(T data) {
    return Result<T>(data: data, status: ResultStatus.successful);
  }

  factory Result.failed(ResultFailedReason reason) {
    return Result<T>(reason: reason, status: ResultStatus.failed);
  }
}

enum ResultStatus { successful, failed }

class ResultNotSuccessfulException implements Exception {
  ResultNotSuccessfulException();
}

class ResultNotFailedException implements Exception {
  ResultNotFailedException();
}

class ResultFailedReason {
  ResultFailedReason({
    required this.cause,
    required this.title,
    required this.description,
  });
  final Exception cause;
  final String title;
  final String description;
}
