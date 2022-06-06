import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../providers/account/current_account_provider.dart';
import '../../../common/theme.dart';
import 'all_assets_layout.dart';
import 'ton_wallet_transactions_layout.dart';

class WalletModalBody extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(int)? onTabSelected;

  const WalletModalBody({
    Key? key,
    required this.scrollController,
    this.onTabSelected,
  }) : super(key: key);

  @override
  _WalletModalBodyState createState() => _WalletModalBodyState();
}

class _WalletModalBodyState extends State<WalletModalBody> {
  @override
  Widget build(BuildContext context) {
    final tabs = [
      AppLocalizations.of(context)!.assets,
      AppLocalizations.of(context)!.transactions,
    ].map((e) => Text(e)).toList();

    return Material(
      color: Colors.white,
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: Platform.isIOS ? 19 : 6),
        child: DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: CrystalColor.divider,
                      ),
                    ),
                    TabBar(
                      tabs: tabs,
                      labelStyle: const TextStyle(fontSize: 16),
                      labelColor: CrystalColor.accent,
                      unselectedLabelColor: CrystalColor.fontSecondaryDark,
                      labelPadding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: widget.onTabSelected,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer(
                  builder: (context, ref, child) {
                    final currentAccount = ref.watch(currentAccountProvider);

                    return TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        if (currentAccount != null)
                          AllAssetsLayout(
                            address: currentAccount.address,
                            controller: widget.scrollController,
                          )
                        else
                          const SizedBox(),
                        if (currentAccount != null)
                          TonWalletTransactionsLayout(
                            address: currentAccount.address,
                            controller: widget.scrollController,
                          )
                        else
                          const SizedBox(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
