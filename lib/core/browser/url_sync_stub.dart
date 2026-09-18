import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Native platforms: browser URL sync does not apply — pass the child through.
class UrlSync extends StatefulWidget {
  const UrlSync({super.key, required this.router, required this.child});

  final GoRouter router;

  final Widget child;

  @override
  State<UrlSync> createState() => _UrlSyncStateStub();
}

class _UrlSyncStateStub extends State<UrlSync> {
  @override
  Widget build(BuildContext context) => widget.child;
}
