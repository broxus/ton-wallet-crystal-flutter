import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../../../domain/blocs/account/account_info_bloc.dart';
import '../../../../../../../../domain/blocs/ton_wallet/ton_wallet_info_bloc.dart';
import '../../../../../../../../injection.dart';
import '../../../../../domain/models/account.dart';
import '../../../../design/design.dart';
import '../../../../design/widgets/wallet_card_selectable_field.dart';
import 'more_button.dart';

class WalletCard extends StatefulWidget {
  final String address;
  final bool isExternal;
  final String? publicKey;

  const WalletCard({
    Key? key,
    required this.address,
    this.isExternal = false,
    this.publicKey,
  }) : super(key: key);

  @override
  _WalletCardState createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  final tonWalletInfoBloc = getIt.get<TonWalletInfoBloc>();
  late final AccountInfoBloc accountInfoBloc;

  @override
  void initState() {
    super.initState();
    tonWalletInfoBloc.add(TonWalletInfoEvent.load(widget.address));

    accountInfoBloc = getIt.get<AccountInfoBloc>();
    accountInfoBloc.add(
      AccountInfoEvent.load(
        address: widget.address,
        isExternal: widget.isExternal,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      tonWalletInfoBloc.add(TonWalletInfoEvent.load(widget.address));
      accountInfoBloc.add(
        AccountInfoEvent.load(
          address: widget.address,
          isExternal: widget.isExternal,
        ),
      );
    }
  }

  @override
  void dispose() {
    tonWalletInfoBloc.close();
    accountInfoBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedAppearance(
        child: Stack(
          children: [
            Container(
              height: 200,
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  stops: [0, 0.45],
                  colors: [
                    Color(0xFFA6AEBD),
                    CrystalColor.background,
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(1),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: const Alignment(-5, 2),
                    end: Alignment.topRight,
                    stops: const [0, 0.75],
                    colors: [
                      Colors.white.withOpacity(0.1),
                      CrystalColor.background,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 17,
                      child: info(),
                    ),
                    Expanded(flex: 6, child: pattern()),
                  ],
                ),
              ),
            ),
            BlocBuilder<TonWalletInfoBloc, TonWalletInfo?>(
              bloc: tonWalletInfoBloc,
              builder: (context, state) => state != null
                  ? Positioned(
                      top: 8,
                      right: 8,
                      child: MoreButton(
                        address: state.address,
                        isExternal: widget.isExternal,
                        publicKey: widget.publicKey,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );

  Widget pattern() => ColoredBox(
        color: const Color(0xFFCDF8E4),
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC4C5EB), Color(0xFFBF70E6)],
          ).createShader(rect),
          blendMode: BlendMode.srcATop,
          child: Image.asset(
            Assets.images.accountCardPattern.path,
            color: Colors.white,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget info() => Padding(
        padding: const EdgeInsets.only(top: 23, left: 23, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<AccountInfoBloc, Account?>(
              bloc: accountInfoBloc,
              builder: (context, state) => state != null
                  ? AutoSizeText(
                      state.when(
                        internal: (assetsList) => assetsList.name,
                        external: (assetsList) => assetsList.name,
                      ),
                      maxLines: 1,
                      maxFontSize: 16,
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 0.75,
                        color: CrystalColor.fontLight,
                      ),
                    )
                  : const SizedBox(),
            ),
            const CrystalDivider(height: 8),
            BlocBuilder<TonWalletInfoBloc, TonWalletInfo?>(
              bloc: tonWalletInfoBloc,
              builder: (context, state) => state != null
                  ? namedField(
                      name: LocaleKeys.fields_public_key.tr(),
                      value: state.publicKey,
                      ellipsedValue: state.publicKey.ellipsePublicKey(),
                    )
                  : namedField(
                      name: LocaleKeys.fields_public_key.tr(),
                    ),
            ),
            BlocBuilder<TonWalletInfoBloc, TonWalletInfo?>(
              bloc: tonWalletInfoBloc,
              builder: (context, state) => state != null
                  ? namedField(
                      name: LocaleKeys.fields_address.tr(),
                      value: state.address,
                      ellipsedValue: state.address.ellipseAddress(),
                    )
                  : namedField(
                      name: LocaleKeys.fields_address.tr(),
                    ),
            ),
            BlocBuilder<TonWalletInfoBloc, TonWalletInfo?>(
              bloc: tonWalletInfoBloc,
              builder: (context, state) => state != null
                  ? namedField(
                      name: LocaleKeys.fields_type.tr(),
                      value: state.walletType.describe(),
                      isSelectable: false,
                    )
                  : namedField(
                      name: LocaleKeys.fields_type.tr(),
                      isSelectable: false,
                    ),
            ),
            const Spacer(),
            if (widget.isExternal) externalAccountLabel(),
            const Spacer(flex: 2),
            BlocBuilder<TonWalletInfoBloc, TonWalletInfo?>(
              bloc: tonWalletInfoBloc,
              builder: (context, state) => state != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: balance(state.contractState.balance),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );

  Widget externalAccountLabel() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.images.iconMultisig.svg(),
          const SizedBox(width: 8),
          const Text(
            'External account',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );

  Widget namedField({
    required String name,
    String? value,
    String? ellipsedValue,
    bool isSelectable = true,
    bool disabled = false,
  }) =>
      Row(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              letterSpacing: 0.75,
              color: CrystalColor.secondary,
            ),
          ),
          const CrystalDivider(width: 8),
          Flexible(
            child: value == null && ellipsedValue == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: shimmer(),
                  )
                : isSelectable
                    ? WalletCardSelectableField(
                        value: value!,
                        text: ellipsedValue!,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          value!,
                          maxLines: 1,
                          style: const TextStyle(
                            letterSpacing: 0.75,
                            color: CrystalColor.secondary,
                          ),
                        ),
                      ),
          ),
        ],
      );

  Widget balance(String balance) {
    final formattedString = balance.toTokens().floorValue().removeZeroes().formatValue();

    return AutoSizeText.rich(
      TextSpan(
        text: formattedString.contains('.')
            ? formattedString.substring(0, formattedString.indexOf('.'))
            : formattedString,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          letterSpacing: 0.75,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: formattedString.contains('.')
                ? "${formattedString.substring(formattedString.indexOf('.'), formattedString.length)} TON"
                : ' TON',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 0.75,
              fontWeight: FontWeight.normal,
            ),
          )
        ],
      ),
      maxLines: 1,
      minFontSize: 10,
    );
  }

  Widget shimmer({
    double height = 16,
    double width = 80,
  }) =>
      Container(
        constraints: BoxConstraints(maxHeight: height, maxWidth: width),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Shimmer.fromColors(
          baseColor: CrystalColor.shimmerBackground,
          highlightColor: CrystalColor.shimmerHighlight,
          child: Container(color: Colors.white),
        ),
      );
}
