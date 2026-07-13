import 'package:emam_admin_web_app/features/content/models/content_snapshot.dart';
import 'package:emam_admin_web_app/features/content/provider/content_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contentProvider =
    AsyncNotifierProvider<ContentNotifier, ContentSnapshot>(ContentNotifier.new);

class ContentNotifier extends AsyncNotifier<ContentSnapshot> {
  @override
  Future<ContentSnapshot> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<ContentSnapshot> _load() {
    return ref.read(contentRepositoryProvider).fetchAll();
  }
}
