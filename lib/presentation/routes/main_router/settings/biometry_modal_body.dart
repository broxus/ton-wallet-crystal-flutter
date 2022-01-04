import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../../../../../../../domain/blocs/biometry/biometry_info_bloc.dart';
import '../../../design/design.dart';

class BiometryModalBody extends StatefulWidget {
  const BiometryModalBody({Key? key}) : super(key: key);

  @override
  _BiometryModalBodyState createState() => _BiometryModalBodyState();
}

class _BiometryModalBodyState extends State<BiometryModalBody> {
  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            getBiometricSwitcher(),
            const SizedBox(height: 34),
          ],
        ),
      );

  Widget getBiometricSwitcher() => Row(
        children: [
          Expanded(
            child: Text(
              LocaleKeys.biometry_checkbox.tr(),
              style: const TextStyle(
                color: CrystalColor.fontDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          BlocBuilder<BiometryInfoBloc, BiometryInfoState>(
            bloc: context.watch<BiometryInfoBloc>(),
            builder: (context, state) => PlatformSwitch(
              value: state.isEnabled,
              onChanged: (p0) => context.read<BiometryInfoBloc>().add(
                    BiometryInfoEvent.setStatus(
                      localizedReason: 'Please authenticate to interact with wallet',
                      isEnabled: !state.isEnabled,
                    ),
                  ),
            ),
          ),
        ],
      );
}