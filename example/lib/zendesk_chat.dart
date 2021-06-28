import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zendesk2/chat2/model/provider_model.dart';
import 'package:zendesk2/zendesk2.dart';

class ZendeskChat extends StatefulWidget {
  _ZendeskChat createState() => _ZendeskChat();
}

class _ZendeskChat extends State<ZendeskChat> {
  final Zendesk2Chat _z = Zendesk2Chat.instance;

  final _tecM = TextEditingController();
  ProviderModel? _providerModel;

  @override
  void dispose() {
    _z.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(), () async {
      _z.providersStream.listen((providerModel) {
        _providerModel = providerModel;
        setState(() {});
      });
    });
  }

  void _attach() async {
    bool isPhoto = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: [
                Icon(Icons.camera_alt),
                Text('Photo'),
              ],
            ),
            onTap: () => Navigator.of(context).pop(true),
          ),
          ListTile(
            title: Row(
              children: [
                Icon(FontAwesomeIcons.file),
                Text('File'),
              ],
            ),
            onTap: () => Navigator.of(context).pop(false),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
    if (isPhoto == null) return;
    final compatibleExt = await _z.getAttachmentExtensions();
    final result = isPhoto
        ? await ImagePicker().getImage(source: ImageSource.camera)
        : await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.custom,
            allowedExtensions: compatibleExt,
          );
    if (result != null) {
      final file = result is FilePickerResult
          ? result.files.single
          : (result as PickedFile);

      final path = file is PlatformFile ? file.path : (file as PickedFile).path;

      if (path != null) {
        _z.sendFile(path);
      }
    }
  }

  void _settings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: [
                Icon(Icons.close),
                Text('End chat'),
              ],
            ),
            onTap: () async {
              await _z.endChat();
              Navigator.of(context).pop(true);
            },
          ),
          ListTile(
            title: Row(
              children: [
                Icon(Icons.rate_review),
                Text('Rate'),
              ],
            ),
            onTap: () async {
              final Map<RATING, bool> rate = {
                RATING.GOOD: false,
                RATING.BAD: false,
                RATING.NONE: true,
              };
              Navigator.of(context).pop();
              final tec = TextEditingController();
              RATING rating = RATING.NONE;
              final text = await showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: Text('Rate and Comment'),
                    content: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: RATING.values
                                    .map((e) => TextButton(
                                          onPressed: () => setState(() {
                                            rate.keys.forEach((element) =>
                                                rate[element] = element == e);
                                            rating = e;
                                          }),
                                          child: Text(e
                                              .toString()
                                              .replaceAll('RATING.', '')),
                                        ))
                                    .toList()),
                          ),
                          TextField(
                            controller: tec,
                            decoration: InputDecoration(
                                labelText: 'Comment (Optional)'),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(tec.text),
                        child: Text('Rate'),
                      ),
                    ],
                  ),
                ),
              );
              if (text is String && text != null && text.isNotEmpty) {
                _z.sendRateComment(text);
              }
              if (rating != null) {
                _z.sendRateReview(rating);
              }
            },
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  void _send() async {
    final text = _tecM.text;
    if (text.isNotEmpty) {
      await _z.sendMessage(text);
      _tecM.clear();
      _z.sendTyping(false);
      setState(() {});
    }
  }

  Widget _userWidget() => Container(
        padding: EdgeInsets.all(5),
        child: Card(
          color: Theme.of(context).primaryColor,
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: Container(
            padding: EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 0.1,
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.amber),
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        FontAwesomeIcons.pencilAlt,
                        color: Colors.white,
                      ),
                    ),
                    controller: _tecM,
                    onChanged: (text) => _z.sendTyping(text.isNotEmpty),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'attachFab',
                      mini: true,
                      backgroundColor: Theme.of(context).accentColor,
                      child: Icon(Icons.attach_file),
                      onPressed: _attach,
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zendeskSettings',
                      child: Icon(Icons.settings),
                      onPressed: _settings,
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zendeskSend',
                      child: Icon(Icons.send),
                      onPressed: _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _chat() => ListView.builder(
        padding: EdgeInsets.only(bottom: 200),
        itemCount: _providerModel!.logs.length,
        itemBuilder: (context, index) {
          ChatLog log = _providerModel!.logs[index];
          ChatMessage chatMessage = log.chatLogType.chatMessage;

          String message = chatMessage.message ?? '';

          String name = log.displayName ?? '';

          bool isAttachment = false;
          bool isJoinOrLeave = false;
          bool isRatingReview = false;
          bool isRatingComment = false;
          bool isAgent =
              log.chatLogParticipant.chatParticipant == CHAT_PARTICIPANT.AGENT;

          Agent? agent;
          if (isAgent)
            agent = _providerModel!.agents
                .firstWhere((element) => element.displayName == name);

          switch (log.chatLogType.logType) {
            case LOG_TYPE.ATTACHMENT_MESSAGE:
              message = 'Attachment';
              isAttachment = true;
              break;
            case LOG_TYPE.CHAT_COMMENT:
              ChatComment chatComment = log.chatLogType.chatComment;
              final comment = chatComment.comment ?? '';
              final newComment = chatComment.newComment ?? '';
              message = 'Rating comment: $comment\n'
                  'New comment: $newComment';
              isRatingComment = true;
              break;
            case LOG_TYPE.CHAT_RATING:
              message = 'Rating review: ' +
                  log.chatLogType.chatRating.rating
                      .toString()
                      .replaceAll('RATING.', '');
              isRatingReview = true;
              break;
            case LOG_TYPE.CHAT_RATING_REQUEST:
              message = 'Rating request';
              break;
            case LOG_TYPE.MEMBER_JOIN:
              message = '$name Joined!';
              isJoinOrLeave = true;
              break;
            case LOG_TYPE.MEMBER_LEAVE:
              message = '$name Left!';
              isJoinOrLeave = true;
              break;
            case LOG_TYPE.MESSAGE:
              message = message;
              break;
            case LOG_TYPE.OPTIONS_MESSAGE:
              message = 'Options message';
              break;
            case LOG_TYPE.UNKNOWN:
              message = 'Unknown';
              break;
            case null:
              message = 'LogType=null';
              break;
          }

          bool isVisitor = log.chatLogParticipant.chatParticipant ==
              CHAT_PARTICIPANT.VISITOR;

          final imageUrl = log.chatLogType.chatAttachment.url;

          final mimeType = log
              .chatLogType.chatAttachment.chatAttachmentAttachment.mimeType
              ?.toLowerCase();
          final isImage = mimeType == null
              ? false
              : (mimeType.contains('jpg') ||
                  mimeType.contains('png') ||
                  mimeType.contains('jpeg') ||
                  mimeType.contains('gif'));

          return isJoinOrLeave || isRatingReview || isRatingComment
              ? Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: isVisitor
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isAgent)
                            agent?.avatar != null
                                ? CachedNetworkImage(
                                    imageUrl: agent!.avatar ?? '')
                                : Icon(Icons.person),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              padding: EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  if (isAttachment)
                                    GestureDetector(
                                      onTap: () => launch(log
                                              .chatLogType
                                              .chatAttachment
                                              .chatAttachmentAttachment
                                              .url ??
                                          ''),
                                      child: isImage
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl ?? '',
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(),
                                            )
                                          : Column(
                                              children: [
                                                Icon(FontAwesomeIcons.file),
                                                Text(log
                                                        .chatLogType
                                                        .chatAttachment
                                                        .chatAttachmentAttachment
                                                        .name ??
                                                    '')
                                              ],
                                            ),
                                    ),
                                  Text(message),
                                ],
                              ),
                            ),
                          ),
                          if (isVisitor) Icon(Icons.person),
                        ],
                      ),
                    )
                  ],
                );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Chat UI'),
        actions: [
          if (_providerModel != null)
            Icon(
              Icons.circle,
              color: _providerModel!.connectionStatus ==
                      CONNECTION_STATUS.CONNECTED
                  ? Colors.green
                  : _providerModel!.connectionStatus ==
                          CONNECTION_STATUS.CONNECTING
                      ? Colors.yellow
                      : Colors.red,
            )
        ],
      ),
      body: _providerModel == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (_providerModel != null) _chat(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_providerModel != null &&
                        _providerModel!.agents.isNotEmpty)
                      if (_providerModel!.agents.first.isTyping ?? false)
                        Text(
                          'Agent is typing...',
                          textAlign: TextAlign.start,
                        ),
                    _userWidget(),
                  ],
                ),
              ],
            ),
    );
  }
}
