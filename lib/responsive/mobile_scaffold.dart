import 'package:emam_admin_web_app/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        title: Text(
          'Emam Admin Panel',
          style: GoogleFonts.aBeeZee(color: AppConstants.primary),
        ),
        iconTheme: IconThemeData(color: AppConstants.primary),
        backgroundColor: AppConstants.bgColor,
      ),
      drawer: Drawer(
        backgroundColor: AppConstants.bgColor,
        child: ListView(
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.only(top: 24),
              child: Image.asset(AppConstants.emamLogo),
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard_rounded,
                color: AppConstants.primary,
              ),
              title: Text(
                'D A S H B O A R D',
                style: GoogleFonts.aBeeZee(color: AppConstants.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
