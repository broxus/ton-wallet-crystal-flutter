import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:tuple/tuple.dart';

import '../../../../../domain/blocs/ton_wallet/ton_wallet_expired_transactions_provider.dart';
import '../../../../../domain/blocs/ton_wallet/ton_wallet_info_provider.dart';
import '../../../../../domain/blocs/ton_wallet/ton_wallet_multisig_pending_transactions_provider.dart';
import '../../../../../domain/blocs/ton_wallet/ton_wallet_sent_transactions_provider.dart';
import '../../../../../domain/blocs/ton_wallet/ton_wallet_transactions_state_provider.dart';
import '../../../../design/design.dart';
import '../../../../design/widgets/preload_transactions_listener.dart';
import 'transactions_holders/ton_wallet_expired_transaction_holder.dart';
import 'transactions_holders/ton_wallet_multisig_pending_transaction_holder.dart';
import 'transactions_holders/ton_wallet_sent_transaction_holder.dart';
import 'transactions_holders/ton_wallet_transaction_holder.dart';

class TonWalletTransactionsLayout extends StatefulWidget {
  final String address;
  final ScrollController controller;

  const TonWalletTransactionsLayout({
    Key? key,
    required this.address,
    required this.controller,
  }) : super(key: key);

  @override
  _TonWalletTransactionsLayoutState createState() => _TonWalletTransactionsLayoutState();
}

class _TonWalletTransactionsLayoutState extends State<TonWalletTransactionsLayout> {
  @override
  Widget build(BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final tonWalletInfo = ref.watch(tonWalletInfoProvider(widget.address)).asData?.value;
          final transactionsState = ref.watch(tonWalletTransactionsStateProvider(widget.address));
          final sentTransactionsState =
              ref.watch(tonWalletSentTransactionsProvider(widget.address)).asData?.value ?? [];
          final expiredTransactionsState =
              ref.watch(tonWalletExpiredTransactionsProvider(widget.address)).asData?.value ?? [];
          final multisigPendingTransactionsState =
              ref.watch(tonWalletMultisigPendingTransactionsProvider(widget.address)).asData?.value ?? [];

          return Stack(
            fit: StackFit.expand,
            children: [
              if (tonWalletInfo != null)
                list(
                  tonWalletInfo: tonWalletInfo,
                  transactionsState: transactionsState.item1,
                  sentTransactionsState: sentTransactionsState,
                  expiredTransactionsState: expiredTransactionsState,
                  multisigPendingTransactionsState: multisigPendingTransactionsState,
                ),
              loader(transactionsState.item2),
            ],
          );
        },
      );

  Widget list({
    required TonWalletInfo tonWalletInfo,
    required List<TonWalletTransactionWithData> transactionsState,
    required List<Tuple2<PendingTransaction, Transaction?>> sentTransactionsState,
    required List<PendingTransaction> expiredTransactionsState,
    required List<MultisigPendingTransaction> multisigPendingTransactionsState,
  }) {
    final accountPendingTransactions = transactionsState
        .where((e) => e.data != null)
        .toList()
        .where(
          (e) => e.data!.maybeWhen(
            walletInteraction: (info) => info.method.maybeWhen(
              multisig: (multisigTransaction) => multisigTransaction.maybeWhen(
                submit: (multisigSubmitTransaction) =>
                    multisigPendingTransactionsState.any((e) => e.id == multisigSubmitTransaction.transId),
                orElse: () => false,
              ),
              orElse: () => false,
            ),
            orElse: () => false,
          ),
        )
        .toList();

    final ordinary = transactionsState
        .where((e) => !accountPendingTransactions.any((el) => el == e))
        .map(
          (e) => Tuple2(
            e.transaction.createdAt,
            TonWalletTransactionHolder(
              transactionWithData: e,
              walletAddress: tonWalletInfo.address,
            ),
          ),
        )
        .toList();

    final sent = sentTransactionsState
        .map(
          (e) => Tuple2(
            e.item2?.createdAt ?? e.item1.expireAt,
            TonWalletSentTransactionHolder(
              pendingTransaction: e.item1,
              transaction: e.item2,
              walletAddress: tonWalletInfo.address,
            ),
          ),
        )
        .toList();

    final expired = expiredTransactionsState
        .map(
          (e) => Tuple2(
            e.expireAt,
            TonWalletExpiredTransactionHolder(
              pendingTransaction: e,
              walletAddress: tonWalletInfo.address,
            ),
          ),
        )
        .toList();

    final multisigPending = accountPendingTransactions
        .map(
          (e) => Tuple2(
            e.transaction.createdAt,
            TonWalletMultisigPendingTransactionHolder(
              transactionWithData: e,
              multisigPendingTransaction: multisigPendingTransactionsState.firstWhere(
                (el) =>
                    el.id ==
                    e.data?.maybeWhen(
                      walletInteraction: (info) => info.method.maybeWhen(
                        multisig: (multisigTransaction) => multisigTransaction.maybeWhen(
                          submit: (multisigSubmitTransaction) => multisigSubmitTransaction.transId,
                          orElse: () => null,
                        ),
                        orElse: () => null,
                      ),
                      orElse: () => null,
                    ),
              ),
              walletAddress: tonWalletInfo.address,
              walletType: tonWalletInfo.walletType,
              walletPublicKey: tonWalletInfo.publicKey,
              custodians: tonWalletInfo.custodians ?? [],
            ),
          ),
        )
        .toList();

    final sorted = [
      ...ordinary,
      ...sent,
      ...expired,
      ...multisigPending,
    ]..sort((a, b) => b.item1.compareTo(a.item1));

    final all = sorted.map((e) => e.item2).toList();

    return AnimatedSwitcher(
      duration: kThemeAnimationDuration,
      child: all.isNotEmpty
          ? Consumer(
              builder: (context, ref, child) => PreloadTransactionsListener(
                prevTransactionId: transactionsState.lastOrNull?.transaction.prevTransactionId,
                onLoad: () => ref.read(tonWalletTransactionsStateProvider(widget.address).notifier).preload(),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  controller: widget.controller,
                  itemBuilder: (context, index) => all[index],
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                  ),
                  itemCount: all.length,
                ),
              ),
            )
          : placeholder(LocaleKeys.wallet_history_modal_placeholder_transactions_empty.tr()),
    );
  }

  Widget loader(bool loading) => IgnorePointer(
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

  Widget placeholder(String text) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: CrystalColor.fontSecondaryDark,
            ),
          ),
        ),
      );
}
