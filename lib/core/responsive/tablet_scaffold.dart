import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/constants/widget_constants.dart';
import 'package:flutter/material.dart';

class TabletScaffold extends StatelessWidget {
  const TabletScaffold({
    super.key,
    required this.body,
    this.title = 'Admin Panel',
  });

  final Widget body;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}
