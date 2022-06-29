import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../common/general/button/primary_button.dart';
import '../../common/general/button/text_button.dart';
import '../../common/general/default_appbar.dart';
import '../../common/general/field/seed_phrase_input.dart';
import '../../util/extensions/context_extensions.dart';
import '../../util/extensions/iterable_extensions.dart';
import '../../util/theme_styles.dart';
import '../general_screens/create_password.dart';
import '../widgets/onboarding_background.dart';
import 'widgets/tabbar.dart';

class EnterSeedPhraseRoute extends MaterialPageRoute<void> {
  EnterSeedPhraseRoute(String phraseName)
      : super(builder: (_) => EnterSeedPhraseScreen(phraseName: phraseName));
}

class EnterSeedPhraseScreen extends StatefulWidget {
  final String phraseName;

  const EnterSeedPhraseScreen({Key? key, required this.phraseName}) : super(key: key);

  @override
  State<EnterSeedPhraseScreen> createState() => _EnterSeedPhraseScreenState();
}

class _EnterSeedPhraseScreenState extends State<EnterSeedPhraseScreen> {
  final formKey = GlobalKey<FormState>();
  final controllers = List.generate(24, (_) => TextEditingController());
  final focuses = List.generate(24, (_) => FocusNode());
  final values = const <int>[12, 24];

  /// Display paste only if there are no text(false) in fields else clear (true)
  final isClearButtonState = ValueNotifier<bool>(false);
  late ValueNotifier<int> valuesNotifier = ValueNotifier<int>(values.first);

  @override
  void initState() {
    super.initState();
    controllers.forEach(
      (c) => c.addListener(() {
        final hasText = controllers.any((controller) => controller.text.isNotEmpty);
        isClearButtonState.value = hasText;
      }),
    );
  }

  @override
  void dispose() {
    controllers.forEach((c) => c.dispose());
    focuses.forEach((f) => f.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.localization;
    final themeStyle = context.themeStyle;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return OnboardingBackground(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: DefaultAppBar(
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: isClearButtonState,
                builder: (_, isClear, __) {
                  return TextPrimaryButton.appBar(
                    onPressed: isClear ? clearFields : pastePhrase,
                    text: isClear ? localization.clear : localization.paste,
                    style: themeStyle.styles.basicBoldStyle,
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: _buildPhrasesList(localization, themeStyle),
                ),
                SizedBox(
                  height: bottomPadding < kPrimaryButtonHeight
                      ? 0
                      : bottomPadding - kPrimaryButtonHeight,
                ),
                PrimaryButton(
                  text: localization.confirm,
                  onPressed: _confirmAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhrasesList(AppLocalizations localization, ThemeStyle themeStyle) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: ValueListenableBuilder<int>(
          valueListenable: valuesNotifier,
          builder: (_, value, __) {
            final activeControllers = controllers.take(value).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.enter_seed_phrase,
                  style: themeStyle.styles.appbarStyle,
                ),
                const SizedBox(height: 28),
                EWTabBar<int>(
                  values: values,
                  selectedValue: value,
                  onChanged: (v) {
                    formKey.currentState?.reset();
                    valuesNotifier.value = v;
                  },
                  builder: (_, v, isActive) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        // TODO: replace word
                        '$v words',
                        style: themeStyle.styles.basicStyle.copyWith(
                          color: isActive ? null : themeStyle.colors.textSecondaryTextButtonColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: activeControllers
                            .getRange(0, value ~/ 2)
                            .mapIndex(
                              (c, index) => _inputBuild(
                                c,
                                focuses[index],
                                index + 1,
                                themeStyle,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: activeControllers.getRange(value ~/ 2, value).mapIndex(
                          (c, index) {
                            final i = index + value ~/ 2;
                            return _inputBuild(c, focuses[i], i + 1, themeStyle);
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// [index] start with 1
  Widget _inputBuild(
    TextEditingController controller,
    FocusNode focus,
    int index,
    ThemeStyle themeStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SeedPhraseInput(
        controller: controller,
        focus: focus,
        prefixText: '$index.',
        requestNextField: () => focuses[index].requestFocus(),
        textInputAction:
            index == valuesNotifier.value ? TextInputAction.done : TextInputAction.next,
        confirmAction: _confirmAction,
      ),
    );
  }

  void _confirmAction() {
    if (formKey.currentState?.validate() ?? false) {
      try {
        final phrase = controllers.take(valuesNotifier.value).map((e) => e.text).toList();
        final mnemonicType = valuesNotifier.value == values.last
            ? const MnemonicType.legacy()
            : const MnemonicType.labs(id: 0);

        deriveFromPhrase(
          phrase: phrase,
          mnemonicType: mnemonicType,
        );
        Navigator.of(context).push(CreatePasswordRoute(phrase, widget.phraseName));
      } on Object catch (_) {
        /// TODO: display dialog error
      }
    }
  }

  void clearFields() {
    controllers.forEach(
      (c) => c
        ..text = ''
        ..selection = const TextSelection.collapsed(offset: 0),
    );
    formKey.currentState?.reset();
  }

  Future<void> pastePhrase() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final words = clipboard?.text?.split(RegExp('[ |;|,|:]')) ?? <String>[];

    if (words.isNotEmpty && words.length == valuesNotifier.value) {
      for (final word in words) {
        if (getHints(word).isEmpty) {
          words.clear();
          break;
        }
      }
    } else {
      words.clear();
    }

    if (words.isEmpty) {
      if (!mounted) return;

      formKey.currentState?.reset();

      // TODO: show snackbar
      // showErrorCrystalFlushbar(
      //   context,
      //   message: AppLocalizations.of(context)!.incorrect_words_format,
      //   flushbarPosition: FlushbarPosition.BOTTOM,
      //   margin: const EdgeInsets.only(bottom: 12),
      // );
      return;
    }

    words.asMap().forEach((index, word) {
      controllers[index].value = TextEditingValue(
        text: word,
        selection: TextSelection.fromPosition(TextPosition(offset: word.length)),
      );
    });
    formKey.currentState?.validate();
  }
}
