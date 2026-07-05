import 'package:emam_admin_web_app/constants/app_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var myAppBar = AppBar(
  title: Text(
    'Admin Panel',
    style: GoogleFonts.aBeeZee(color: AppConstants.primary),
  ),
  iconTheme: IconThemeData(color: AppConstants.primary),
  backgroundColor: AppConstants.bgColor,
);

var myDrawer = Drawer(
  backgroundColor: AppConstants.bgColor,
  child: ListView(
    children: [
      Container(
        height: 180,
        padding: const EdgeInsets.only(top: 24),
        child: Image.asset(AppConstants.emamLogo),
      ),
      ListTile(
        leading: Icon(Icons.dashboard_rounded, color: AppConstants.primary),
        title: Text(
          'D A S H B O A R D',
          style: GoogleFonts.aBeeZee(color: AppConstants.primary),
        ),
      ),
      ListTile(
        leading: Icon(
          CupertinoIcons.arrow_left_square_fill,
          color: AppConstants.primary,
        ),
        title: Text(
          'L O G O U T',
          style: GoogleFonts.aBeeZee(color: AppConstants.primary),
        ),
      ),
    ],
  ),
);
