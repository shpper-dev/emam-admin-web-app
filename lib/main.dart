import 'package:emam_admin_web_app/responsive/desktop_scaffold.dart';
import 'package:emam_admin_web_app/responsive/mobile_scaffold.dart';
import 'package:emam_admin_web_app/responsive/responsive_layout.dart';
import 'package:emam_admin_web_app/responsive/tablet_scaffold.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ResponsiveLayout(
        mobile: (context) => const MobileScaffold(),
        tablet: (context) => const TabletScaffold(),
        desktop: (context) => const DesktopScaffold(),
      ),
    );
  }
}
