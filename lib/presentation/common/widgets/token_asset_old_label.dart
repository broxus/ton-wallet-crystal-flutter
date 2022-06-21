import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../theme.dart';

class TokenAssetOldLabel extends StatelessWidget {
  const TokenAssetOldLabel({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: CrystalColor.error,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        child: Text(
          AppLocalizations.of(context)!.old,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );
}
