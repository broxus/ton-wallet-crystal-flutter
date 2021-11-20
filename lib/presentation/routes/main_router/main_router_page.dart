import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../../../../../domain/blocs/account/accounts_bloc.dart';
import '../../../../../../logger.dart';
import '../../design/design.dart';
import '../router.gr.dart';

class MainRouterPage extends StatefulWidget {
  const MainRouterPage({Key? key}) : super(key: key);

  @override
  _MainRouterPageState createState() => _MainRouterPageState();
}

class _MainRouterPageState extends State<MainRouterPage> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(handleAndroidBackButton);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(handleAndroidBackButton);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async => handleAndroidBackButton(),
        child: AutoTabsScaffold(
          lazyLoad: false,
          routes: const [
            WalletRouterRoute(),
            WebviewRoute(),
            SettingsRouterRoute(),
          ],
          animationDuration: Duration.zero,
          builder: (context, page, animation) => page,
          bottomNavigationBuilder: (context, router) => bottomNavigationBar(router),
        ),
      );

  Widget bottomNavigationBar(TabsRouter router) => CupertinoTheme(
        data: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            tabLabelTextStyle: TextStyle(
              fontFamily: FontFamily.pt,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
        child: PlatformNavBar(
          currentIndex: router.activeIndex,
          itemChanged: (index) => itemChanged(
            index: index,
            router: router,
          ),
          backgroundColor: CrystalColor.navigationBarBackground,
          material: (context, target) => MaterialNavBarData(
            selectedItemColor: CrystalColor.fontHeaderDark,
            unselectedItemColor: const Color(0xFFC4C4C4),
          ),
          cupertino: (context, target) => CupertinoTabBarData(
            activeColor: CrystalColor.fontHeaderDark,
            inactiveColor: const Color(0xFFC4C4C4),
          ),
          items: [
            item(
              image: Assets.images.wallet,
              label: LocaleKeys.wallet_screen_title.tr(),
            ),
            item(
              image: Assets.images.browser,
              label: LocaleKeys.browser_title.tr(),
            ),
            item(
              image: Assets.images.profile,
              label: 'Profile',
            ),
          ],
        ),
      );

  Future<void> itemChanged({
    required int index,
    required TabsRouter router,
  }) async {
    if (index == 1) {
      final exist = await checkForExistingAccount(index);

      if (!exist) {
        showAddAccountDialog();
        return;
      }
    }

    if (index == router.activeIndex) {
      switch (index) {
        case 0:
          router.navigate(const WalletRouterRoute());
          break;
        case 1:
          router.navigate(const WebviewRoute());
          break;
        case 2:
          router.navigate(const SettingsRouterRoute());
          break;
      }
    } else {
      router.setActiveIndex(index);
    }
  }

  BottomNavigationBarItem item({
    required SvgGenImage image,
    required String label,
  }) =>
      BottomNavigationBarItem(
        icon: image.svg(
          width: 24,
          height: 24,
        ),
        activeIcon: image.svg(
          width: 24,
          height: 24,
          color: CrystalColor.fontHeaderDark,
        ),
        label: label,
      );

  Future<bool> checkForExistingAccount(int index) async {
    final bloc = context.read<AccountsBloc>();

    final state = bloc.state;

    if (state.currentAccount == null && state.accounts.isNotEmpty) {
      bloc.add(AccountsEvent.setCurrent(state.accounts.firstOrNull?.address));

      try {
        await bloc.stream.first.timeout(const Duration(seconds: 1));
      } catch (err, st) {
        logger.e(err, err, st);
        return false;
      }
    }

    return bloc.state.currentAccount != null;
  }

  Future<void> showAddAccountDialog() => showPlatformDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) => Theme(
          data: ThemeData(),
          child: PlatformAlertDialog(
            title: const Text('Add account'),
            content: const Text('To use the browser you need to add an account first'),
            actions: [
              PlatformDialogAction(
                onPressed: () async {
                  await context.router.pop();

                  final mainRouterRouter = context.router.root.innerRouterOf(MainRouterRoute.name);
                  final walletRouterRouter = mainRouterRouter?.innerRouterOf(WalletRouterRoute.name);

                  mainRouterRouter?.navigate(const WalletRouterRoute());
                  walletRouterRouter?.navigate(const NewAccountRouterRoute());
                },
                cupertino: (_, __) => CupertinoDialogActionData(
                  isDefaultAction: true,
                ),
                child: const Text('Add account'),
              ),
            ],
          ),
        ),
      );

  bool handleAndroidBackButton([bool? stopDefaultButtonEvent, RouteInfo? routeInfo]) {
    try {
      final router = context.innerRouterOf(MainRouterRoute.name)! as TabsRouter;
      final currentIndex = router.activeIndex;
      if (currentIndex == 0) return false;
      router.setActiveIndex(0);
    } catch (err, st) {
      logger.e(err, err, st);
    }

    return true;
  }
}
