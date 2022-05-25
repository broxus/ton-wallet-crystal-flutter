import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../generated/codegen_loader.g.dart';
import '../widgets/crystal_title.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_elevated_button.dart';
import '../widgets/custom_text_form_field.dart';
import '../widgets/text_field_clear_button.dart';
import '../widgets/unfocusing_gesture_detector.dart';

class SeedNamePage extends StatefulWidget {
  final void Function(String? name) onSubmit;

  const SeedNamePage({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<SeedNamePage> createState() => _SeedNamePageState();
}

class _SeedNamePageState extends State<SeedNamePage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: UnfocusingGestureDetector(
          child: Scaffold(
            appBar: AppBar(
              leading: const CustomBackButton(),
            ),
            body: body(),
          ),
        ),
      );

  Widget body() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16) - const EdgeInsets.only(top: 16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    title(),
                    const SizedBox(height: 32),
                    field(),
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

  Widget title() => CrystalTitle(
        text: LocaleKeys.seed_phrase_name_description.tr(),
      );

  Widget field() => CustomTextFormField(
        name: LocaleKeys.name.tr(),
        controller: controller,
        hintText: '${LocaleKeys.enter_name.tr()}...',
        suffixIcon: TextFieldClearButton(
          controller: controller,
        ),
      );

  Widget submitButton() => CustomElevatedButton(
        onPressed: () => widget.onSubmit(controller.text.trim().isNotEmpty ? controller.text.trim() : null),
        text: LocaleKeys.submit.tr(),
      );
}