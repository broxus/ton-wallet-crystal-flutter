import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../../../../domain/models/transaction_type.dart';
import '../../../../../../../../../../domain/utils/explorer.dart';
import '../../../../../../../../../../domain/utils/transaction_data.dart';
import '../../../../../../../../../../domain/utils/transaction_time.dart';
import '../../../../../design/design.dart';
import '../../../../../design/widgets/crystal_bottom_sheet.dart';

class TonWalletTransactionObserver extends StatefulWidget {
  final String currency;
  final TransactionType transactionType;
  final Transaction transaction;
  final TransactionAdditionalInfo? data;
  final Widget? icon;
  final bool isOutgoing;
  final String? address;
  final String value;

  TonWalletTransactionObserver._({
    Key? key,
    required this.currency,
    required this.transactionType,
    required this.transaction,
    this.data,
    this.icon,
  })  : isOutgoing = transaction.outMessages.isNotEmpty,
        address = transaction.outMessages.isNotEmpty ? transaction.outMessages.first.dst : transaction.inMessage.src,
        value = transaction.outMessages.isNotEmpty ? transaction.outMessages.first.value : transaction.inMessage.value,
        super(key: key);

  static Future<void> open({
    required BuildContext context,
    required String currency,
    required TransactionType transactionType,
    required Transaction transaction,
    TransactionAdditionalInfo? data,
    required Widget? icon,
  }) =>
      showCrystalBottomSheet(
        context,
        expand: false,
        barrierColor: CrystalColor.modalBackground.withOpacity(0.7),
        title: LocaleKeys.transaction_observer_title.tr(),
        body: TonWalletTransactionObserver._(
          currency: currency,
          transactionType: transactionType,
          transaction: transaction,
          data: data,
          icon: icon,
        ),
      );

  @override
  _TonWalletTransactionObserverState createState() => _TonWalletTransactionObserverState();
}

class _TonWalletTransactionObserverState extends State<TonWalletTransactionObserver> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: FadingEdgeScrollView.fromSingleChildScrollView(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InformationField(
                        title: LocaleKeys.fields_date_time.tr(),
                        value: widget.transaction.createdAt.toDateTime().format(),
                      ),
                      const CrystalDivider(height: 16),
                      if (widget.address != null)
                        InformationField(
                          title: widget.isOutgoing ? LocaleKeys.fields_recipient.tr() : LocaleKeys.fields_sender.tr(),
                          value: widget.address!,
                        ),
                      const CrystalDivider(height: 16),
                      InformationField(
                        title: LocaleKeys.fields_hash_id.tr(),
                        value: widget.transaction.id.hash,
                      ),
                      const CrystalDivider(height: 16),
                      const Divider(height: 1, thickness: 1),
                      const CrystalDivider(height: 16),
                      InformationField(
                        title: LocaleKeys.fields_amount.tr(),
                        value: LocaleKeys.wallet_history_modal_holder_value.tr(
                          args: [
                            '${widget.isOutgoing ? '- ' : ''}${widget.value.toTokens().removeZeroes().formatValue()}',
                            widget.currency,
                          ],
                        ),
                      ),
                      const CrystalDivider(height: 16),
                      InformationField(
                        title: LocaleKeys.fields_blockchain_fee.tr(),
                        value: LocaleKeys.wallet_history_modal_holder_fee.tr(
                          args: [
                            widget.transaction.totalFees.toTokens().removeZeroes().formatValue(),
                            'TON',
                          ],
                        ),
                      ),
                      const CrystalDivider(height: 16),
                      if (widget.data?.toComment() != null && (widget.data?.toComment()?.isNotEmpty ?? false)) ...[
                        const Divider(height: 1, thickness: 1),
                        const CrystalDivider(height: 16),
                        InformationField(
                          title: LocaleKeys.fields_comment.tr(),
                          step: 8,
                          value: widget.data!.toComment()!,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const CrystalDivider(height: 8),
            CrystalButton(
              onTap: () => launch(getTransactionExplorerLink(widget.transaction.id.hash)),
              type: CrystalButtonType.outline,
              text: LocaleKeys.transaction_observer_open_explorer.tr(),
            ),
          ],
        ),
      );
}
