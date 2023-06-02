import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:uuid/uuid.dart';

final Map<String, void Function(Response)> _registered = {};

void _requestListener(data) async {
  if (data["isFromOverlay"] == isOverlay) return; // just in case
  print("catch request on overlay: $isOverlay, $data");
  if (data["data"] != null) {
    final request = _registered[data["id"]];
    if (request != null) {
      final isListening = data["isListenDataResponse"] == true;
      if (!isListening) _registered.remove(data["id"]);
      final response = isListening
          ? ListenDataResponse.fromJson(data)
          : DataGetResponse.fromJson(data);
      request.call(response);
    }
  } else if (data["type"] != null) {
    final request = DataGetRequest.fromJson(data);
    final dynamic responseData;
    switch (request.type) {
      case RequestDataType.settings:
        responseData = SettingsData.settings.data;
        break;
      default:
        throw UnimplementedError();
    }

    OverlayUtils.sendData(
      DataGetResponse(
          data: responseData, id: request.id, isFromOverlay: isOverlay),
    );
  } else if (data["action"] != null) {
    final request = ActionRequest.fromJson(data);
    final Future future;
    switch (request.action) {
      case RequestActionType.addSong:
        future = HomeScreenMusicManager.addSong(
          key: request.args[0],
          youtubeId: request.args[1],
          musicData: request.args[2],
          mediaUrl: request.args[3],
        );
        break;
      case RequestActionType.play:
        future = musicManager.play();
        break;
      case RequestActionType.pause:
        future = musicManager.pause();
        break;
      default:
        throw UnimplementedError();
    }

    final result = await future;

    OverlayUtils.sendData(
      ActionCompletedResponse(
          result: result, id: request.id, isFromOverlay: isOverlay),
    );
  } else if (data["listenDataType"] != null) {
    final request = ListenDataRequest.fromJson(data);

    switch (request.listenDataType) {
      case ListenDataType.playingState:
        musicManager.playingStateNotifier.addListener(() {
          final playingState = musicManager.playingStateNotifier.value;
          OverlayUtils.sendData(
            ListenDataResponse(
              data: playingState.name,
              id: request.id,
              isFromOverlay: isOverlay,
            ),
          );
        });
        break;
      default:
        throw UnimplementedError();
    }
  }
}

class OverlayUtils {
  static String portName = "asterfox_main";

  static void init() {
    print("initialized overlay utils on overlay: $isOverlay");
    if (isOverlay) {
      FlutterOverlayWindow.overlayListener.listen(_requestListener);
    } else {
      final receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(receivePort.sendPort, portName);
      receivePort.listen(_requestListener);
    }
  }

  static Future<dynamic> requestData(RequestDataType type) async {
    final requestId = const Uuid().v4();
    final completer = Completer();
    _registered[requestId] = (Response response) {
      response as DataGetResponse;
      completer.complete(response.data);
    };
    sendData(
      DataGetRequest(type: type, id: requestId, isFromOverlay: isOverlay),
    );

    return completer.future;
  }

  static Future requestAction(RequestActionType action, [List<dynamic>? args]) {
    final requestId = const Uuid().v4();
    final completer = Completer();
    _registered[requestId] = (Response response) {
      response as ActionCompletedResponse;
      completer.complete(response.result);
    };
    sendData(
      ActionRequest(
        action: action,
        args: args ?? [],
        id: requestId,
        isFromOverlay: isOverlay,
      ),
    );

    return completer.future;
  }

  static void listenData({
    required ListenDataType type,
    required Function(ListenDataResponse) callback,
  }) {
    final requestId = const Uuid().v4();
    _registered[requestId] = (Response response) {
      callback(response as ListenDataResponse);
    };

    sendData(
      ListenDataRequest(
        listenDataType: type,
        id: requestId,
        isFromOverlay: isOverlay,
      ),
    );
  }

  static SendPort? mainServer;
  static void sendData(DataSharing data) {
    if (isOverlay) {
      mainServer ??= IsolateNameServer.lookupPortByName(portName);
      mainServer?.send(data.toJson());
    } else {
      FlutterOverlayWindow.shareData(data.toJson());
    }
  }
}

abstract class DataSharing {
  DataSharing({required this.id, required this.isFromOverlay});
  final String id;
  final bool isFromOverlay;

  Map<String, dynamic> toJson();
}

abstract class Response extends DataSharing {
  Response({required super.id, required super.isFromOverlay});
}

abstract class Request extends DataSharing {
  Request({required super.id, required super.isFromOverlay});
}

class DataGetRequest extends Request {
  DataGetRequest(
      {required this.type, required super.id, required super.isFromOverlay});
  final RequestDataType type;

  factory DataGetRequest.fromJson(Map<String, dynamic> json) {
    return DataGetRequest(
      type: RequestDataType.values
          .firstWhere((type) => type.name == json["type"]),
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

class DataGetResponse extends Response {
  DataGetResponse(
      {required this.data, required super.id, required super.isFromOverlay});
  final dynamic data;

  factory DataGetResponse.fromJson(Map<String, dynamic> json) {
    return DataGetResponse(
      data: json["data"],
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "data": data,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

class ActionRequest extends Request {
  ActionRequest(
      {required this.action,
      required this.args,
      required super.id,
      required super.isFromOverlay});
  final RequestActionType action;
  final List<dynamic> args;

  factory ActionRequest.fromJson(Map<String, dynamic> json) {
    return ActionRequest(
      action: RequestActionType.values
          .firstWhere((action) => action.name == json["action"]),
      args: json["args"],
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "action": action.name,
      "args": args,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

class ActionCompletedResponse extends Response {
  ActionCompletedResponse(
      {this.result, required super.id, required super.isFromOverlay});
  final dynamic result;

  factory ActionCompletedResponse.fromJson(Map<String, dynamic> json) {
    return ActionCompletedResponse(
      result: json["result"],
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "result": result,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

class ListenDataRequest extends Request {
  ListenDataRequest({
    required this.listenDataType,
    required super.id,
    required super.isFromOverlay,
  });
  final ListenDataType listenDataType;

  factory ListenDataRequest.fromJson(Map<String, dynamic> json) {
    return ListenDataRequest(
      listenDataType: ListenDataType.values
          .firstWhere((type) => type.name == json["listenDataType"]),
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "listenDataType": listenDataType.name,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

class ListenDataResponse extends Response {
  ListenDataResponse({
    required this.data,
    required super.id,
    required super.isFromOverlay,
  });
  final dynamic data;

  factory ListenDataResponse.fromJson(Map<String, dynamic> json) {
    if (json["isListenDataResponse"] != true) {
      throw Exception("Cannot parse the json in unknown format.");
    }
    return ListenDataResponse(
      data: json["data"],
      id: json["id"],
      isFromOverlay: json["isFromOverlay"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "data": data,
      "id": id,
      "isFromOverlay": isFromOverlay,
      "isListenDataResponse": true,
    };
  }
}

enum RequestDataType { settings }

enum RequestActionType { addSong, play, pause }

enum ListenDataType { playingState }
