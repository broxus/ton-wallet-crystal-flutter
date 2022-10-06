import 'dart:math';

import 'constants.dart';

Map<int, String> generateCheckingMap(List<String> phrase) {
  final rng = Random();
  final indices = <int>[];

  while (indices.length < kDefaultCheckingWordsAmount) {
    final number = rng.nextInt(phrase.length);

    if (indices.contains(number)) {
      continue;
    }

    indices.add(number);
  }

  indices.sort();

  final map = {for (final index in indices) index: phrase[index]};

  return map;
}

String decentralizationPolicyLink() => 'https://l1.broxus.com/everscale/wallet/terms';

String everAccountExplorerLink(String address) => 'https://everscan.io/accounts/$address';

String everTransactionExplorerLink(String id) => 'https://everscan.io/transactions/$id';

String venomAccountExplorerLink(String address) => 'https://venomscan.com/accounts/$address';

String venomTransactionExplorerLink(String id) => 'https://venomscan.com/transactions/$id';
