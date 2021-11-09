part of 'token_send_transaction_flow.dart';

class _EnterAddressBody extends StatefulWidget {
  final ValueNotifier<String?> clipboard;
  final String? amount;
  final String? address;
  final String? comment;
  final String? balance;
  final String? currency;

  const _EnterAddressBody({
    Key? key,
    required this.clipboard,
    this.balance,
    this.currency,
    this.amount,
    this.address,
    this.comment,
  }) : super(key: key);

  @override
  __EnterAddressBodyState createState() => __EnterAddressBodyState();
}

class __EnterAddressBodyState extends State<_EnterAddressBody> {
  final _scrollController = ScrollController();

  final _amountFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _commentFocus = FocusNode();

  late final TextEditingController _amountController;
  late final TextEditingController _addressController;
  late final TextEditingController _commentController;

  late final _notifyReceiverCheckNotifier = ValueNotifier<bool>(false);

  ValueNotifier<String?> get _clipboard => widget.clipboard;

  @override
  void initState() {
    _amountController = TextEditingController(text: widget.amount?.replaceAll(',', ''));
    _addressController = TextEditingController(text: widget.address);
    _commentController = TextEditingController(text: widget.comment);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    _amountFocus.dispose();
    _addressFocus.dispose();
    _commentFocus.dispose();
    _notifyReceiverCheckNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FadingEdgeScrollView.fromSingleChildScrollView(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CrystalTextFormField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      hintText: LocaleKeys.send_transaction_modal_input_hints_amount.tr(),
                      maxLength: 64,
                      suffix: _suffixText(
                        text: LocaleKeys.send_transaction_modal_input_actions_max.tr(),
                        onTap: () {
                          _amountController.text = widget.balance?.removeZeroes() ?? '';
                        },
                      ),
                      scrollPadding: const EdgeInsets.only(bottom: 24),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      formatters: [AmountInputFormatter()],
                    ),
                    const CrystalDivider(height: 8),
                    if (widget.balance != null && widget.currency != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          LocaleKeys.send_transaction_modal_input_balance.tr(
                            args: [
                              widget.balance!.removeZeroes(),
                              widget.currency!,
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 0.75,
                            color: CrystalColor.fontSecondaryDark,
                          ),
                        ),
                      ),
                    const CrystalDivider(height: 16),
                    AnimatedBuilder(
                      animation: Listenable.merge([_addressController, _clipboard]),
                      builder: (context, _) => CrystalTextFormField(
                        key: const ValueKey('send_transaction_address_text_field'),
                        controller: _addressController,
                        focusNode: _addressFocus,
                        hintText: LocaleKeys.send_transaction_modal_input_hints_address.tr(),
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp('[:0-9a-zA-Z]')),
                        ],
                        scrollPadding: const EdgeInsets.only(bottom: 24),
                        maxLength: 128,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value != null && validateAddress(value)) {
                            return null;
                          } else {
                            return LocaleKeys.fields_validation_errors_wrong_address.tr();
                          }
                        },
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_addressController.text.isEmpty && _clipboard.value != null)
                              _suffixText(
                                text: 'Paste',
                                paddingLeft: 12,
                                paddingRight: 6,
                                onTap: () {
                                  _addressController.text = _clipboard.value!;
                                  _addressController.selection =
                                      TextSelection.collapsed(offset: _clipboard.value!.length);
                                },
                              ),
                            _suffixText(
                              text: 'Scan',
                              paddingLeft: 6,
                              paddingRight: 12,
                              onTap: () async {
                                var status = await ph.Permission.camera.status;

                                if (!status.isGranted) {
                                  status = await ph.Permission.camera.request();
                                }

                                if (!status.isGranted) {
                                  ph.openAppSettings();
                                } else {
                                  if (FocusScope.of(context).hasFocus) {
                                    FocusScope.of(context).unfocus();
                                    await Future.delayed(const Duration(milliseconds: 500));
                                  }

                                  final result = await Navigator.of(context).push<String>(
                                    MaterialPageRoute(
                                      builder: (context) => const ScannerWidget(),
                                    ),
                                  );

                                  if (result != null) {
                                    final regExp = RegExp(
                                      r"([\-]?[\d]:[\d\w\+\-\/]{64})|([\d\w\+\-\/]{48})|([13]{1}[a-km-zA-HJ-NP-Z1-9]{26,33}|bc1[a-z0-9]{39,59})|(0x[a-fA-F0-9]{40})",
                                    );

                                    final address = regExp.stringMatch(result);

                                    if (address != null) {
                                      _addressController.text = address;
                                    } else {
                                      await showErrorCrystalFlushbar(
                                        context,
                                        message: 'Incorrect address',
                                      );
                                      return;
                                    }

                                    final amountRegExp = RegExp(
                                      r"amount=[+-]?((\d+(\.\d*)?)|(\.\d+))",
                                    );

                                    final amount = amountRegExp.firstMatch(result)?.group(1);

                                    if (amount != null) {
                                      _amountController.text = amount;
                                    }

                                    final commentRegExp = RegExp(
                                      r"comment=(.+?(?=&|$))",
                                    );

                                    final comment = commentRegExp.firstMatch(result)?.group(1);

                                    if (comment != null) {
                                      _commentController.text = Uri.decodeFull(comment);
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const CrystalDivider(height: 24),
                    _getNotifyReceiverCheckBox(),
                    const CrystalDivider(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: Listenable.merge([_amountController, _addressController]),
              builder: (context, _) => CrystalButton(
                enabled: _amountController.text.isNotEmpty && _addressController.text.isNotEmpty,
                text: LocaleKeys.actions_send.tr(),
                onTap: _send,
              ),
            ),
          ),
        ],
      );

  Widget _getNotifyReceiverCheckBox() => Row(
        children: [
          ExpandTapWidget(
            onTap: () => _notifyReceiverCheckNotifier.value = !_notifyReceiverCheckNotifier.value,
            tapPadding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<bool>(
              valueListenable: _notifyReceiverCheckNotifier,
              builder: (context, selected, _) => CrystalCheckbox(
                value: selected,
              ),
            ),
          ),
          const SizedBox(
            width: 17,
          ),
          const Text(
            'Notify receiver',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 0.75,
              color: CrystalColor.fontSecondaryDark,
            ),
          ),
        ],
      );

  Widget _suffixText({
    required String text,
    double paddingLeft = 16,
    double paddingRight = 16,
    VoidCallback? onTap,
  }) =>
      AnimatedSwitcher(
        duration: kThemeAnimationDuration,
        child: onTap != null
            ? IntrinsicWidth(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(paddingLeft, 14, paddingRight, 14),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: CrystalColor.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      );

  void _send() {
    context.read<TokenWalletTransferBloc>().add(
          TokenWalletTransferEvent.prepareTransfer(
            destination: _addressController.text,
            tokens: _amountController.text,
            notifyReceiver: _notifyReceiverCheckNotifier.value,
          ),
        );
  }
}