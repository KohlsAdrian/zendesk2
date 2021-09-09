import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zendesk2/zendesk2.dart';
import 'package:zendesk2_example/zendesk_answer_ui.dart';
import 'package:zendesk2_example/zendesk_chat_ui.dart';
import 'package:zendesk2_example/zendesk_talk_ui.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.indigo,
        ),
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  final z = Zendesk.instance;

  String accountKey = '';
  String appId = '';
  String clientId = '';
  String zendeskUrl = '';

  void chat() async {
    String name = '';
    String email = '';
    String phoneNumber = '';

    await z.initChatSDK(accountKey, appId);

    Zendesk2Chat zChat = Zendesk2Chat.instance;

    await zChat.setVisitorInfo(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      tags: ['app', 'zendesk2_plugin'],
    );

    await Zendesk2Chat.instance.startChatProviders(autoConnect: false);

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ZendeskChatUI()));
  }

  void answer() async {
    z.initAnswerSDK(appId, clientId, zendeskUrl);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ZendeskAnswerUI()));
  }

  void talk() async {
    z.initTalkSDK(appId, clientId, zendeskUrl);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ZendeskTalkUI()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            FloatingActionButton.extended(
              heroTag: 'chat',
              icon: Icon(FontAwesomeIcons.comments),
              label: Text('Chat SDK V2'),
              onPressed: chat,
            ),
            FloatingActionButton.extended(
              heroTag: 'answer',
              icon: Icon(FontAwesomeIcons.comments),
              label: Text('Answer BOT'),
              onPressed: answer,
            ),
            FloatingActionButton.extended(
              heroTag: 'chat',
              icon: Icon(FontAwesomeIcons.comments),
              label: Text('Chat SDK V2'),
              onPressed: talk,
            ),
          ],
        ),
      ),
    );
  }
}
