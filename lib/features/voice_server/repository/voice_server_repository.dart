import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/voice_server/models/voice_server_status.dart';

class VoiceServerRepository {
  VoiceServerRepository(this._client);

  final DioClient _client;

  Future<VoiceServerStatus> fetchStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.voiceServer,
    );
    return VoiceServerStatus.fromJson(response.data ?? {});
  }

  Future<VoiceServerStatus> turnOn() => _switch('start');

  Future<VoiceServerStatus> turnOff() => _switch('stop');

  Future<VoiceServerStatus> _switch(String action) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.voiceServerSwitch(action),
    );
    return VoiceServerStatus.fromJson(response.data ?? {});
  }
}
