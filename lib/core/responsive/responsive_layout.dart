import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 1200,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < mobileBreakpoint) {
          return mobile(context);
        } else if (width < tabletBreakpoint) {
          return (tablet ?? mobile)(context);
        } else {
          return desktop(context);
        }
      },
    );
  }
}
