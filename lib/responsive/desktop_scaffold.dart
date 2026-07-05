import 'package:emam_admin_web_app/constants/app_constants.dart';
import 'package:emam_admin_web_app/constants/widget_constants.dart';
import 'package:flutter/material.dart';

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Row(
        children: [
          // Open Drawer
          Padding(padding: const EdgeInsets.only(left: 32), child: myDrawer),

          // Rest of the body
        ],
      ),
    );
  }
}
