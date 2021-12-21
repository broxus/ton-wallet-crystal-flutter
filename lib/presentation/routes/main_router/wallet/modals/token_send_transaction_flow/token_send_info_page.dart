import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../../../../../data/repositories/biometry_repository.dart';
import '../../../../../../domain/blocs/biometry/biometry_info_bloc.dart';
import '../../../../../../domain/blocs/token_wallet/token_wallet_estimate_fees_bloc.dart';
import '../../../../../../domain/blocs/token_wallet/token_wallet_info_bloc.dart';
import '../../../../../../domain/blocs/token_wallet/token_wallet_prepare_transfer_bloc.dart';
import '../../../../../../injection.dart';
import '../../../../../design/extension.dart';
import '../../../../../design/widgets/custom_back_button.dart';
import '../../../../../design/widgets/custom_elevated_button.dart';
import '../../../../../design/widgets/sectioned_card.dart';
import '../../../../../design/widgets/sectioned_card_section.dart';
import '../common/password_enter_page.dart';
import '../common/token_send_result_page.dart';

class TokenSendInfoPage extends StatefulWidget {
  final BuildContext modalContext;
  final String owner;
  final String rootTokenContract;
  final String publicKey;
  final String destination;
  final String amount;
  final bool notifyReceiver;
  final String? comment;

  const TokenSendInfoPage({
    Key? key,
    required this.modalContext,
    required this.owner,
    required this.rootTokenContract,
    required this.publicKey,
    required this.destination,
    required this.amount,
    required this.notifyReceiver,
    this.comment,
  }) : super(key: key);

  @override
  _NewSelectWalletTypePageState createState() => _NewSelectWalletTypePageState();
}

class _NewSelectWalletTypePageState extends State<TokenSendInfoPage> {
  final infoBloc = getIt.get<TokenWalletInfoBloc>();
  final prepareTransferBloc = getIt.get<TokenWalletPrepareTransferBloc>();
  final estimateFeesBloc = getIt.get<TokenWalletEstimateFeesBloc>();

  @override
  void initState() {
    super.initState();
    infoBloc.add(
      TokenWalletInfoEvent.load(
        owner: widget.owner,
        rootTokenContract: widget.rootTokenContract,
      ),
    );
    prepareTransferBloc.add(
      TokenWalletPrepareTransferEvent.prepareTransfer(
        owner: widget.owner,
        rootTokenContract: widget.rootTokenContract,
        publicKey: widget.publicKey,
        destination: widget.destination,
        amount: widget.amount,
        notifyReceiver: widget.notifyReceiver,
        payload: widget.comment,
      ),
    );
  }

  @override
  void dispose() {
    infoBloc.close();
    prepareTransferBloc.close();
    estimateFeesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<TokenWalletPrepareTransferBloc, TokenWalletPrepareTransferState>(
        bloc: prepareTransferBloc,
        listener: (context, state) => state.maybeWhen(
          success: (message) => estimateFeesBloc.add(
            TokenWalletEstimateFeesEvent.estimateFees(
              owner: widget.owner,
              rootTokenContract: widget.rootTokenContract,
              message: message,
              amount: widget.amount,
            ),
          ),
          orElse: () => null,
        ),
        child: scaffold(),
      );

  Widget scaffold() => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: const Text(
            'Confirm transaction',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: body(),
      );

  Widget body() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                controller: ModalScrollController.of(context),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    card(),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    submitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget card() => SectionedCard(
        sections: [
          recipient(),
          amount(),
          fee(),
          if (widget.comment != null) comment(),
          notifyReceiver(),
        ],
      );

  Widget recipient() => SectionedCardSection(
        title: 'Recipient',
        subtitle: widget.destination,
        isSelectable: true,
      );

  Widget amount() => BlocBuilder<TokenWalletInfoBloc, TokenWalletInfo?>(
        bloc: infoBloc,
        builder: (context, state) => SectionedCardSection(
          title: 'Amount',
          subtitle: state != null
              ? '${widget.amount.toTokens(state.symbol.decimals).removeZeroes()} ${state.symbol.name}'
              : null,
        ),
      );

  Widget fee() => BlocBuilder<TokenWalletPrepareTransferBloc, TokenWalletPrepareTransferState>(
        bloc: prepareTransferBloc,
        builder: (context, prepareTransferState) =>
            BlocBuilder<TokenWalletEstimateFeesBloc, TokenWalletEstimateFeesState>(
          bloc: estimateFeesBloc,
          builder: (context, estimateFeesState) {
            final subtitle = prepareTransferState.maybeWhen(
                  error: (exception) => exception.toString(),
                  orElse: () => null,
                ) ??
                estimateFeesState.when(
                  initial: () => null,
                  success: (fees) => '${fees.toTokens().removeZeroes()} TON',
                  insufficientFunds: (fees) => 'Insufficient funds',
                  insufficientOwnerFunds: (fees) => 'Insufficient owner funds',
                  error: (exception) => exception.toString(),
                );

            final hasError = prepareTransferState.maybeWhen(
                  error: (_) => true,
                  orElse: () => false,
                ) ||
                estimateFeesState.maybeWhen(
                  insufficientFunds: (_) => true,
                  insufficientOwnerFunds: (_) => true,
                  error: (_) => true,
                  orElse: () => false,
                );

            return SectionedCardSection(
              title: 'Blockchain fee',
              subtitle: subtitle,
              hasError: hasError,
            );
          },
        ),
      );

  Widget comment() => SectionedCardSection(
        title: 'Comment',
        subtitle: widget.comment,
      );

  Widget notifyReceiver() => SectionedCardSection(
        title: 'Notify receiver',
        subtitle: widget.notifyReceiver ? 'Yes' : 'No',
      );

  Widget submitButton() => BlocBuilder<TokenWalletEstimateFeesBloc, TokenWalletEstimateFeesState>(
        bloc: estimateFeesBloc,
        builder: (context, estimateFeesState) =>
            BlocBuilder<TokenWalletPrepareTransferBloc, TokenWalletPrepareTransferState>(
          bloc: prepareTransferBloc,
          builder: (context, prepareTransferState) {
            final message = prepareTransferState.maybeWhen(
              success: (message) => message,
              orElse: () => null,
            );

            final sufficientFunds = estimateFeesState.maybeWhen(
              success: (_) => true,
              orElse: () => false,
            );

            return CustomElevatedButton(
              onPressed: sufficientFunds && message != null
                  ? () => onPressed(
                        message: message,
                        publicKey: widget.publicKey,
                      )
                  : null,
              text: 'Send',
            );
          },
        ),
      );

  Future<void> onPressed({
    required UnsignedMessage message,
    required String publicKey,
  }) async {
    String? password;

    final biometryInfoBloc = context.read<BiometryInfoBloc>();

    if (biometryInfoBloc.state.isAvailable && biometryInfoBloc.state.isEnabled) {
      password = await getPasswordFromBiometry(publicKey);
    }

    if (!mounted) return;

    if (password != null) {
      pushTokenSendResult(
        message: message,
        publicKey: publicKey,
        password: password,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PasswordEnterPage(
            modalContext: widget.modalContext,
            publicKey: publicKey,
            onSubmit: (password) => pushTokenSendResult(
              message: message,
              publicKey: publicKey,
              password: password,
            ),
          ),
        ),
      );
    }
  }

  Future<String?> getPasswordFromBiometry(String ownerPublicKey) async {
    try {
      final password = await getIt.get<BiometryRepository>().getKeyPassword(
            localizedReason: 'Please authenticate to interact with wallet',
            publicKey: ownerPublicKey,
          );

      return password;
    } catch (err) {
      return null;
    }
  }

  Future<void> pushTokenSendResult({
    required UnsignedMessage message,
    required String publicKey,
    required String password,
  }) =>
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => TokenSendResultPage(
            modalContext: widget.modalContext,
            owner: widget.owner,
            rootTokenContract: widget.rootTokenContract,
            message: message,
            publicKey: publicKey,
            password: password,
            sendingText: 'Transaction is sending...',
            successText: 'Transaction has been sent successfully',
          ),
        ),
        (_) => false,
      );
}
