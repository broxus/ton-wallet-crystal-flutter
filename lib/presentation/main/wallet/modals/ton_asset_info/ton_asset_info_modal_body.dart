import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../../../../../data/models/ton_wallet_info.dart';
import '../../../../../../providers/key/current_key_provider.dart';
import '../../../../../../providers/key/keys_provider.dart';
import '../../../../../../providers/ton_wallet/ton_wallet_expired_transactions_provider.dart';
import '../../../../../../providers/ton_wallet/ton_wallet_info_provider.dart';
import '../../../../../../providers/ton_wallet/ton_wallet_multisig_pending_transactions_provider.dart';
import '../../../../../../providers/ton_wallet/ton_wallet_pending_transactions_provider.dart';
import '../../../../../../providers/ton_wallet/ton_wallet_transactions_state_provider.dart';
import '../../../../../generated/assets.gen.dart';
import '../../../../../providers/common/network_type_provider.dart';
import '../../../../common/constants.dart';
import '../../../../common/extensions.dart';
import '../../../../common/theme.dart';
import '../../../../common/widgets/custom_close_button.dart';
import '../../../../common/widgets/preload_transactions_listener.dart';
import '../../../../common/widgets/ton_asset_icon.dart';
import '../../../../common/widgets/wallet_action_button.dart';
import '../../map_ton_wallet_transactions_to_widgets.dart';
import '../deploy_wallet_flow/start_deploy_wallet_flow.dart';
import '../receive_modal/show_receive_modal.dart';
import '../send_transaction_flow/start_send_transaction_flow.dart';

class TonAssetInfoModalBody extends StatefulWidget {
  final String address;

  const TonAssetInfoModalBody({
    Key? key,
    required this.address,
  }) : super(key: key);

  @override
  _TonAssetInfoModalBodyState createState() => _TonAssetInfoModalBodyState();
}

class _TonAssetInfoModalBodyState extends State<TonAssetInfoModalBody> {
  @override
  Widget build(BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final tonWalletInfo = ref.watch(tonWalletInfoProvider(widget.address)).asData?.value;

          return tonWalletInfo != null
              ? Material(
                  color: Colors.white,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header(tonWalletInfo: tonWalletInfo),
                        Expanded(
                          child: history(tonWalletInfo: tonWalletInfo),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox();
        },
      );

  Widget header({
    required TonWalletInfo tonWalletInfo,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        color: CrystalColor.accentBackground,
        child: Column(
          children: [
            info(tonWalletInfo.contractState.balance),
            const SizedBox(height: 24),
            actions(tonWalletInfo),
          ],
        ),
      );

  Widget info(String balance) => Row(
        children: [
          const TonAssetIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                balanceText(balance),
                const SizedBox(height: 4),
                nameText(),
              ],
            ),
          ),
          const CustomCloseButton(),
        ],
      );

  Widget balanceText(String balance) => Consumer(
        builder: (context, ref, child) {
          final ticker =
              ref.watch(networkTypeProvider).asData?.value == 'Ever' ? kEverTicker : kVenomTicker;

          return Text(
            '${balance.toTokens().removeZeroes().formatValue()} $ticker',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      );

  Widget nameText() => Consumer(
        builder: (context, ref, child) {
          final isEver = ref.watch(networkTypeProvider).asData?.value == 'Ever';

          return Text(
            isEver ? kEverNetworkName : kVenomNetworkName,
            style: const TextStyle(
              fontSize: 16,
            ),
          );
        },
      );

  Widget actions(TonWalletInfo tonWalletInfo) => Consumer(
        builder: (context, ref, child) {
          final keys = ref.watch(keysProvider).asData?.value ?? {};
          final currentKey = ref.watch(currentKeyProvider).asData?.value;

          final receiveButton = WalletActionButton(
            icon: Assets.images.iconReceive,
            title: AppLocalizations.of(context)!.receive,
            onPressed: () => showReceiveModal(
              context: context,
              address: widget.address,
            ),
          );

          WalletActionButton? actionButton;

          if (currentKey != null) {
            final requiresSeparateDeploy = tonWalletInfo.details.requiresSeparateDeploy;
            final isDeployed = tonWalletInfo.contractState.isDeployed;

            if (!requiresSeparateDeploy || isDeployed) {
              final keysList = [
                ...keys.keys,
                ...keys.values.whereNotNull().expand((e) => e),
              ];

              final custodians = tonWalletInfo.custodians ?? [];

              final localCustodians =
                  keysList.where((e) => custodians.any((el) => el == e.publicKey)).toList();

              final initiatorKey =
                  localCustodians.firstWhereOrNull((e) => e.publicKey == currentKey.publicKey);

              final listOfKeys = [
                if (initiatorKey != null) initiatorKey,
                ...localCustodians.where((e) => e.publicKey != initiatorKey?.publicKey),
              ];

              final publicKeys = listOfKeys.map((e) => e.publicKey).toList();

              actionButton = WalletActionButton(
                icon: Assets.images.iconSend,
                title: AppLocalizations.of(context)!.send,
                onPressed: publicKeys.isNotEmpty
                    ? () => startSendTransactionFlow(
                          context: context,
                          address: widget.address,
                          publicKeys: publicKeys,
                        )
                    : null,
              );
            } else {
              actionButton = WalletActionButton(
                icon: Assets.images.iconDeploy,
                title: AppLocalizations.of(context)!.deploy,
                onPressed: () => startDeployWalletFlow(
                  context: context,
                  address: widget.address,
                  publicKey: currentKey.publicKey,
                ),
              );
            }
          }

          return Row(
            children: [
              Expanded(
                child: receiveButton,
              ),
              if (actionButton != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: actionButton,
                ),
              ],
            ],
          );
        },
      );

  Widget history({
    required TonWalletInfo tonWalletInfo,
  }) =>
      Consumer(
        builder: (context, ref, child) {
          final transactionsState = ref.watch(tonWalletTransactionsStateProvider(widget.address));
          final pendingTransactionsState =
              ref.watch(tonWalletPendingTransactionsProvider(widget.address)).asData?.value ?? [];
          final expiredTransactionsState =
              ref.watch(tonWalletExpiredTransactionsProvider(widget.address)).asData?.value ?? [];
          final multisigPendingTransactionsState = ref
                  .watch(tonWalletMultisigPendingTransactionsProvider(widget.address))
                  .asData
                  ?.value ??
              [];

          return Column(
            children: [
              historyTitle(
                transactionsState: transactionsState.item1,
                pendingTransactionsState: pendingTransactionsState,
                expiredTransactionsState: expiredTransactionsState,
                multisigPendingTransactionsState: multisigPendingTransactionsState,
              ),
              const Divider(
                height: 1,
                thickness: 1,
              ),
              Flexible(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    list(
                      tonWalletInfo: tonWalletInfo,
                      transactionsState: transactionsState.item1,
                      pendingTransactionsState: pendingTransactionsState,
                      expiredTransactionsState: expiredTransactionsState,
                      multisigPendingTransactionsState: multisigPendingTransactionsState,
                    ),
                    loader(loading: transactionsState.item2),
                  ],
                ),
              ),
            ],
          );
        },
      );

  Widget historyTitle({
    required List<TonWalletTransactionWithData> transactionsState,
    required List<PendingTransaction> pendingTransactionsState,
    required List<PendingTransaction> expiredTransactionsState,
    required List<MultisigPendingTransaction> multisigPendingTransactionsState,
  }) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.history,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (transactionsState.isEmpty &&
                pendingTransactionsState.isEmpty &&
                expiredTransactionsState.isEmpty &&
                multisigPendingTransactionsState.isEmpty)
              Text(
                AppLocalizations.of(context)!.transactions_empty,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
          ],
        ),
      );

  Widget list({
    required TonWalletInfo tonWalletInfo,
    required List<TonWalletTransactionWithData> transactionsState,
    required List<PendingTransaction> pendingTransactionsState,
    required List<PendingTransaction> expiredTransactionsState,
    required List<MultisigPendingTransaction> multisigPendingTransactionsState,
  }) {
    final timeForConfirmation = Duration(seconds: tonWalletInfo.details.expirationTime);

    final all = mapTonWalletTransactionsToWidgets(
      timeForConfirmation: timeForConfirmation,
      tonWalletInfo: tonWalletInfo,
      transactions: transactionsState,
      pendingTransactions: pendingTransactionsState,
      expiredTransactions: expiredTransactionsState,
      multisigPendingTransactions: multisigPendingTransactionsState,
    );

    return RawScrollbar(
      thickness: 4,
      minThumbLength: 48,
      thumbColor: CrystalColor.secondary,
      radius: const Radius.circular(8),
      controller: ModalScrollController.of(context),
      child: Consumer(
        builder: (context, ref, child) => PreloadTransactionsListener(
          scrollController: ModalScrollController.of(context)!,
          onNotification: () => ref
              .read(
                tonWalletTransactionsStateProvider(widget.address).notifier,
              )
              .preload(transactionsState.lastOrNull?.transaction.prevTransactionId),
          child: ListView.separated(
            controller: ModalScrollController.of(context),
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) => all[index],
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
            ),
            itemCount: all.length,
          ),
        ),
      ),
    );
  }

  Widget loader({required bool loading}) => IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: loading
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black12,
                  child: Center(
                    child: PlatformCircularProgressIndicator(),
                  ),
                )
              : const SizedBox(),
        ),
      );
}
