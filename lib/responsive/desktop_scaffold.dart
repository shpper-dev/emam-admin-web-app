import 'package:emam_admin_web_app/constants/app_constants.dart';
import 'package:emam_admin_web_app/constants/widget_constants.dart';
import 'package:emam_admin_web_app/extension/widget_extension.dart';
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
          myDrawer.paddingOnly(left: 28),

          // Vertical Divider
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.grey.shade900,
          ),

          // Rest of the body
        ],
      ),
    );
  }
}
