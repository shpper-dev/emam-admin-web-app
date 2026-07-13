import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/constants/widget_constants.dart';
import 'package:emam_admin_web_app/core/extension/widget_extension.dart';
import 'package:flutter/material.dart';

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppDrawer().paddingOnly(left: 28),
          Container(
            width: 1,
            color: Colors.grey.shade900,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
