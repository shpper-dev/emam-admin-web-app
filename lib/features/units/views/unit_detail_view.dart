import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One unit on its own page, for screens too narrow for the side panel.
class UnitDetailView extends StatelessWidget {
  const UnitDetailView({super.key, required this.installId});

  final String installId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = contentHorizontalPadding(constraints.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(RoutePaths.units),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to units'),
                ),
              ),
              const SizedBox(height: 8),
              UnitDetailPanel(installId: installId),
            ],
          ),
        );
      },
    );
  }
}
