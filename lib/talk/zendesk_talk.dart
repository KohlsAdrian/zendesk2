import 'package:zendesk2/zendesk2.dart';

class ZendeskTalk {
  ZendeskTalk._() {
    _channel.setMethodCallHandler(
      (call) async {
        try {
          final arguments = call.arguments;
          switch (call.method) {
            case 'sendTalkAvailability':
              TalkProviderModel talkProviderModel =
                  TalkProviderModel.fromJson(arguments);
              break;
            case 'sendTalkCall':
              TalkCallProviderModel talkCallProviderModel =
                  TalkCallProviderModel.fromJson(arguments);
              break;
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }
  static final ZendeskTalk instance = ZendeskTalk._();

  static final _channel = Zendesk.instance.channel;

  Future<TalkPermission> getRecordingPermission() async {
    TalkPermission talkPermission = TalkPermission.UNKNOWN;
    try {
      final result = await _channel.invokeMethod('talk_recording_permission');
      switch (result['talkPermission']) {
        case 'UNDETERMINED':
          talkPermission = TalkPermission.UNDETERMINED;
          break;
        case 'DENIED':
          talkPermission = TalkPermission.DENIED;
          break;
        case 'GRANTED':
          talkPermission = TalkPermission.GRANTED;
          break;
        default:
          talkPermission = TalkPermission.UNKNOWN;
          break;
      }
    } catch (e) {
      print(e);
    }
    return talkPermission;
  }

  Future<void> checkAvailability(String digitalLineName) async {
    try {
      final arguments = {
        'digitalLineName': digitalLineName,
      };
      await _channel.invokeMethod('talk_check_availability', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> call(String digitalLineName, TalkConsent talkConsent) async {
    try {
      final arguments = {
        'digitalLineName': digitalLineName,
        'recordingConsentAnswer': talkConsent.toString().split('.').last,
      };
      await _channel.invokeMethod('talk_call', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<bool> toggleMute() async {
    bool isMuted = false;
    try {
      final result = await _channel.invokeMethod('talk_toggle_mute');
      isMuted = result['isMuted'] ?? false;
    } catch (e) {
      print(e);
    }
    return isMuted;
  }

  Future<bool> toggleOutput() async {
    bool isSpeaker = false;
    try {
      final result = await _channel.invokeMethod('talk_toggle_output');
      isSpeaker = result['isSpeaker'] ?? false;
    } catch (e) {
      print(e);
    }
    return isSpeaker;
  }

  Future<Iterable<TalkCallAudioRoutingOptionModel>>
      getAvailableAudioRoutingOptions() async {
    Iterable<TalkCallAudioRoutingOptionModel> audioRoutingOptions = [];
    try {
      final result =
          await _channel.invokeMethod('talk_available_audio_routing_options');

      final options = result['availableAudioRoutingOptions'] ?? [];
      audioRoutingOptions = (options as Iterable)
          .map((e) => TalkCallAudioRoutingOptionModel.fromJson(e));
    } catch (e) {
      print(e);
    }
    return audioRoutingOptions;
  }
}
