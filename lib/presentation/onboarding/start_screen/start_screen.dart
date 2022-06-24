import 'package:flutter/material.dart';

import '../../../generated/assets.gen.dart';
import '../../common/general/button/primary_button.dart';
import '../../util/extensions/context_extensions.dart';
import '../widgets/onboarding_background.dart';
import 'agree_decentralization.dart';
import 'widgets/sliding_block_chains.dart';

/// Entry point in the app if user not authenticated
class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = context.themeStyle;

    return Scaffold(
      body: OnboardingBackground(
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Expanded(child: SlidingBlockChains()),
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.localization.welcome_title,
                      style: style.styles.fullScreenStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.localization.welcome_subtitle,
                      style: style.styles.basicStyle,
                    ),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      text: context.localization.create_new_wallet,
                      onPressed: () => Navigator.of(context).push(AgreeDecentralizationRoute()),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: context.localization.sign_in,
                      onPressed: () {},
                      isTransparent: true,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'Ledger',
                      // TODO: change icon
                      icon: Assets.images.iconQr.svg(
                        color: style.styles.secondaryButtonStyle.color,
                      ),
                      onPressed: () {},
                      isTransparent: true,
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
}
