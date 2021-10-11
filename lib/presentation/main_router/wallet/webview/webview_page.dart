import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:crystal/domain/blocs/misc/bookmarks_bloc.dart';
import 'package:crystal/domain/models/web_metadata.dart';
import 'package:crystal/presentation/design/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../domain/blocs/account/accounts_bloc.dart';
import '../../../../domain/blocs/provider/approvals_bloc.dart';
import '../../../../injection.dart';
import '../../../../logger.dart';
import '../../../design/design.dart';
import '../../../design/utils.dart';
import 'account_selection.dart';
import 'approval_dialogs.dart';
import 'delegate.dart';

class WebviewPage extends StatefulWidget {
  @override
  _WebviewPageState createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  final accountsBloc = getIt.get<AccountsBloc>();
  final approvalsBloc = getIt.get<ApprovalsBloc>();
  final bookmarksBloc = getIt.get<BookmarksBloc>();
  InAppWebViewController? controller;
  late final StreamSubscription disconnectedStreamSubscription;
  late final StreamSubscription transactionsFoundStreamSubscription;
  late final StreamSubscription contractStateChangedStreamSubscription;
  late final StreamSubscription networkChangedStreamSubscription;
  late final StreamSubscription permissionsChangedStreamSubscription;
  late final StreamSubscription loggedOutStreamSubscription;
  final backButtonEnabled = ValueNotifier<bool>(false);
  final forwardButtonEnabled = ValueNotifier<bool>(false);
  final homePageShown = ValueNotifier<bool>(true);
  final urlController = TextEditingController();
  final onFocusChange = ValueNotifier<bool>(false);
  final isManaging = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    disconnectedStreamSubscription = disconnectedStream.listen((event) => disconnectedCaller(event));
    transactionsFoundStreamSubscription = transactionsFoundStream.listen((event) => transactionsFoundCaller(event));
    contractStateChangedStreamSubscription =
        contractStateChangedStream.listen((event) => contractStateChangedCaller(event));
    networkChangedStreamSubscription = networkChangedStream.listen((event) => networkChangedCaller(event));
    permissionsChangedStreamSubscription = permissionsChangedStream.listen((event) => permissionsChangedCaller(event));
    loggedOutStreamSubscription = loggedOutStream.listen((event) => loggedOutCaller(event));
  }

  @override
  void dispose() {
    accountsBloc.close();
    approvalsBloc.close();
    backButtonEnabled.dispose();
    forwardButtonEnabled.dispose();
    disconnectedStreamSubscription.cancel();
    transactionsFoundStreamSubscription.cancel();
    contractStateChangedStreamSubscription.cancel();
    networkChangedStreamSubscription.cancel();
    permissionsChangedStreamSubscription.cancel();
    loggedOutStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountsBloc, AccountsState>(
        bloc: accountsBloc,
        builder: (context, state) => state.maybeWhen(
          ready: (accounts, currentAccount) => currentAccount != null
              ? buildApprovalsListener(
                  accounts: accounts,
                  currentAccount: currentAccount,
                )
              : Center(
                  child: PlatformCircularProgressIndicator(),
                ),
          orElse: () => Center(
            child: PlatformCircularProgressIndicator(),
          ),
        ),
      );

  Widget buildApprovalsListener({
    required List<AssetsList> accounts,
    required AssetsList currentAccount,
  }) =>
      BlocListener<ApprovalsBloc, ApprovalsState>(
        bloc: approvalsBloc,
        listener: (context, state) async {
          state.maybeWhen(
            requested: (request) => request.when(
              requestPermissions: (origin, permissions, completer) => onRequestPermissions(
                origin: origin,
                permissions: permissions,
                completer: completer,
                address: currentAccount.address,
                publicKey: currentAccount.publicKey,
                walletType: currentAccount.tonWallet.contract,
              ),
              sendMessage: (origin, sender, recipient, amount, bounce, payload, knownPayload, completer) =>
                  onSendMessage(
                origin: origin,
                sender: sender,
                recipient: recipient,
                amount: amount,
                bounce: bounce,
                payload: payload,
                knownPayload: knownPayload,
                completer: completer,
              ),
              callContractMethod: (origin, selectedPublicKey, repackedRecipient, payload, completer) =>
                  onCallContractMethod(
                origin: origin,
                selectedPublicKey: selectedPublicKey,
                repackedRecipient: repackedRecipient,
                payload: payload,
                completer: completer,
              ),
            ),
            orElse: () => null,
          );
        },
        child: buildScaffold(
          accounts: accounts,
          currentAccount: currentAccount,
        ),
      );

  Widget buildScaffold({
    required List<AssetsList> accounts,
    required AssetsList currentAccount,
  }) =>
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Padding(
          padding: EdgeInsets.only(bottom: context.safeArea.bottom),
          child: CupertinoPageScaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: CrystalColor.iosBackground,
            child: SafeArea(
              bottom: false,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildTitle(
                      accounts: accounts,
                      currentAccount: currentAccount,
                    ),
                    Expanded(child: buildBody()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget buildTitle({
    required List<AssetsList> accounts,
    required AssetsList currentAccount,
  }) =>
      Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: onFocusChange,
            builder: (context, onFocusChangeValue, child) => onFocusChangeValue
                ? const SizedBox(
                    height: 48,
                    width: 24,
                  )
                : Wrap(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: backButtonEnabled,
                        builder: (context, value, child) => CupertinoButton(
                          onPressed: value ? () => controller?.goBack() : null,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            CupertinoIcons.back,
                            color: value ? CrystalColor.accent : CrystalColor.hintColor,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: forwardButtonEnabled,
                        builder: (context, value, child) => CupertinoButton(
                          onPressed: value ? () => controller?.goForward() : null,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            CupertinoIcons.forward,
                            color: value ? CrystalColor.accent : CrystalColor.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Theme(
              data: ThemeData(),
              child: Focus(
                onFocusChange: (value) {
                  onFocusChange.value = value;
                  homePageShown.value = value;
                },
                child: CupertinoTextField(
                  controller: urlController,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();

                    var url = urlController.text;

                    if (!url.startsWith("https://")) {
                      url = "https://$url";
                    }

                    try {
                      controller?.loadUrl(
                        urlRequest: URLRequest(
                          url: Uri.parse(url),
                        ),
                      );
                    } catch (_) {}
                  },
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: onFocusChange,
            builder: (context, onFocusChangeValue, child) => onFocusChangeValue
                ? const SizedBox.shrink()
                : ValueListenableBuilder<bool>(
                    valueListenable: homePageShown,
                    builder: (context, value, child) => CupertinoButton(
                      onPressed: !value
                          ? () => controller?.loadUrl(
                                urlRequest: URLRequest(url: Uri.parse("about:blank")),
                              )
                          : null,
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.home,
                        color: !value ? CrystalColor.accent : CrystalColor.hintColor,
                      ),
                    ),
                  ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              dividerTheme: const DividerThemeData(color: Colors.grey),
            ),
            child: PopupMenuButton<int>(
              color: CrystalColor.grayBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: const Icon(
                CupertinoIcons.ellipsis,
                color: CrystalColor.accent,
              ),
              itemBuilder: (context) => [
                buildPopupAccountMenuItem(
                  value: 0,
                  address: currentAccount.address,
                ),
                const PopupMenuDivider(),
                buildPopupMenuItem(
                  value: 1,
                  text: "Reload",
                ),
                const PopupMenuDivider(),
                buildPopupBookmarkMenuItem(
                  value: 2,
                ),
                const PopupMenuDivider(),
                buildPopupMenuItem(
                  value: 3,
                  text: "Share",
                ),
              ],
              onSelected: (item) => onItemSelected(
                item: item,
                accounts: accounts,
              ),
            ),
          ),
        ],
      );

  PopupMenuEntry<int> buildPopupAccountMenuItem({
    required int value,
    required String address,
  }) =>
      PopupMenuItem<int>(
        value: 0,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: getGravatarIcon(address.hashCode),
            ),
            const SizedBox(
              width: 8,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Account",
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  address.elipseAddress(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );

  PopupMenuEntry<int> buildPopupBookmarkMenuItem({
    required int value,
  }) =>
      PopupMenuItem<int>(
        value: value,
        child: BlocBuilder<BookmarksBloc, BookmarksState>(
          bloc: bookmarksBloc,
          builder: (context, state) => state.maybeWhen(
            ready: (bookmarks) => Text(
              !bookmarks.map((e) => e.url).contains(urlController.text) ? "Add bookmark" : "Remove bookmark",
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            orElse: () => const Text(
              "Add bookmark",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

  PopupMenuEntry<int> buildPopupMenuItem({
    required int value,
    required String text,
  }) =>
      PopupMenuItem<int>(
        value: value,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      );

  void onItemSelected({
    required int item,
    required List<AssetsList> accounts,
  }) {
    switch (item) {
      case 0:
        AccountSelection.open(
          context: context,
          accounts: accounts,
          onTap: (String address) async {
            accountsBloc.add(AccountsEvent.setCurrentAccount(address));
            await disconnect(origin: urlController.text);
          },
        );
        break;
      case 1:
        controller?.reload();
        break;
      case 2:
        bookmarksBloc.state.maybeWhen(
          ready: (bookmarks) {
            if (!bookmarks.map((e) => e.url).contains(urlController.text)) {
              bookmarksBloc.add(BookmarksEvent.addBookmark(urlController.text));
            } else {
              bookmarksBloc.add(BookmarksEvent.removeBookmark(urlController.text));
            }
          },
          orElse: () => null,
        );
        break;
      case 3:
        Share.share(urlController.text);
        break;
    }
  }

  Widget buildBody() => GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        behavior: HitTestBehavior.translucent,
        child: FutureBuilder<String>(
          future: loadMainScript(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ValueListenableBuilder<bool>(
                valueListenable: homePageShown,
                builder: (context, value, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Offstage(
                      offstage: value,
                      child: buildWebView(snapshot.data!),
                    ),
                    Offstage(
                      offstage: !value,
                      child: buildHomePage(),
                    ),
                  ],
                ),
              );
            } else {
              return Center(child: PlatformCircularProgressIndicator());
            }
          },
        ),
      );

  Widget buildWebView(String script) => InAppWebView(
        initialUserScripts: UnmodifiableListView<UserScript>([
          UserScript(
            source: script,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        ]),
        initialOptions: InAppWebViewGroupOptions(
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true,
          ),
        ),
        onWebViewCreated: onWebViewCreated,
        onLoadStop: onLoadStop,
        onConsoleMessage: onConsoleMessage,
      );

  Widget buildHomePage() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "BOOKMARKS",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isManaging,
                  builder: (context, value, child) => CupertinoButton(
                    onPressed: () => isManaging.value = !isManaging.value,
                    child: Text(!value ? "Manage" : "Done"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<BookmarksBloc, BookmarksState>(
              bloc: bookmarksBloc,
              builder: (context, state) => state.maybeWhen(
                ready: (bookmarks) => bookmarks.isNotEmpty ? buildBookmarks(bookmarks) : buildBookmarksPlaceholder(),
                orElse: () => const SizedBox(),
              ),
            ),
          ),
        ],
      );

  Widget buildBookmarksPlaceholder() => Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              CupertinoIcons.bookmark,
              size: 64,
            ),
          ),
          Text(
            "Your bookmarks will show up here",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      );

  Widget buildBookmarks(List<WebMetadata> bookmarks) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          height: 44,
        ),
        itemCount: bookmarks.length,
        itemBuilder: (context, index) => GridTile(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => controller?.loadUrl(
                    urlRequest: URLRequest(url: Uri.parse(bookmarks[index].url)),
                  ),
                  child: Row(
                    children: [
                      buildBookmarkIcon(
                        bookmarks: bookmarks,
                        index: index,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: buildBookmarkTitle(
                            bookmarks: bookmarks,
                            index: index,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              buildRemoveBookmarkButton(
                bookmarks: bookmarks,
                index: index,
              ),
            ],
          ),
        ),
      );

  Widget buildBookmarkIcon({
    required List<WebMetadata> bookmarks,
    required int index,
  }) =>
      bookmarks[index].icon != null && !bookmarks[index].icon!.contains("svg")
          ? SizedBox.square(
              dimension: 22,
              child: Image.network(bookmarks[index].icon!),
            )
          : const Icon(
              CupertinoIcons.globe,
              size: 22,
            );

  Widget buildBookmarkTitle({
    required List<WebMetadata> bookmarks,
    required int index,
  }) =>
      Text(
        bookmarks[index].title ?? bookmarks[index].url,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
        ),
      );

  Widget buildRemoveBookmarkButton({
    required List<WebMetadata> bookmarks,
    required int index,
  }) =>
      ValueListenableBuilder<bool>(
        valueListenable: isManaging,
        builder: (context, value, child) => CupertinoButton(
          onPressed: () => showCupertinoDialog(
            context: context,
            builder: (context) => Theme(
              data: ThemeData.light(),
              child: CupertinoAlertDialog(
                title: Text('Remove from Bookmarks?'),
                content: Text('Are you sure you want to remove ${bookmarks[index].title} from Bookmarks?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    onPressed: Navigator.of(context).pop,
                    child: Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      bookmarksBloc.add(BookmarksEvent.removeBookmark(bookmarks[index].url));
                      Navigator.of(context).pop();
                    },
                    textStyle: TextStyle(
                      color: Colors.red,
                    ),
                    child: Text(
                      'Remove',
                    ),
                  ),
                ],
              ),
            ),
          ),
          padding: EdgeInsets.zero,
          child: value
              ? const Icon(
                  CupertinoIcons.delete,
                  color: Colors.red,
                )
              : const SizedBox.shrink(),
        ),
      );

  void onWebViewCreated(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'requestPermissions',
      callback: requestPermissionsHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'disconnect',
      callback: disconnectHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'subscribe',
      callback: subscribeHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'unsubscribe',
      callback: unsubscribeHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'unsubscribeAll',
      callback: unsubscribeAllHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'getProviderState',
      callback: getProviderStateHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'getFullContractState',
      callback: getFullContractStateHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'getTransactions',
      callback: getTransactionsHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'runLocal',
      callback: runLocalHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'getExpectedAddress',
      callback: getExpectedAddressHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'packIntoCell',
      callback: packIntoCellHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'unpackFromCell',
      callback: unpackFromCellHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'extractPublicKey',
      callback: extractPublicKeyHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'codeToTvc',
      callback: codeToTvcHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'splitTvc',
      callback: splitTvcHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'encodeInternalInput',
      callback: encodeInternalInputHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'decodeInput',
      callback: decodeInputHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'decodeEvent',
      callback: decodeEventHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'decodeOutput',
      callback: decodeOutputHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'decodeTransaction',
      callback: decodeTransactionHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'decodeTransactionEvents',
      callback: decodeTransactionEventsHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'estimateFees',
      callback: estimateFeesHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'sendMessage',
      callback: sendMessageHandler,
    );

    controller.addJavaScriptHandler(
      handlerName: 'sendExternalMessage',
      callback: sendExternalMessageHandler,
    );
  }

  Future<void> onLoadStop(InAppWebViewController controller, Uri? url) async {
    this.controller = controller;

    backButtonEnabled.value = await this.controller?.canGoBack() ?? false;
    forwardButtonEnabled.value = await this.controller?.canGoForward() ?? false;

    final url = await this.controller?.getUrl();
    if (url != null) {
      homePageShown.value = url == Uri.parse("about:blank");
      urlController.value = TextEditingValue(
        text: url.toString(),
        selection: TextSelection.collapsed(offset: url.toString().length),
      );
    }
  }

  void onConsoleMessage(InAppWebViewController controller, ConsoleMessage consoleMessage) {
    if (consoleMessage.message == 'JavaScript execution returned a result of an unsupported type') {
      return;
    }

    if (consoleMessage.messageLevel == ConsoleMessageLevel.DEBUG) {
      logger.d(consoleMessage.message);
    } else if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
      logger.e(consoleMessage.message, consoleMessage.message);
    } else if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
      logger.d(consoleMessage.message);
    } else if (consoleMessage.messageLevel == ConsoleMessageLevel.TIP) {
      logger.d(consoleMessage.message);
    } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
      logger.w(consoleMessage.message);
    }
  }

  Future<void> onRequestPermissions({
    required String origin,
    required List<Permission> permissions,
    required Completer<Permissions> completer,
    required String address,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final result = await showRequestPermissionsDialog(
      context,
      origin: origin,
      permissions: permissions,
      address: address,
      publicKey: publicKey,
    );

    if (result) {
      var grantedPermissions = const Permissions();

      for (final permission in permissions) {
        switch (permission) {
          case Permission.tonClient:
            grantedPermissions = grantedPermissions.copyWith(tonClient: true);
            break;
          case Permission.accountInteraction:
            final contractType = walletType.when(
              multisig: (multisigType) {
                switch (multisigType) {
                  case MultisigType.safeMultisigWallet:
                    return WalletContractType.safeMultisigWallet;
                  case MultisigType.safeMultisigWallet24h:
                    return WalletContractType.safeMultisigWallet24h;
                  case MultisigType.setcodeMultisigWallet:
                    return WalletContractType.setcodeMultisigWallet;
                  case MultisigType.bridgeMultisigWallet:
                    return WalletContractType.bridgeMultisigWallet;
                  case MultisigType.surfWallet:
                    return WalletContractType.surfWallet;
                }
              },
              walletV3: () => WalletContractType.walletV3,
            );

            grantedPermissions = grantedPermissions.copyWith(
              accountInteraction: AccountInteraction(
                address: address,
                publicKey: publicKey,
                contractType: contractType,
              ),
            );
            break;
        }
      }

      completer.complete(grantedPermissions);
    } else {
      completer.completeError(Exception('Not granted'));
    }
  }

  Future<void> onSendMessage({
    required String origin,
    required String sender,
    required String recipient,
    required String amount,
    required bool bounce,
    required FunctionCall? payload,
    required KnownPayload? knownPayload,
    required Completer<String> completer,
  }) async {
    final result = await showSendMessageDialog(
      context,
      origin: origin,
      sender: sender,
      recipient: recipient,
      amount: amount,
      bounce: bounce,
      payload: payload,
      knownPayload: knownPayload,
    );

    if (result != null) {
      completer.complete(result);
    } else {
      completer.completeError(Exception('No password'));
    }
  }

  Future<void> onCallContractMethod({
    required String origin,
    required String selectedPublicKey,
    required String repackedRecipient,
    required FunctionCall payload,
    required Completer<String> completer,
  }) async {
    final result = await showCallContractMethodDialog(
      context,
      origin: origin,
      selectedPublicKey: selectedPublicKey,
      repackedRecipient: repackedRecipient,
      payload: payload,
    );

    if (result != null) {
      completer.complete(result);
    } else {
      completer.completeError(Exception('No password'));
    }
  }

  Future<void> disconnectedCaller(Error event) async {
    try {
      final jsonOutput = jsonEncode(event.toJson());
      logger.d('EVENT disconnected $jsonOutput');

      await controller?.evaluateJavascript(source: "window.__dartNotifications.disconnected('$jsonOutput')");
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<void> transactionsFoundCaller(TransactionsFoundEvent event) async {
    try {
      final jsonOutput = jsonEncode(event.toJson());
      logger.d('EVENT transactionsFound $jsonOutput');

      await controller?.evaluateJavascript(source: "window.__dartNotifications.transactionsFound('$jsonOutput')");
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<void> contractStateChangedCaller(ContractStateChangedEvent event) async {
    try {
      final jsonOutput = jsonEncode(event.toJson());
      logger.d('EVENT contractStateChanged $jsonOutput');

      await controller?.evaluateJavascript(source: "window.__dartNotifications.contractStateChanged('$jsonOutput')");
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<void> networkChangedCaller(NetworkChangedEvent event) async {
    try {
      final jsonOutput = jsonEncode(event.toJson());
      logger.d('EVENT networkChanged $jsonOutput');

      await controller?.evaluateJavascript(source: "window.__dartNotifications.networkChanged('$jsonOutput')");
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<void> permissionsChangedCaller(PermissionsChangedEvent event) async {
    try {
      final jsonOutput = jsonEncode(event.toJson());
      logger.d('EVENT permissionsChanged $jsonOutput');

      await controller?.evaluateJavascript(source: "window.__dartNotifications.permissionsChanged('$jsonOutput')");
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<void> loggedOutCaller(Object event) async {
    try {
      logger.d('EVENT loggedOut');

      await controller?.evaluateJavascript(source: 'window.__dartNotifications.loggedOut()');
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> codeToTvcHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST codeToTvc args $jsonInput');

      final input = CodeToTvcInput.fromJson(jsonInput);

      final output = await codeToTvc(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST codeToTvc result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> decodeEventHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST decodeEvent args $jsonInput');

      final input = DecodeEventInput.fromJson(jsonInput);

      final output = await decodeEvent(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output?.toJson());
      logger.d('REQUEST decodeEvent result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> decodeInputHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST decodeInput args $jsonInput');

      final input = DecodeInputInput.fromJson(jsonInput);

      final output = await decodeInput(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output?.toJson());
      logger.d('REQUEST decodeInput result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> decodeOutputHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST decodeOutput args $jsonInput');

      final input = DecodeOutputInput.fromJson(jsonInput);

      final output = await decodeOutput(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output?.toJson());
      logger.d('REQUEST decodeOutput result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> decodeTransactionEventsHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST decodeTransactionEvents args $jsonInput');

      final input = DecodeTransactionEventsInput.fromJson(jsonInput);

      final output = await decodeTransactionEvents(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST decodeTransactionEvents result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> decodeTransactionHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST decodeTransaction args $jsonInput');

      final input = DecodeTransactionInput.fromJson(jsonInput);

      final output = await decodeTransaction(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output?.toJson());
      logger.d('REQUEST decodeTransaction result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> disconnectHandler(List<dynamic> args) async {
    try {
      await disconnect(
        origin: urlController.text,
      );

      final jsonOutput = jsonEncode({});
      logger.d('REQUEST disconnect result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> encodeInternalInputHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST encodeInternalInput args $jsonInput');

      final input = EncodeInternalInputInput.fromJson(jsonInput);

      final output = await encodeInternalInput(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST encodeInternalInput result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> estimateFeesHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST estimateFees args $jsonInput');

      final input = EstimateFeesInput.fromJson(jsonInput);

      final output = await estimateFees(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST estimateFees result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> extractPublicKeyHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST extractPublicKey args $jsonInput');

      final input = ExtractPublicKeyInput.fromJson(jsonInput);

      final output = await extractPublicKey(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST extractPublicKey result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> getExpectedAddressHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST getExpectedAddress args $jsonInput');

      final input = GetExpectedAddressInput.fromJson(jsonInput);

      final output = await getExpectedAddress(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST getExpectedAddress result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> getFullContractStateHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST getFullContractState args $jsonInput');

      final input = GetFullContractStateInput.fromJson(jsonInput);

      final output = await getFullContractState(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST getFullContractState result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> getProviderStateHandler(List<dynamic> args) async {
    try {
      final output = await getProviderState(
        origin: urlController.text,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST getProviderState result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> getTransactionsHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST getTransactions args $jsonInput');

      final input = GetTransactionsInput.fromJson(jsonInput);

      final output = await getTransactions(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST getTransactions result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> packIntoCellHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST packIntoCell args $jsonInput');

      final input = PackIntoCellInput.fromJson(jsonInput);

      final output = await packIntoCell(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST packIntoCell result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> requestPermissionsHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST requestPermissions args $jsonInput');

      final input = RequestPermissionsInput.fromJson(jsonInput);

      final output = await requestPermissions(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST requestPermissions result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> runLocalHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST runLocal args $jsonInput');

      final input = RunLocalInput.fromJson(jsonInput);

      final output = await runLocal(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST runLocal result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> sendExternalMessageHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST sendExternalMessage args $jsonInput');

      final input = SendExternalMessageInput.fromJson(jsonInput);

      final output = await sendExternalMessage(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST sendExternalMessage result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> sendMessageHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST sendMessage args $jsonInput');

      final input = SendMessageInput.fromJson(jsonInput);

      final output = await sendMessage(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST sendMessage result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> splitTvcHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST splitTvc args $jsonInput');

      final input = SplitTvcInput.fromJson(jsonInput);

      final output = await splitTvc(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST splitTvc result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> subscribeHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST subscribe args $jsonInput');

      final input = SubscribeInput.fromJson(jsonInput);

      final output = await subscribe(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST subscribe result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> unpackFromCellHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST unpackFromCell args $jsonInput');

      final input = UnpackFromCellInput.fromJson(jsonInput);

      final output = await unpackFromCell(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode(output.toJson());
      logger.d('REQUEST unpackFromCell result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> unsubscribeAllHandler(List<dynamic> args) async {
    try {
      await unsubscribeAll(
        origin: urlController.text,
      );

      final jsonOutput = jsonEncode({});
      logger.d('REQUEST unsubscribeAll result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }

  Future<dynamic> unsubscribeHandler(List<dynamic> args) async {
    try {
      final jsonInput = args.first as Map<String, dynamic>;
      logger.d('REQUEST unsubscribe args $jsonInput');

      final input = UnsubscribeInput.fromJson(jsonInput);

      await unsubscribe(
        origin: urlController.text,
        input: input,
      );

      final jsonOutput = jsonEncode({});
      logger.d('REQUEST unsubscribe result $jsonOutput');

      return jsonOutput;
    } catch (err, st) {
      logger.e(err, err, st);
    }
  }
}
