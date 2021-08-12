import 'package:zendesk2/zendesk.dart';

class ZendeskAnswer {
  ZendeskAnswer._();
  static final ZendeskAnswer instance = ZendeskAnswer._();

  static final _channel = Zendesk.instance.channel;
}
