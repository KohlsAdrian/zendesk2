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

  Widget _text(String text) => Text(
        text,
        style: TextStyle(fontSize: 10),
      );

  Widget _debugCard() => Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(5),
        child: Card(
          color: Colors.transparent,
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(5),
            child: _providerModel == null
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text('Online: ' + _providerModel.isOnline.toString()),
                      _text('isFileSendingEnabled: ' +
                          _providerModel.isFileSendingEnabled.toString()),
                      _text('chatSessionStatus: ' +
                          _providerModel.chatSessionStatus
                              .toString()
                              .split('.')
                              .last),
                      _text('connectionStatus: ' +
                          _providerModel.connectionStatus
                              .toString()
                              .split('.')
                              .last),
                      _text(
                          'hasAgents: ' + _providerModel.hasAgents.toString()),
                      _text('isChatting: ' +
                          _providerModel.isChatting.toString()),
                    ],
                  ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;

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

                      switch (log.chatLogType.logType) {
                        case LOG_TYPE.ATTACHMENT_MESSAGE:
                          message = 'Attachment';
                          isAttachment = true;
                          break;
                        case LOG_TYPE.CHAT_COMMENT:
                          message = 'Comment';
                          break;
                        case LOG_TYPE.CHAT_RATING:
                          message = 'Rating';
                          break;
                        case LOG_TYPE.CHAT_RATING_REQUEST:
                          message = 'Rating request';
                          break;
                        case LOG_TYPE.MEMBER_JOIN:
                          message = 'Member join - $name';
                          break;
                        case LOG_TYPE.MEMBER_LEAVE:
                          message = 'Member leave';
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

                      return Row(
                        mainAxisAlignment: isVisitor
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            width: size.width * 0.7,
                            padding: EdgeInsets.all(5),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Column(
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: () async {
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
                        final compatibleExt =
                            await _z.getAttachmentExtensions();
                        final result = isPhoto
                            ? await ImagePicker()
                                .getImage(source: ImageSource.camera)
                            : await FilePicker.platform.pickFiles(
                                allowMultiple: false,
                                type: FileType.custom,
                                allowedExtensions: compatibleExt,
                              );
                        if (result != null) {
                          final file = result is FilePickerResult
                              ? result.files.single
                              : (result as PickedFile);

                          final path = file is PlatformFile
                              ? file.path
                              : (file as PickedFile).path;

                          _z.sendFile(path);
                        }
                      },
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.7,
                      padding: EdgeInsets.all(5),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: TextField(
                            controller: _tecM,
                            onChanged: (text) => _z.sendTyping(text.isNotEmpty),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        onPressed: () async {
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
                                SizedBox(height: 50),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'zendeskSend',
                      child: Icon(Icons.send),
                      onPressed: () async {
                        final text = _tecM.text;
                        if (text.isNotEmpty) {
                          await _z.sendMessage(text);
                          _tecM.clear();
                          _z.sendTyping(false);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
