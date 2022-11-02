import 'package:auto_size_text/auto_size_text.dart';
import 'package:ever_wallet/application/bloc/common/account_overall_balance_stream.dart';
import 'package:ever_wallet/application/common/async_value.dart';
import 'package:ever_wallet/application/common/async_value_stream_provider.dart';
import 'package:ever_wallet/application/common/extensions.dart';
import 'package:ever_wallet/application/common/general/button/menu_dropdown.dart';
import 'package:ever_wallet/application/common/general/button/push_state_scale_widget.dart';
import 'package:ever_wallet/application/common/general/default_appbar.dart';
import 'package:ever_wallet/application/common/general/default_list_tile.dart';
import 'package:ever_wallet/application/common/general/flushbar.dart';
import 'package:ever_wallet/application/main/profile/manage_seed/manage_seed_actions/rename_account_sheet.dart';
import 'package:ever_wallet/application/main/profile/manage_seed/manage_seed_actions/show_account_delete_sheet.dart';
import 'package:ever_wallet/application/util/colors.dart';
import 'package:ever_wallet/application/util/extensions/context_extensions.dart';
import 'package:ever_wallet/application/util/styles.dart';
import 'package:ever_wallet/application/util/theme_styles.dart';
import 'package:ever_wallet/data/repositories/accounts_repository.dart';
import 'package:ever_wallet/data/repositories/token_currencies_repository.dart';
import 'package:ever_wallet/data/repositories/token_wallets_repository.dart';
import 'package:ever_wallet/data/repositories/ton_wallets_repository.dart';
import 'package:ever_wallet/data/repositories/transport_repository.dart';
import 'package:ever_wallet/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AccountDetailRoute extends MaterialPageRoute<void> {
  AccountDetailRoute(AssetsList account, bool isExternal, String linkedPublicKey)
      : super(
          builder: (_) => AccountDetailScreen(
            account: account,
            isExternal: isExternal,
            linkedPublicKey: linkedPublicKey,
          ),
        );
}

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({
    required this.account,
    required this.isExternal,
    required this.linkedPublicKey,
    super.key,
  });

  final AssetsList account;
  final bool isExternal;
  final String linkedPublicKey;

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  AssetsList get account => widget.account;

  @override
  Widget build(BuildContext context) {
    final localization = context.localization;
    final themeStyle = context.themeStyle;

    return Scaffold(
      appBar: DefaultAppBar(backText: localization.key_word),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EWListTile(
            height: 87,
            leading: Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Assets.images.account.svg(width: 32, height: 32),
            ),
            subtitleWidget: Text(
              localization.account.toUpperCase(),
              style: themeStyle.styles.sectionCaption,
            ),
            titleWidget: Text(
              account.name,
              maxLines: 2,
              style: themeStyle.styles.header3Style,
            ),
            trailing: _accountDropDown(themeStyle, localization),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
              localization.public_key,
              style: StylesRes.medium14Caption.copyWith(color: ColorsRes.grey4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PushStateScaleWidget(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: account.address));
                showFlushbar(
                  context,
                  message: localization.public_key_copied(account.address.ellipseAddress()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorsRes.notWhite,
                  border: Border.all(color: ColorsRes.grey2),
                ),
                child: Row(
                  children: [
                    QrImage(
                      size: 100,
                      data: account.address,
                    ),
                    Expanded(
                      child: Text(
                        account.address,
                        style: StylesRes.regular16.copyWith(color: ColorsRes.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  localization.total_balance,
                  style: StylesRes.regular16.copyWith(color: ColorsRes.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AsyncValueStreamProvider<double>(
                    create: (context) => accountOverallBalanceStream(
                      context.read<AccountsRepository>(),
                      context.read<TransportRepository>(),
                      context.read<TonWalletsRepository>(),
                      context.read<TokenWalletsRepository>(),
                      context.read<TokenCurrenciesRepository>(),
                      account.address,
                    ),
                    builder: (context, child) {
                      final balanceUsdt = context.watch<AsyncValue<double>>().maybeWhen(
                            ready: (value) => value,
                            orElse: () => null,
                          );

                      return balanceUsdt != null
                          ? balance(
                              balanceUsdt
                                  .truncateToDecimalPlaces(4)
                                  .toStringAsFixed(4)
                                  .removeZeroes()
                                  .formatValue(),
                            )
                          : balance('0');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      localization.linked_keys,
                      style: StylesRes.medium14Caption.copyWith(color: ColorsRes.grey4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountDropDown(
    ThemeStyle themeStyle,
    AppLocalizations localization,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ColorsRes.darkBlue.withOpacity(0.2)),
      ),
      child: MenuDropdown(
        buttonDecoration: const BoxDecoration(),
        items: [
          MenuDropdownData(
            title: localization.rename,
            onTap: () => showRenameAccountSheet(context: context, address: account.address),
          ),
          MenuDropdownData(
            title: localization.delete_word,
            onTap: () => showAccountDeleteSheet(
              context: context,
              account: account,
              isExternal: widget.isExternal,
              linkedPublicKey: widget.linkedPublicKey,
            ),
            textStyle: StylesRes.basicText.copyWith(color: ColorsRes.redLight),
          ),
        ],
      ),
    );
  }

  Widget balance(String balance) {
    final parts = balance.split('.');

    return AutoSizeText.rich(
      TextSpan(
        text: '\$${parts.first}',
        style: StylesRes.basicText.copyWith(color: ColorsRes.black),
        children: parts.length != 1
            ? [
                TextSpan(
                  text: '.${parts.last}',
                  style: StylesRes.basicText.copyWith(color: ColorsRes.black),
                )
              ]
            : null,
      ),
      maxLines: 1,
      minFontSize: 10,
      textAlign: TextAlign.right,
    );
  }
}
