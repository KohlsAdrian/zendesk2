import 'package:flutter/material.dart';
import 'package:zendesk2/zendesk2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Press on FAB to start chat'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.chat),
          onPressed: () async {
            String accountKey = '';
            String appId = '';

            String name = '';
            String email = '';
            String phoneNumber = '';

            await Zendesk2.logger(true);
            await Zendesk2.init(accountKey, appId);
            await Zendesk2.customize(
              departmentFieldStatus: PRE_CHAT_FIELD_STATUS.REQUIRED,
              nameFieldStatus: PRE_CHAT_FIELD_STATUS.REQUIRED,
              emailFieldStatus: PRE_CHAT_FIELD_STATUS.REQUIRED,
              phoneFieldStatus: PRE_CHAT_FIELD_STATUS.REQUIRED,
              transcriptChatEnabled: true,
              agentAvailability: true,
              endChatEnabled: true,
              offlineForms: false,
              preChatForm: true,
              transcript: true,
            );
            await Zendesk2.setVisitorInfo(
              name: name,
              email: email,
              phoneNumber: phoneNumber,
              departmentName: 'Suporte IZA',
              tags: ['app', 'zendesk2_plugin'],
            );

            await Zendesk2.startChat();
          },
        ),
      ),
    );
  }
}
