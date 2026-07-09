import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/constants/widget_constants.dart';
import 'package:emam_admin_web_app/core/extension/widget_extension.dart';
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
          const AppDrawer().paddingOnly(left: 28),
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.grey.shade900,
          ),
        ],
      ),
    );
  }
}
