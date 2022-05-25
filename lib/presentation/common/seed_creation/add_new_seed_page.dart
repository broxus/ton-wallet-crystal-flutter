import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import '../../../generated/codegen_loader.g.dart';
import '../../router.gr.dart';
import '../widgets/crystal_title.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_dropdown_button.dart';
import '../widgets/custom_elevated_button.dart';

class AddNewSeedPage extends StatefulWidget {
  const AddNewSeedPage({
    Key? key,
  }) : super(key: key);

  @override
  State<AddNewSeedPage> createState() => _AddNewSeedPageState();
}

class _AddNewSeedPageState extends State<AddNewSeedPage> {
  final optionNotifier = ValueNotifier<_CreationActions>(_CreationActions.create);

  @override
  void dispose() {
    optionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: AppBar(
            leading: CustomBackButton(
              onPressed: () => context.router.pop(),
            ),
          ),
          body: body(),
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
                    dropdownButton(),
                    const SizedBox(height: 16),
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

  Widget title() => CrystalTitle(
        text: LocaleKeys.add_new_seed_phrase_description.tr(),
      );

  Widget dropdownButton() => ValueListenableBuilder<_CreationActions>(
        valueListenable: optionNotifier,
        builder: (context, value, child) => CustomDropdownButton<_CreationActions>(
          items: _CreationActions.values.map((e) => Tuple2(e, e.describe())).toList(),
          value: value,
          onChanged: (value) {
            if (value != null) {
              optionNotifier.value = value;
            }
          },
        ),
      );

  Widget submitButton() => CustomElevatedButton(
        onPressed: () => context.router.push(
          SeedNameRoute(
            onSubmit: (String? name) {
              optionNotifier.value == _CreationActions.create
                  ? context.router.push(
                      SeedPhraseSaveRoute(
                        seedName: name,
                      ),
                    )
                  : context.router.push(
                      SeedPhraseImportRoute(
                        seedName: name,
                        isLegacy: optionNotifier.value == _CreationActions.importLegacy,
                      ),
                    );
            },
          ),
        ),
        text: LocaleKeys.next.tr(),
      );
}

enum _CreationActions {
  create,
  import,
  importLegacy,
}

extension on _CreationActions {
  String describe() {
    switch (this) {
      case _CreationActions.create:
        return LocaleKeys.create_seed.tr();
      case _CreationActions.import:
        return LocaleKeys.import_seed.tr();
      case _CreationActions.importLegacy:
        return LocaleKeys.import_legacy_seed.tr();
    }
  }
}