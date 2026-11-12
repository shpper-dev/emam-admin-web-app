import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IssuedCodes {
  const IssuedCodes({required this.codes, required this.label});

  final List<String> codes;
  final String label;
}

/// The codes from the last "Create codes", kept in memory until dismissed:
/// the server never shows them again.
final activationCodesProvider =
    NotifierProvider<ActivationCodesNotifier, IssuedCodes?>(
      ActivationCodesNotifier.new,
    );

class ActivationCodesNotifier extends Notifier<IssuedCodes?> {
  @override
  IssuedCodes? build() => null;

  /// Throws on failure so the caller can show the error.
  Future<void> create({required int count, required String label}) async {
    final codes = await ref
        .read(unitsRepositoryProvider)
        .createActivationCodes(count: count, label: label);
    if (ref.mounted) state = IssuedCodes(codes: codes, label: label.trim());
  }

  void dismiss() => state = null;
}
