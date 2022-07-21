import 'package:ever_wallet/application/common/constants.dart';
import 'package:ever_wallet/application/common/general/button/primary_button.dart';
import 'package:ever_wallet/application/common/general/button/text_button.dart';
import 'package:ever_wallet/application/common/general/onboarding_appbar.dart';
import 'package:ever_wallet/application/onboarding/create_wallet/check_seed_phrase_screen/check_seed_phase_screen.dart';
import 'package:ever_wallet/application/onboarding/general_screens/create_password.dart';
import 'package:ever_wallet/application/onboarding/widgets/onboarding_background.dart';
import 'package:ever_wallet/application/util/colors.dart';
import 'package:ever_wallet/application/util/extensions/context_extensions.dart';
import 'package:ever_wallet/application/util/extensions/iterable_extensions.dart';
import 'package:ever_wallet/application/util/theme_styles.dart';
import 'package:ever_wallet/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

class SaveSeedPhraseRoute extends MaterialPageRoute<void> {
  SaveSeedPhraseRoute(String phraseName)
      : super(
          builder: (_) => SaveSeedPhraseScreen(phraseName: phraseName),
        );
}

/// !!! Here displays only 12 words
class SaveSeedPhraseScreen extends StatefulWidget {
  final String phraseName;

  const SaveSeedPhraseScreen({Key? key, required this.phraseName}) : super(key: key);

  @override
  State<SaveSeedPhraseScreen> createState() => _SaveSeedPhraseScreenState();
}

class _SaveSeedPhraseScreenState extends State<SaveSeedPhraseScreen> {
  final key = generateKey(kDefaultMnemonicType);
  final isCopied = ValueNotifier<bool>(false);

  List<String> get words => key.words;

  @override
  Widget build(BuildContext context) {
    final localization = context.localization;
    final themeStyle = context.themeStyle;

    return OnboardingBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: const OnboardingAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localization.save_seed_phrase, style: themeStyle.styles.appbarStyle),
              const SizedBox(height: 16),
              Text(
                // TODO: change text
                'It is the series of words generated by your cryptocurrency wallet that give you access to the crypto associated with that wallet',
                style: themeStyle.styles.basicStyle,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: ColorsRes.lightBlue.withOpacity(0.08),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: words
                                        .getRange(0, 6)
                                        .mapIndex((word, i) => _textPair(word, i + 1, themeStyle))
                                        .toList(),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: words
                                        .getRange(6, 12)
                                        .mapIndex((word, i) => _textPair(word, i + 7, themeStyle))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: isCopied,
                            builder: (_, copied, __) {
                              if (copied) {
                                return SizedBox(
                                  height: kPrimaryButtonHeight,
                                  child: Align(
                                    child: Text(
                                      // TODO: replace text
                                      'Copied',
                                      style: themeStyle.styles.basicStyle
                                          .copyWith(color: ColorsRes.green400),
                                    ),
                                  ),
                                );
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextPrimaryButton(
                                    icon: Assets.images.copy.svg(color: ColorsRes.lightBlue),
                                    fillWidth: false,
                                    text: localization.copy_words,
                                    style: themeStyle.styles.basicStyle
                                        .copyWith(color: ColorsRes.lightBlue),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: words.join(' ')));
                                      isCopied.value = true;
                                      Future.delayed(const Duration(seconds: 2), () {
                                        isCopied.value = false;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          // To allow scroll above buttons
                          const SizedBox(height: kPrimaryButtonHeight * 2 + 12),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                          PrimaryButton(
                            // TODO: replace text
                            text: 'Check the phrase',
                            onPressed: () => Navigator.of(context).push(
                              CheckSeedPhraseRoute(words, widget.phraseName),
                            ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            backgroundColor: const Color(0xFF253056),
                            text: "Skip, I'll take the risk",
                            onPressed: () => Navigator.of(context).push(
                              CreatePasswordRoute(words, widget.phraseName),
                            ),
                            isTransparent: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textPair(String word, int index, ThemeStyle themeStyle) {
    final style = themeStyle.styles.basicStyle;
    final colors = themeStyle.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index.',
              style: style.copyWith(color: colors.textSecondaryTextButtonColor),
            ),
          ),
          Expanded(
            child: Text(word, style: style, textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }
}
