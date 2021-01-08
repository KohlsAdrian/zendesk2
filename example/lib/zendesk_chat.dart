import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zendesk2/chat2/model/provider_model.dart';
import 'package:zendesk2/zendesk2.dart';

class ZendeskChat extends StatefulWidget {
  _ZendeskChat createState() => _ZendeskChat();
}

class _ZendeskChat extends State<ZendeskChat> {
  final Zendesk2Chat _z = Zendesk2Chat.instance;

  final _tecM = TextEditingController();

  ProviderModel _providerModel;

  @override
  void dispose() {
    _z.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(), () async {
      await _z.startChatProviders();
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
                Icon(Icons.photo),
                Text('Gallery'),
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

      _z.sendFile(path);
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
                                    .map((e) => FlatButton(
                                          color: rate[e]
                                              ? Colors.blue
                                              : Colors.transparent,
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
                      FlatButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text('Cancel'),
                      ),
                      RaisedButton(
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text('Custom Chat UI')),
      body: _providerModel == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _providerModel.logs.length,
                    itemBuilder: (context, index) {
                      ChatLog log = _providerModel.logs[index];
                      ChatMessage chatMessage = log.chatLogType.chatMessage;

                      String message = chatMessage?.message ?? '';

                      String name = log.displayName;

                      bool isAttachment = false;
                      bool isJoinOrLeave = false;
                      bool isRatingReview = false;
                      bool isRatingComment = false;
                      bool isAgent = log.chatLogParticipant.chatParticipant ==
                          CHAT_PARTICIPANT.AGENT;

                      Agent agent;
                      if (isAgent)
                        agent = _providerModel.agents.firstWhere(
                            (element) => element.displayName == name,
                            orElse: () => null);

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
                      }

                      bool isVisitor = log.chatLogParticipant.chatParticipant ==
                          CHAT_PARTICIPANT.VISITOR;

                      final imageUrl = log.chatLogType?.chatAttachment?.url;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (isAgent)
                                        agent?.avatar != null
                                            ? CachedNetworkImage(
                                                imageUrl: agent.avatar)
                                            : Icon(Icons.person),
                                      Card(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0)),
                                        child: Container(
                                          width: size.width * 0.5,
                                          padding: EdgeInsets.all(5),
                                          child: Column(
                                            crossAxisAlignment: isVisitor
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              if (isAttachment)
                                                CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  placeholder: (context, url) =>
                                                      CircularProgressIndicator(),
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
                  ),
                  if (_providerModel.agents.isNotEmpty &&
                      _providerModel.agents.first.isTyping)
                    Text(
                      'Agent is typing...',
                      textAlign: TextAlign.start,
                    ),
                ],
              ),
            ),
      floatingActionButton: _providerModel == null ||
              _providerModel.chatSessionStatus == CHAT_SESSION_STATUS.ENDED
          ? null
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: size.width / 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          'Agents: ' + _providerModel.agents.length.toString()),
                      IconButton(
                        icon: Icon(Icons.attach_file),
                        onPressed: _attach,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: size.width / 2.5,
                  padding: EdgeInsets.all(5),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        controller: _tecM,
                        onChanged: (text) => _z.sendTyping(text.isNotEmpty),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        heroTag: 'zendeskSettings',
                        child: Icon(Icons.settings),
                        onPressed: _settings,
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'zendeskSend',
                      child: Icon(Icons.send),
                      onPressed: _send,
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
