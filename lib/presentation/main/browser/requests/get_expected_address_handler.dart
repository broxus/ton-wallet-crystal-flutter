import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../../../../../../../logger.dart';
import '../../../../../data/repositories/permissions_repository.dart';
import '../../../../../injection.dart';
import '../../../../data/constants.dart';
import '../extensions.dart';
import 'models/get_expected_address_input.dart';
import 'models/get_expected_address_output.dart';

Future<Map<String, dynamic>> getExpectedAddressHandler({
  required InAppWebViewController controller,
  required List<dynamic> args,
}) async {
  try {
    logger.d('getExpectedAddress', args);

    final jsonInput = args.first as Map<String, dynamic>;
    final input = GetExpectedAddressInput.fromJson(jsonInput);

    final origin = await controller.getOrigin();

    final existingPermissions = getIt.get<PermissionsRepository>().permissions[origin];

    if (existingPermissions?.basic == null) throw Exception('Basic interaction not permitted');

    final result = getExpectedAddress(
      tvc: input.tvc,
      contractAbi: input.abi,
      workchainId: input.workchain ?? kDefaultWorkchain,
      publicKey: input.publicKey,
      initData: input.initParams,
    );

    final output = GetExpectedAddressOutput(
      address: result.item1,
      stateInit: result.item2,
    );

    final jsonOutput = output.toJson();

    return jsonOutput;
  } catch (err, st) {
    logger.e('getExpectedAddress', err, st);
    rethrow;
  }
}
