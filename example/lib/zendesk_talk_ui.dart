import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:zendesk2/zendesk2.dart';

class ZendeskTalkUI extends StatefulWidget {
  _ZendeskTalkUI createState() => _ZendeskTalkUI();
}

class _ZendeskTalkUI extends State<ZendeskTalkUI> {
  ZendeskTalk _z = ZendeskTalk.instance;

  StreamSubscription<TalkProviderModel>? _availabilityStream;
  StreamSubscription<TalkCallProviderModel>? _talkCallStream;

  TalkProviderModel? _talkProviderModel;
  TalkCallProviderModel? _talkCallProviderModel;
  TalkPermission _talkPermission = TalkPermission.UNKNOWN;
  Iterable<TalkCallAudioRoutingOptionModel> _availableAudioRoutingOptions = [];
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback(
      (_) async {
        _availabilityStream = _z.availabilityStream.listen((talkProviderModel) {
          setState(() => _talkProviderModel = talkProviderModel);
          _getStatus();
        });
        _talkCallStream = _z.talkCallStream?.listen((talkCallProviderModel) {
          setState(() => _talkCallProviderModel = talkCallProviderModel);
          _getStatus();
        });
        _getStatus();
      },
    );
  }

  Future<bool> _onWillPopScope() async {
    _availabilityStream?.cancel();
    _talkCallStream?.cancel();
    _z.disconnect();
    _z.dispose();
    return true;
  }

  void _getStatus() async {
    await _z.checkAvailability('digital_line');
    _talkPermission = await _z.getRecordingPermission();
    _availableAudioRoutingOptions = await _z.getAvailableAudioRoutingOptions();
    setState(() {});
  }

  void _call() async => await _z.call('digital_line', TalkConsent.OPT_IN);
  void _disconnect() => _z.disconnect();

  void _toggleMute() async => _isMuted = await _z.toggleMute();
  void _toggleOutput() async => _isSpeaker = await _z.toggleOutput();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopScope,
      child: Scaffold(
        appBar: AppBar(title: Text('Talk SDK')),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_talkCallProviderModel != null &&
                      _talkCallProviderModel!.talkStatus ==
                          TalkStatus.CONNECTED)
                    FloatingActionButton.extended(
                      label: Text('Disconnect'),
                      icon: Icon(Icons.phone_disabled),
                      onPressed: _disconnect,
                    )
                  else
                    FloatingActionButton.extended(
                      label: Text('Call'),
                      icon: Icon(Icons.phone),
                      onPressed: _call,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Divider(),
                  ),
                  if (_talkCallProviderModel != null &&
                      _talkCallProviderModel!.talkStatus ==
                          TalkStatus.CONNECTED)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleOutput,
                          icon: Icon(_isSpeaker
                              ? Icons.phone_android
                              : Icons.headphones),
                          label: Text('Toggle Output'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _toggleMute,
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                          ),
                          label: Text('Toggle Mute'),
                        ),
                      ],
                    )
                ],
              ),
            ),
            if (_talkProviderModel != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agent Available: ${_talkProviderModel!.isAgentAvailable}\n'
                    'Consent: ${_talkProviderModel!.consent}\n'
                    'Talk Permission: $_talkPermission',
                    textAlign: TextAlign.center,
                  ),
                  Column(
                    children: [
                      if (_talkCallProviderModel != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                              'Call Status: ${_talkCallProviderModel!.talkStatus}'),
                        ),
                      Container(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _availableAudioRoutingOptions
                              .map((e) => Text(e.name))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
