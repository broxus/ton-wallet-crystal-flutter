import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../../../../generated/codegen_loader.g.dart';
import '../../../../common/widgets/animated_offstage.dart';
import '../../../../common/widgets/custom_elevated_button.dart';
import '../../../../common/widgets/custom_text_form_field.dart';
import '../../../../common/widgets/text_field_clear_button.dart';
import '../../../../common/widgets/unfocusing_gesture_detector.dart';

class CustomTokenLayout extends StatefulWidget {
  final void Function(String) onSave;

  const CustomTokenLayout({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  _CustomTokenLayoutState createState() => _CustomTokenLayoutState();
}

class _CustomTokenLayoutState extends State<CustomTokenLayout> {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  final formValidityNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    controller.dispose();
    formValidityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UnfocusingGestureDetector(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: form(),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: submitButton(),
            ),
          ],
        ),
      );

  Widget form() => Form(
        key: formKey,
        onChanged: () =>
            formValidityNotifier.value = (formKey.currentState?.validate() ?? false) && controller.text.isNotEmpty,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.15),
          ),
          child: CustomTextFormField(
            name: LocaleKeys.address.tr(),
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            hintText: LocaleKeys.root_token_contract.tr(),
            suffixIcon: TextFieldClearButton(controller: controller),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              }

              if (!validateAddress(value)) {
                return LocaleKeys.invalid_value.tr();
              }
              return null;
            },
            borderColor: Colors.transparent,
            errorBorderColor: Colors.transparent,
          ),
        ),
      );

  Widget submitButton() => ValueListenableBuilder<bool>(
        valueListenable: formValidityNotifier,
        builder: (context, value, child) => AnimatedOffstage(
          duration: const Duration(milliseconds: 300),
          offstage: value,
          child: CustomElevatedButton(
            onPressed: () {
              final address = controller.text;
              context.router.pop();
              widget.onSave(address);
            },
            text: LocaleKeys.proceed.tr(),
          ),
        ),
      );
}