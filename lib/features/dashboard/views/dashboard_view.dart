import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_rounded,
              size: 64,
              color: AppConstants.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Emam Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select Contents from the sidebar to preview app content.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
