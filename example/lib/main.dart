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

            Zendesk2Chat z = Zendesk2Chat.instance;

            await z.init(
              accountKey,
              appId,
              iosThemeColor: Color(0xFFFF5148),
            );
            await z.logger(true);
            await z.setVisitorInfo(
              name: name,
              email: email,
              phoneNumber: phoneNumber,
              tags: ['app', 'zendesk2_plugin'],
            );

            await z.startChat(
              toolbarTitle: 'Fale Conosco',
              backButtonLabel: 'Voltar',
              botLabel: 'IZA',
            );
          },
        ),
      ),
    );
  }
}
