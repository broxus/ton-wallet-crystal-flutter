import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/design.dart';
import '../../../design/widgets/custom_app_bar.dart';
import '../../../design/widgets/custom_elevated_button.dart';
import '../../../design/widgets/custom_text_form_field.dart';
import '../../../design/widgets/text_clear_button.dart';
import '../../../design/widgets/unfocusing_gesture_detector.dart';

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
            appBar: const CustomAppBar(),
            body: body(),
          ),
        ),
      );

  Widget body() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    title(),
                    const SizedBox(height: 32),
                    CustomTextFormField(
                      controller: controller,
                      hintText: 'Enter the name...',
                      suffixIcon: TextClearButton(
                        controller: controller,
                      ),
                    ),
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

  Widget title() => const Text(
        'Enter the name for seed phrase',
        style: TextStyle(
          fontSize: 36,
          color: CrystalColor.fontHeaderDark,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.start,
      );

  Widget submitButton() => CustomElevatedButton(
        onPressed: () => widget.onSubmit(controller.text.isNotEmpty ? controller.text.trim() : null),
        text: 'Submit',
      );
}
