import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../../../../../logger.dart';
import 'models/network_changed_event.dart';

Future<void> networkChangedHandler({
  required InAppWebViewController controller,
  required NetworkChangedEvent event,
}) async {
  try {
    logger.d('NetworkChangedEvent', event);

    final jsonOutput = jsonEncode(event.toJson());

    await controller.evaluateJavascript(source: "window.__dartNotifications.networkChanged('$jsonOutput')");
  } catch (err, st) {
    logger.e(err, err, st);
    rethrow;
  }
}