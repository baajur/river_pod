import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

import 'internal.dart';

class ProviderScope extends StatefulWidget {
  const ProviderScope({
    Key key,
    this.overrides = const [],
    @required this.child,
  })  : assert(child != null, 'child cannot be `null`'),
        super(key: key);

  @visibleForTesting
  final Widget child;

  @visibleForTesting
  final List<ProviderOverride<ProviderBaseSubscription, Object>> overrides;

  @override
  _ProviderScopeState createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  ProviderStateOwner _owner;
  var _dirty = false;

  @override
  void didUpdateWidget(ProviderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _owner.updateOverrides(widget.overrides);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO throw if ancestorOwner changed
    final ancestorOwner = context
        .dependOnInheritedWidgetOfExactType<ProviderStateOwnerScope>()
        ?.owner;

    _owner ??= ProviderStateOwner(
      parent: ancestorOwner,
      overrides: widget.overrides,
      markNeedsUpdate: () => setState(() => _dirty = true),
      // TODO How to report to FlutterError?
      // onError: (dynamic error, stack) {
      //   FlutterError.reportError(
      //     FlutterErrorDetails(
      //       library: 'flutter_provider',
      //       exception: error,
      //       stack: stack,
      //     ),
      //   );
      // },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dirty) {
      // TODO test
      _dirty = false;
      _owner.updateOverrides();
    }
    return ProviderStateOwnerScope(
      owner: _owner,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _owner.dispose();
    super.dispose();
  }
}

class ProviderStateOwnerScope extends InheritedWidget {
  const ProviderStateOwnerScope({
    Key key,
    @required this.owner,
    Widget child,
  })  : assert(owner != null, 'ProviderStateOwner cannot be null'),
        super(key: key, child: child);

  static ProviderStateOwner of(BuildContext context, {bool listen = true}) {
    ProviderStateOwnerScope scope;

    if (listen) {
      scope = context //
          .dependOnInheritedWidgetOfExactType<ProviderStateOwnerScope>();
    } else {
      scope = context
          .getElementForInheritedWidgetOfExactType<ProviderStateOwnerScope>()
          .widget as ProviderStateOwnerScope;
    }

    if (scope == null) {
      throw StateError('No ProviderScope found');
    }

    return scope.owner;
  }

  final ProviderStateOwner owner;

  @override
  bool updateShouldNotify(ProviderStateOwnerScope oldWidget) {
    return owner != oldWidget.owner;
  }
}
