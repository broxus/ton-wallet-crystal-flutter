import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../../../domain/blocs/account/account_assets_options_bloc.dart';
import '../../../../../../../../../../domain/models/token_contract_asset.dart';
import '../../../../../../../../../../injection.dart';
import '../../../../../design/design.dart';
import '../../../../../design/widgets/crystal_flushbar.dart';
import '../../../../../design/widgets/custom_elevated_button.dart';
import '../../../../../design/widgets/custom_text_form_field.dart';
import '../../../../../design/widgets/text_field_clear_button.dart';
import '../../../../../design/widgets/unfocusing_gesture_detector.dart';
import 'selection_asset_holder.dart';

class AssetsLayout extends StatefulWidget {
  final String address;
  final void Function(
    List<TokenContractAsset> added,
    List<TokenContractAsset> removed,
  ) onSave;

  const AssetsLayout({
    Key? key,
    required this.address,
    required this.onSave,
  }) : super(key: key);

  @override
  _AssetsLayoutState createState() => _AssetsLayoutState();
}

class _AssetsLayoutState extends State<AssetsLayout> {
  final controller = TextEditingController();
  final accountAssetsOptionsBloc = getIt.get<AccountAssetsOptionsBloc>();
  final selectedNotifier = ValueNotifier<List<TokenContractAsset>>([]);
  final filteredNotifier = ValueNotifier<List<TokenContractAsset>>([]);
  late final StreamSubscription accountAssetsErrorsSubscription;

  @override
  void initState() {
    super.initState();
    accountAssetsErrorsSubscription = accountAssetsOptionsBloc.errorsStream
        .listen((event) => showErrorCrystalFlushbar(context, message: event.toString()));
    accountAssetsOptionsBloc.add(AccountAssetsOptionsEvent.load(widget.address));
  }

  @override
  void didUpdateWidget(covariant AssetsLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      accountAssetsOptionsBloc.add(AccountAssetsOptionsEvent.load(widget.address));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    accountAssetsOptionsBloc.close();
    selectedNotifier.dispose();
    filteredNotifier.dispose();
    accountAssetsErrorsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AccountAssetsOptionsBloc, AccountAssetsOptionsState>(
        bloc: accountAssetsOptionsBloc,
        listener: (context, state) {
          selectedNotifier.value = [...state.added];
          filteredNotifier.value = [...state.added, ...state.available];
        },
        builder: (context, state) => UnfocusingGestureDetector(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(state),
              const SizedBox(height: 16),
              Expanded(
                child: list(),
              ),
              const SizedBox(height: 16),
              submitButton(state),
            ],
          ),
        ),
      );

  Widget field(AccountAssetsOptionsState state) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
        ),
        child: CustomTextFormField(
          name: 'search',
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          hintText: LocaleKeys.add_assets_modal_search_layout_hint.tr(),
          suffixIcon: TextFieldClearButton(controller: controller),
          onChanged: (value) {
            final text = value?.toLowerCase().trim() ?? '';
            filteredNotifier.value = [...state.added, ...state.available]
                .where((e) => e.name.toLowerCase().contains(text) || e.symbol.toLowerCase().contains(text))
                .toList();
          },
          borderColor: Colors.transparent,
          errorBorderColor: Colors.transparent,
        ),
      );

  Widget list() => ValueListenableBuilder<List<TokenContractAsset>>(
        valueListenable: filteredNotifier,
        builder: (context, filteredValue, child) => ValueListenableBuilder<List<TokenContractAsset>>(
          valueListenable: selectedNotifier,
          builder: (context, value, child) => ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: filteredValue.length,
            itemBuilder: (context, index) {
              final asset = filteredValue[index];

              return SelectionAssetHolder(
                key: ValueKey(asset.address),
                onTap: () {
                  final assets = [...selectedNotifier.value];

                  if (value.contains(asset)) {
                    assets.remove(asset);
                  } else {
                    assets.add(asset);
                  }

                  selectedNotifier.value = assets;
                },
                asset: filteredValue[index],
                isSelected: value.contains(asset),
              );
            },
            separatorBuilder: (_, __) => const Divider(thickness: 1, height: 1),
          ),
        ),
      );

  Widget submitButton(AccountAssetsOptionsState state) => ValueListenableBuilder<List<TokenContractAsset>>(
        valueListenable: selectedNotifier,
        builder: (context, value, child) => CustomElevatedButton(
          onPressed: !listEquals(value, state.added)
              ? () {
                  context.router.pop();
                  widget.onSave(
                    value.where((e) => !state.added.contains(e)).toList(),
                    state.added.where((e) => !value.contains(e)).toList(),
                  );
                }
              : null,
          text: LocaleKeys.actions_save.tr(),
        ),
      );
}
