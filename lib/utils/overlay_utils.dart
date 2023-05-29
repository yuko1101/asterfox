import 'dart:async';

import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:uuid/uuid.dart';

final Map<String, void Function(Response)> _registered = {};

void _listener(data) async {
  if (data["isFromOverlay"] == isOverlay) return;
  if (data["data"] != null) {
    final request = _registered[data["id"]];
    if (request != null) {
      _registered.remove(data["id"]);
      request.call(DataGetResponse.fromJson(data));
    }
  } else if (data["type"] != null) {
    final request = DataGetRequest.fromJson(data);
    final dynamic responseData;
    switch (request.type) {
      case RequestDataType.settings:
        responseData = SettingsData.settings.data;
        break;
    }

    FlutterOverlayWindow.shareData(
      DataGetResponse(
              data: responseData, id: request.id, isFromOverlay: isOverlay)
          .toJson(),
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
    }

    final result = await future;

    FlutterOverlayWindow.shareData(
      ActionCompletedResponse(
              result: result, id: request.id, isFromOverlay: isOverlay)
          .toJson(),
    );
  }
}

class OverlayUtils {
  static void init() {
    FlutterOverlayWindow.overlayListener.listen(_listener);
  }

  static Future<dynamic> requestData(RequestDataType type) async {
    final requestId = const Uuid().v4();
    final completer = Completer();
    _registered[requestId] = (Response response) {
      response as DataGetResponse;
      completer.complete(response.data);
    };
    FlutterOverlayWindow.shareData(
      DataGetRequest(type: type, id: requestId, isFromOverlay: isOverlay)
          .toJson(),
    );

    return completer.future;
  }

  static Future requestAction(RequestActionType action, List<dynamic> args) {
    final requestId = const Uuid().v4();
    final completer = Completer();
    _registered[requestId] = (Response response) {
      response as ActionCompletedResponse;
      completer.complete(response.result);
    };
    FlutterOverlayWindow.shareData(
      ActionRequest(
              action: action,
              args: args,
              id: requestId,
              isFromOverlay: isOverlay)
          .toJson(),
    );

    return completer.future;
  }
}

class Response {
  Response({required this.id, required this.isFromOverlay});
  final String id;
  final bool isFromOverlay;
}

class Request {
  Request({required this.id, required this.isFromOverlay});
  final String id;
  final bool isFromOverlay;
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

  Map<String, dynamic> toJson() {
    return {
      "result": result,
      "id": id,
      "isFromOverlay": isFromOverlay,
    };
  }
}

enum RequestDataType { settings }

enum RequestActionType { addSong }
