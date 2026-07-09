import 'package:emam_admin_web_app/core/responsive/desktop_scaffold.dart';
import 'package:emam_admin_web_app/core/responsive/mobile_scaffold.dart';
import 'package:emam_admin_web_app/core/responsive/responsive_layout.dart';
import 'package:emam_admin_web_app/core/responsive/tablet_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      mobile: (_) => const MobileScaffold(),
      tablet: (_) => const TabletScaffold(),
      desktop: (_) => const DesktopScaffold(),
    );
  }
}
