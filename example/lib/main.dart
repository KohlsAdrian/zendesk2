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
  void zendesk() async {
    String accountKey = '';
    String appId = '';

    String name = '';
    String email = '';
    String phoneNumber = '';

    Zendesk2Chat z = Zendesk2Chat.instance;

    await z.init(
      accountKey,
      appId,
      iosThemeColor: Color(0xFFFF5148),
    );

    await z.customize(
      departmentFieldStatus: PRE_CHAT_FIELD_STATUS.HIDDEN,
      emailFieldStatus: PRE_CHAT_FIELD_STATUS.HIDDEN,
      nameFieldStatus: PRE_CHAT_FIELD_STATUS.HIDDEN,
      phoneFieldStatus: PRE_CHAT_FIELD_STATUS.HIDDEN,
      transcriptChatEnabled: true,
      agentAvailability: false,
      endChatEnabled: true,
      offlineForms: true,
      preChatForm: true,
      transcript: true,
    );

    await z.setVisitorInfo(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      tags: ['app', 'zendesk2_plugin'],
    );

    await z.logger(true);

    await z.startChat(
      toolbarTitle: 'Fale Conosco',
      backButtonLabel: 'Voltar',
      botLabel: 'bip bop boting',
    );
  }

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
          onPressed: zendesk,
        ),
      ),
    );
  }
}
