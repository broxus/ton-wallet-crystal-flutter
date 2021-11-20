import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/subjects.dart';

import '../../domain/models/token_contract_asset.dart';
import '../../domain/repositories/ton_assets_repository.dart';
import '../dtos/token_contract_asset_dto.dart';
import '../sources/local/hive_source.dart';
import '../sources/remote/rest_source.dart';

@preResolve
@LazySingleton(as: TonAssetsRepository)
class TonAssetsRepositoryImpl implements TonAssetsRepository {
  final HiveSource _hiveSource;
  final RestSource _restSource;
  final _assetsSubject = BehaviorSubject<List<TokenContractAsset>>.seeded([]);

  TonAssetsRepositoryImpl._(
    this._hiveSource,
    this._restSource,
  );

  @factoryMethod
  static Future<TonAssetsRepositoryImpl> create(
    HiveSource hiveSource,
    RestSource restSource,
  ) async {
    final tonAssetsRepositoryImpl = TonAssetsRepositoryImpl._(
      hiveSource,
      restSource,
    );
    // await tonAssetsRepositoryImpl._initialize();
    return tonAssetsRepositoryImpl;
  }

  @override
  Stream<List<TokenContractAsset>> get assetsStream =>
      _assetsSubject.stream.distinct((previous, next) => listEquals(previous, next));

  @override
  List<TokenContractAsset> get assets => _assetsSubject.value;

  @override
  Future<void> save(TokenContractAsset asset) async {
    await _hiveSource.saveTokenContractAsset(asset.toDto());

    final assets = _assetsSubject.value.where((e) => e.address != asset.address).toList()..add(asset);
    _assetsSubject.add(assets);
  }

  @override
  Future<void> saveCustom({
    required String name,
    required String symbol,
    required int decimals,
    required String address,
    required int version,
  }) async {
    final gravatarIcon = await _restSource.getGravatarIcon(address);

    final assetDto = TokenContractAssetDto(
      name: name,
      symbol: symbol,
      decimals: decimals,
      address: address,
      gravatarIcon: gravatarIcon,
      version: version,
    );
    final asset = assetDto.toModel();

    await _hiveSource.saveTokenContractAsset(assetDto);

    final assets = _assetsSubject.value.where((e) => e.address != asset.address).toList()..add(asset);
    _assetsSubject.add(assets);
  }

  @override
  Future<void> remove(String address) async {
    final assets = _assetsSubject.value.where((e) => e.address != address).toList();
    _assetsSubject.add(assets);

    await _hiveSource.removeTokenContractAsset(address);
  }

  @override
  Future<void> clear() async {
    _assetsSubject.add([]);

    await _hiveSource.clearTokenContractAssets();
  }

  @override
  Future<void> refresh() async {
    final manifest = await _restSource.getTonAssetsManifest();

    final assets = <TokenContractAsset>[];

    for (final token in manifest.tokens) {
      String? svgIcon;
      List<int>? gravatarIcon;

      final logoURI = token.logoURI;

      if (logoURI != null) {
        svgIcon = await _restSource.getTokenSvgIcon(logoURI);
      } else {
        gravatarIcon = await _restSource.getGravatarIcon(token.address);
      }

      final assetDto = TokenContractAssetDto(
        name: token.name,
        chainId: token.chainId,
        symbol: token.symbol,
        decimals: token.decimals,
        address: token.address,
        svgIcon: svgIcon,
        gravatarIcon: gravatarIcon,
        version: token.version,
      );
      final asset = assetDto.toModel();

      await _hiveSource.saveTokenContractAsset(assetDto);

      assets.add(asset);
    }

    final old = [..._assetsSubject.value]..removeWhere((e) => assets.any((el) => e.address == el.address));

    final list = [
      ...assets,
      ...old,
    ];

    _assetsSubject.add(list);
  }

  Future<void> _initialize() async {
    final assets = _hiveSource.getTokenContractAssets().map((e) => e.toModel()).toList();

    if (assets.isEmpty) {
      await refresh();
    } else {
      _assetsSubject.add(assets);

      refresh();
    }
  }
}
