import 'package:ever_wallet/application/common/async_value.dart';
import 'package:ever_wallet/application/common/general/default_list_tile.dart';
import 'package:ever_wallet/application/common/general/flushbar.dart';
import 'package:ever_wallet/application/main/browser/widgets/longtap_focusable_widget.dart';
import 'package:ever_wallet/application/util/colors.dart';
import 'package:ever_wallet/application/util/extensions/context_extensions.dart';
import 'package:ever_wallet/application/util/styles.dart';
import 'package:ever_wallet/application/utils.dart';
import 'package:ever_wallet/data/models/bookmark.dart';
import 'package:ever_wallet/data/models/popular_resources.dart';
import 'package:ever_wallet/data/models/site_meta_data.dart';
import 'package:ever_wallet/data/repositories/bookmarks_repository.dart';
import 'package:ever_wallet/data/repositories/sites_meta_data_repository.dart';
import 'package:ever_wallet/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _stakingUrl =
    'https://broxus.medium.com/introducing-stever-and-the-new-era-of-liquid-staking-on-ever-dao-a52e77f48a85';

const _farmingUrl = 'https://docs.flatqube.io/use/farming/new-farming/how-to';

class BrowserHome extends StatefulWidget {
  final ValueChanged<String> changeUrl;

  const BrowserHome({
    required this.changeUrl,
    super.key,
  });

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final pageController = PageController(
    viewportFraction: 0.9,
  );

  /// This resources are not saved into storage and not editable
  final _popularResources = <PopularResources>[
    PopularResources(
      name: 'Octus Bridge',
      url: 'https://octusbridge.io',
      image: Assets.images.everLogo,
    ),
    PopularResources(
      name: 'FlatQube',
      url: 'https://flatqube.io',
      image: Assets.images.everLogo,
    ),
    PopularResources(
      name: 'EVER Scan',
      url: 'https://everscan.io',
      image: Assets.images.everLogo,
    ),
    PopularResources(
      name: 'EVER Pools',
      url: 'https://everpools.io',
      image: Assets.images.everLogo,
    ),
    PopularResources(
      name: 'CoinMarketCap',
      url: 'https://coinmarketcap.com',
      image: Assets.images.browser.coinmarketcap,
    ),
    PopularResources(
      name: 'CoinGecko',
      url: 'https://www.coingecko.com',
      image: Assets.images.browser.coingecko,
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      StreamProvider<AsyncValue<List<Bookmark>>>(
        create: (context) => context
            .read<BookmarksRepository>()
            .bookmarksStream
            .map((event) => AsyncValue.ready(event)),
        initialData: const AsyncValue.loading(),
        catchError: (context, error) => AsyncValue.error(error),
        builder: (context, child) {
          final bookmarks =
              context.watch<AsyncValue<List<Bookmark>>>().maybeWhen(
                    ready: (value) => value,
                    orElse: () => <Bookmark>[],
                  );
          final localization = context.localization;

          final children = <List<Widget>>[
            _sectionBuilder(
              AppLocalizations.of(context)!.popular_resources,
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 160 / 56,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                  ),
                  delegate: SliverChildListDelegate(
                    _popularResources.map(_popularResourceTile).toList(),
                  ),
                ),
              ),
            ),
            _sectionBuilder(
              AppLocalizations.of(context)!.bookmarks,
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: bookmarks.isEmpty
                    ? SliverToBoxAdapter(
                        child: Text(
                          AppLocalizations.of(context)!.bookmarks_placeholder,
                          style: StylesRes.captionText
                              .copyWith(color: ColorsRes.black),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 160 / 56,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 8,
                        ),
                        delegate: SliverChildListDelegate(
                            bookmarks.map(_bookmarkTile).toList()),
                      ),
              ),
            ),
          ];

          return CustomScrollView(
            slivers: [
              if (bookmarks.isEmpty) ...[
                ...children[0],
                ...children[1]
              ] else ...[
                ...children[1],
                ...children[0]
              ],
            ],
          );
        },
      );

  /// [child] must be a sliver
  List<Widget> _sectionBuilder(String title, Widget child) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                title,
                style: StylesRes.header2Faktum.copyWith(color: ColorsRes.black),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      child,
    ];
  }

  Widget _popularResourceTile(PopularResources resource) {
    return LongTapFocusableWidget(
      backgroundColor: ColorsRes.blue970,
      onTap: () => widget.changeUrl(resource.url),
      longTapEnabled: false,
      menuBuilder: null,
      child: _tileContent(
        resource.name,
        resource.image.svg(width: 32, height: 32),
      ),
    );
  }

  Widget _bookmarkTile(Bookmark bookmark) =>
      FutureProvider<AsyncValue<SiteMetaData>>(
        key: ValueKey(bookmark.id),
        create: (context) => context
            .read<SitesMetaDataRepository>()
            .getSiteMetaData(bookmark.url)
            .then((event) => AsyncValue.ready(event)),
        initialData: const AsyncValue.loading(),
        catchError: (context, error) => AsyncValue.error(error),
        builder: (context, child) {
          final meta = context.watch<AsyncValue<SiteMetaData>>().maybeWhen(
                ready: (value) => value,
                orElse: () => null,
              );

          final image = meta?.image;
          return LongTapFocusableWidget(
            backgroundColor: ColorsRes.blue970,
            child: _tileContent(
              bookmark.name.isEmpty
                  ? (meta?.title ?? bookmark.name)
                  : bookmark.name,
              image == null
                  ? const SizedBox.shrink()
                  : CircleAvatar(
                      child: image.endsWith('svg')
                          ? SvgPicture.network(
                              image,
                              width: 32,
                              height: 32,
                            )
                          : Image.network(
                              meta!.image!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                    ),
            ),
            onTap: () => widget.changeUrl(bookmark.url),
            menuBuilder: (context) => _bookmarkLongTapBuilder(
              context: context,
              url: bookmark.url,
              bookmarkId: bookmark.id,
              bookmarkName: bookmark.name,
            ),
          );
        },
      );

  Widget _tileContent(String title, Widget image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          image,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title.overflow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StylesRes.captionText.copyWith(
                color: ColorsRes.black,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoTile({
    required String title,
    required String description,
    required Widget icon,
    required List<Color> gradientColors,
    required String url,
  }) {
    assert(gradientColors.length == 2);
    return InkWell(
      onTap: () => launchUrlString(url),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.5, 0.8],
            colors: gradientColors,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: StylesRes.bold20.copyWith(color: ColorsRes.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: StylesRes.regular14.copyWith(color: ColorsRes.white),
                  ),
                ],
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }

  Widget _bookmarkLongTapBuilder({
    required BuildContext context,
    required String url,
    required String bookmarkName,
    required int bookmarkId,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EWListTile(
          leading: Assets.images.share.svg(color: ColorsRes.bluePrimary400),
          titleWidget: Text(
            context.localization.share,
            style: StylesRes.regular16.copyWith(color: ColorsRes.black),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Share.share(url);
          },
        ),
        EWListTile(
          leading: Assets.images.iconTrash.svg(color: ColorsRes.red400Primary),
          titleWidget: Text(
            context.localization.remove,
            style: StylesRes.regular16.copyWith(color: ColorsRes.red400Primary),
          ),
          onPressed: () {
            final bookRepo = context.read<BookmarksRepository>()
              ..deleteBookmark(bookmarkId);
            Navigator.of(context).pop();
            showFlushbarWithAction(
              context: this.context,
              text: context.localization.bookmark_removed,
              action: () => bookRepo.addBookmark(name: bookmarkName, url: url),
              actionText: context.localization.undo,
            );
          },
        ),
      ],
    );
  }
}
