import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zendesk2/zendesk2.dart';
import 'package:zendesk2_example/zendesk_chat.dart';

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
      theme: ThemeData(accentColor: Colors.amber),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  void zendesk(bool isNativeChat, BuildContext context) async {
    String accountKey = '';
    String appId = '';

    String name = '';
    String email = '';
    String phoneNumber = '';

    Zendesk2Chat z = Zendesk2Chat.instance;

    if (kIsWeb) {
    } else {
      await z.logger(true);

      await z.init(accountKey, appId);

      await z.setVisitorInfo(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        tags: ['app', 'zendesk2_plugin'],
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

      if (isNativeChat) {
        await z.startChat(
          toolbarTitle: 'Talk to us',
          backButtonLabel: 'Back',
          botLabel: 'bip bop boting',
        );
      } else {
        await Zendesk2Chat.instance.startChatProviders();

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => ZendeskChat()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Text('Press on FAB to start chat'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customChat',
        icon: Icon(FontAwesomeIcons.comments),
        label: Text('Custom Chat'),
        onPressed: () => zendesk(false, context),
      ),
    );
  }
}
