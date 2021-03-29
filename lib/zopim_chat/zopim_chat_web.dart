import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class Zendesk2Web {
  Zendesk2Web._();
  static final Zendesk2Web instance = Zendesk2Web._();

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'zendesk2_web',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = Zendesk2Web.instance;
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case '':

      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'zendesk2 for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
