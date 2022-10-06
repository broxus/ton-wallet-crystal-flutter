import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../../../../providers/common/network_type_provider.dart';
import '../../../../common/constants.dart';
import '../../../../common/extensions.dart';
import '../../../../common/widgets/ton_asset_icon.dart';
import '../../modals/ton_wallet_multisig_transaction_info/show_ton_wallet_multisig_transaction_info.dart';
import 'widgets/address_title.dart';
import 'widgets/date_title.dart';
import 'widgets/fees_title.dart';
import 'widgets/icon_forward.dart';
import 'widgets/value_title.dart';

class TonWalletMultisigTransactionHolder extends StatelessWidget {
  final TonWalletTransactionWithData transactionWithData;
  final String creator;
  final List<String> confirmations;
  final String walletAddress;
  final List<String> custodians;

  const TonWalletMultisigTransactionHolder({
    Key? key,
    required this.transactionWithData,
    required this.creator,
    required this.confirmations,
    required this.walletAddress,
    required this.custodians,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final msgSender = transactionWithData.transaction.inMessage.src;

    final dataSender = transactionWithData.data?.maybeWhen(
      walletInteraction: (info) => info.knownPayload?.maybeWhen(
        tokenSwapBack: (tokenSwapBack) => tokenSwapBack.callbackAddress,
        orElse: () => null,
      ),
      orElse: () => null,
    );

    final sender = dataSender ?? msgSender;

    final msgRecipient = transactionWithData.transaction.outMessages.firstOrNull?.dst;

    final dataRecipient = transactionWithData.data?.maybeWhen(
      walletInteraction: (info) =>
          info.knownPayload?.maybeWhen(
            tokenOutgoingTransfer: (tokenOutgoingTransfer) => tokenOutgoingTransfer.to.address,
            orElse: () => null,
          ) ??
          info.method.maybeWhen(
            multisig: (multisigTransaction) => multisigTransaction.maybeWhen(
              send: (multisigSendTransaction) => multisigSendTransaction.dest,
              submit: (multisigSubmitTransaction) => multisigSubmitTransaction.dest,
              orElse: () => null,
            ),
            orElse: () => null,
          ) ??
          info.recipient,
      orElse: () => null,
    );

    final recipient = dataRecipient ?? msgRecipient;

    final isOutgoing = recipient != null;

    final msgValue = (isOutgoing
            ? transactionWithData.transaction.outMessages.firstOrNull?.value
            : transactionWithData.transaction.inMessage.value) ??
        transactionWithData.transaction.inMessage.value;

    final dataValue = transactionWithData.data?.maybeWhen(
      dePoolOnRoundComplete: (notification) => notification.reward,
      walletInteraction: (info) => info.method.maybeWhen(
        multisig: (multisigTransaction) => multisigTransaction.maybeWhen(
          send: (multisigSendTransaction) => multisigSendTransaction.value,
          submit: (multisigSubmitTransaction) => multisigSubmitTransaction.value,
          orElse: () => null,
        ),
        orElse: () => null,
      ),
      orElse: () => null,
    );

    final value = dataValue ?? msgValue;

    final address = (isOutgoing ? recipient : sender) ?? walletAddress;

    final date = transactionWithData.transaction.createdAt.toDateTime();

    final fees = transactionWithData.transaction.totalFees;

    return InkWell(
      onTap: () => showTonWalletMultisigTransactionInfo(
        context: context,
        transactionWithData: transactionWithData,
        creator: creator,
        confirmations: confirmations,
        custodians: custodians,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const TonAssetIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final ticker = ref.watch(networkTypeProvider).asData?.value == 'Ever'
                                ? kEverTicker
                                : kVenomTicker;

                            return ValueTitle(
                              value: value.toTokens().removeZeroes().formatValue(),
                              currency: ticker,
                              isOutgoing: isOutgoing,
                            );
                          },
                        ),
                      ),
                      const IconForward(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FeesTitle(fees: fees.toTokens().removeZeroes().formatValue()),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: AddressTitle(address: address),
                      ),
                      DateTitle(date: date),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
