import 'package:emam_admin_web_app/constants/app_constants.dart';
import 'package:emam_admin_web_app/constants/widget_constants.dart';
import 'package:flutter/material.dart';

class MobileScaffold extends StatefulWidget {
  const MobileScaffold({super.key});

  @override
  State<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends State<MobileScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      appBar: myAppBar,
      drawer: myDrawer,
    );
  }
}
