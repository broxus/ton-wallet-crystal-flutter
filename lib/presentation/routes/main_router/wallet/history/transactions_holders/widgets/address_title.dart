import 'package:flutter/material.dart';

import '../../../../../../design/design.dart';

class AddressTitle extends StatelessWidget {
  final String address;

  const AddressTitle({
    Key? key,
    required this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(
        address.ellipseAddress(),
      );
}
