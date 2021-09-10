import 'package:zendesk2/zendesk2.dart';

class TalkProviderModel {
  final bool isAgentAvailable;
  final TalkConsent consent;
  final String? error;

  TalkProviderModel(
    this.isAgentAvailable,
    this.consent,
    this.error,
  );

  factory TalkProviderModel.fromJson(Map json) {
    bool isAgentAvailable = json['isAgentAvailable'];

    final recordingConsent = json['recordingConsent'];
    TalkConsent consent = TalkConsent.UNKNOWN;

    switch (recordingConsent) {
      case 'OPT_IN':
        consent = TalkConsent.OPT_IN;
        break;
      case 'OPT_OUT':
        consent = TalkConsent.OPT_OUT;
        break;
      default:
        consent = TalkConsent.UNKNOWN;
        break;
    }

    String? error = json['error'];
    return TalkProviderModel(
      isAgentAvailable,
      consent,
      error,
    );
  }
}

class TalkCallProviderModel {
  final TalkStatus talkStatus;
  final String? error;

  TalkCallProviderModel(
    this.talkStatus,
    this.error,
  );

  factory TalkCallProviderModel.fromJson(Map json) {
    String? error = json['error'];

    String mCallStatus = json['callStatus'];
    TalkStatus talkStatus = TalkStatus.UNKNOWN;
    switch (mCallStatus) {
      case 'CONNECTING':
        talkStatus = TalkStatus.CONNECTING;
        break;
      case 'CONNECTED':
        talkStatus = TalkStatus.CONNECTED;
        break;
      case 'DISCONNECTED':
        talkStatus = TalkStatus.DISCONNECTED;
        break;
      case 'FAILED':
        talkStatus = TalkStatus.FAILED;
        break;
      case 'RECONNECTING':
        talkStatus = TalkStatus.RECONNECTING;
        break;
      case 'RECONNECTED':
        talkStatus = TalkStatus.RECONNECTED;
        break;
      default:
        talkStatus = TalkStatus.UNKNOWN;
        break;
    }

    return TalkCallProviderModel(
      talkStatus,
      error,
    );
  }
}

class TalkCallAudioRoutingOptionModel {
  final String name;
  final TalkAudioRoutingOption audioRoutingOption;

  TalkCallAudioRoutingOptionModel(
    this.name,
    this.audioRoutingOption,
  );

  factory TalkCallAudioRoutingOptionModel.fromJson(Map json) {
    String name = json['name'];
    String type = json['type'];

    TalkAudioRoutingOption audioRoutingOption = TalkAudioRoutingOption.UNKNOWN;
    switch (type) {
      case 'BLUETOOTH':
        audioRoutingOption = TalkAudioRoutingOption.BLUETOOTH;
        break;
      case 'BUILT_IN':
        audioRoutingOption = TalkAudioRoutingOption.BUILT_IN;
        break;
      default:
        break;
    }

    return TalkCallAudioRoutingOptionModel(
      name,
      audioRoutingOption,
    );
  }
}
