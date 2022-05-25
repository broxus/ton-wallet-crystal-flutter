import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../../../injection.dart';
import '../../../../../data/repositories/keys_repository.dart';
import '../../../../generated/codegen_loader.g.dart';
import '../../../common/form/field_state.dart';
import '../../../common/form/form_state.dart';
import '../../../common/form/value_state.dart';

part 'input_password_field_notifier.freezed.dart';

class InputPasswordFieldNotifier extends ChangeNotifier {
  final _keystoreRepository = getIt.get<KeysRepository>();
  final _passwordInputSubject = PublishSubject<String>();
  final String _publicKey;
  var _state = InputPasswordFieldState.empty();

  InputPasswordFieldNotifier(this._publicKey) {
    _passwordInputSubject
        .debounce((e) => TimerStream(e, const Duration(milliseconds: 300)))
        .asyncMap((e) => _validatePassword(e))
        .listen((e) {
      _state = _state.copyWith(passwordState: e);
      notifyListeners();
    });
  }

  InputPasswordFieldState get state => _state;

  void onPasswordChange(String value) {
    if (!_state.passwordState.isLoading) {
      _state = _state.copyWith.passwordState(valueState: ValueState.loading);
      notifyListeners();
    }
    _passwordInputSubject.add(value);
  }

  Future<FieldState> _validatePassword(String value) async {
    if (value.isEmpty) {
      return FieldState(
        valueState: ValueState.empty,
        value: value,
      );
    }

    final isCorrect = await _keystoreRepository.checkKeyPassword(
      publicKey: _publicKey,
      password: value,
    );

    return isCorrect
        ? FieldState(
            valueState: ValueState.valid,
            value: value,
          )
        : FieldState(
            valueState: ValueState.invalid,
            value: value,
            errorText: LocaleKeys.invalid_password.tr(),
          );
  }
}

@freezed
class InputPasswordFieldState with _$InputPasswordFieldState {
  const factory InputPasswordFieldState({
    required FieldState passwordState,
  }) = _InputPasswordFieldState;

  factory InputPasswordFieldState.empty() => const InputPasswordFieldState(
        passwordState: FieldState(
          valueState: ValueState.empty,
          value: '',
        ),
      );

  const InputPasswordFieldState._();

  FormState get formState => FormState(
        valueState: passwordState.valueState,
        errorText: passwordState.errorText,
      );
}