import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../data/repositories/keys_repository.dart';
import '../../../../../../injection.dart';
import '../../../../../../providers/key/public_keys_labels_provider.dart';
import '../../../../common/widgets/unfocusing_gesture_detector.dart';

Future<void> showEditCustodianLabelDialog({
  required BuildContext context,
  required String publicKey,
}) =>
    showPlatformDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final publicKeysLabels = ref.watch(publicKeysLabelsProvider).asData?.value ?? {};

          final controller = TextEditingController(text: publicKeysLabels[publicKey]);

          return UnfocusingGestureDetector(
            child: PlatformAlertDialog(
              title: Text(AppLocalizations.of(context)!.custodian_label),
              content: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: PlatformTextField(
                  controller: controller,
                  autocorrect: false,
                  hintText: '${AppLocalizations.of(context)!.enter_name}...',
                ),
              ),
              actions: [
                PlatformDialogAction(
                  onPressed: () => context.router.pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                PlatformDialogAction(
                  onPressed: () async {
                    getIt.get<KeysRepository>().renameKey(
                          publicKey: publicKey,
                          name: controller.text,
                        );

                    Future.delayed(const Duration(seconds: 3), () {
                      controller.dispose();
                    });

                    context.router.pop();
                  },
                  cupertino: (_, __) => CupertinoDialogActionData(
                    isDefaultAction: true,
                  ),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        },
      ),
    );
