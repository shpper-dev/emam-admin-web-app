import 'package:emam_admin_web_app/core/responsive/desktop_scaffold.dart';
import 'package:emam_admin_web_app/core/responsive/mobile_scaffold.dart';
import 'package:emam_admin_web_app/core/responsive/responsive_layout.dart';
import 'package:emam_admin_web_app/core/responsive/tablet_scaffold.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.body,
    this.title = 'Admin Panel',
  });

  final Widget body;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => MobileScaffold(title: title, body: body),
      tablet: (_) => TabletScaffold(title: title, body: body),
      desktop: (_) => DesktopScaffold(body: body),
    );
  }
}
