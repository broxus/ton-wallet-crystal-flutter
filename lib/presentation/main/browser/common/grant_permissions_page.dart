import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../../../data/models/account_interaction.dart';
import '../../../../data/models/permission.dart';
import '../../../../data/models/permissions.dart';
import '../../../../data/models/wallet_contract_type.dart';
import '../../../common/widgets/custom_back_button.dart';
import '../../../common/widgets/custom_elevated_button.dart';
import '../../../common/widgets/sectioned_card.dart';
import '../../../common/widgets/sectioned_card_section.dart';

class GrantPermissionsPage extends StatefulWidget {
  final BuildContext modalContext;
  final String origin;
  final AssetsList account;
  final List<Permission> permissions;
  final void Function(Permissions permissions) onSubmit;

  const GrantPermissionsPage({
    Key? key,
    required this.modalContext,
    required this.origin,
    required this.account,
    required this.permissions,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _GrantPermissionsPageState createState() => _GrantPermissionsPageState();
}

class _GrantPermissionsPageState extends State<GrantPermissionsPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            AppLocalizations.of(context)!.grant_permissions,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: body(),
      );

  Widget body() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: card(),
                ),
              ),
              const SizedBox(height: 16),
              submitButton(),
            ],
          ),
        ),
      );

  Widget card() => SectionedCard(
        sections: [
          origin(),
          permissions(),
          address(),
          publicKey(),
        ],
      );

  Widget origin() => SectionedCardSection(
        title: AppLocalizations.of(context)!.origin,
        subtitle: widget.origin,
        isSelectable: true,
      );

  Widget permissions() => SectionedCardSection(
        title: AppLocalizations.of(context)!.requested_permissions,
        subtitle: widget.permissions.map((e) => describeEnum(e).capitalize).join(', '),
        isSelectable: true,
      );

  Widget address() => SectionedCardSection(
        title: AppLocalizations.of(context)!.account_address,
        subtitle: widget.account.address,
        isSelectable: true,
      );

  Widget publicKey() => SectionedCardSection(
        title: AppLocalizations.of(context)!.account_public_key,
        subtitle: widget.account.publicKey,
        isSelectable: true,
      );

  Widget submitButton() => CustomElevatedButton(
        onPressed: () => onSubmitPressed(),
        text: AppLocalizations.of(context)!.allow,
      );

  void onSubmitPressed() {
    var permissions = const Permissions();

    for (final permission in widget.permissions) {
      switch (permission) {
        case Permission.basic:
          permissions = permissions.copyWith(basic: true);
          break;
        case Permission.accountInteraction:
          permissions = permissions.copyWith(
            accountInteraction: AccountInteraction(
              address: widget.account.address,
              publicKey: widget.account.publicKey,
              contractType: widget.account.tonWallet.contract.toWalletType(),
            ),
          );
          break;
      }
    }

    widget.onSubmit(permissions);
  }
}

extension on WalletType {
  WalletContractType toWalletType() => when(
        multisig: (multisigType) {
          switch (multisigType) {
            case MultisigType.safeMultisigWallet:
              return WalletContractType.safeMultisigWallet;
            case MultisigType.safeMultisigWallet24h:
              return WalletContractType.safeMultisigWallet24h;
            case MultisigType.setcodeMultisigWallet:
              return WalletContractType.setcodeMultisigWallet;
            case MultisigType.setcodeMultisigWallet24h:
              return WalletContractType.setcodeMultisigWallet24h;
            case MultisigType.bridgeMultisigWallet:
              return WalletContractType.bridgeMultisigWallet;
            case MultisigType.surfWallet:
              return WalletContractType.surfWallet;
          }
        },
        walletV3: () => WalletContractType.walletV3,
        highloadWalletV2: () => WalletContractType.highloadWalletV2,
      );
}
