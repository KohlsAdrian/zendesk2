import 'package:zendesk2/zendesk2.dart';

class ChatProviderModel {
  final bool isChatting;
  final CHAT_SESSION_STATUS chatSessionStatus;
  final Iterable<Agent> agents;
  final Iterable<ChatLog> logs;
  final int queuePosition;
  final String queueId;
  final ChatDepartment? chatDepartment;

  ChatProviderModel(
    this.isChatting,
    this.chatSessionStatus,
    this.agents,
    this.logs,
    this.queuePosition,
    this.queueId,
    this.chatDepartment,
  );

  bool get hasAgents => this.agents.isNotEmpty;

  factory ChatProviderModel.fromJson(Map map) {
    bool isChatting = map['isChatting'];
    Iterable<Agent> agents =
        ((map['agents'] ?? []) as Iterable).map((e) => Agent.fromJson(e));

    Iterable<ChatLog> logs =
        ((map['logs'] ?? []) as Iterable).map((e) => ChatLog.fromJson(e));

    int queuePosition = map['queuePosition'] ?? -1;
    String queueId = map['queueId'];

    CHAT_SESSION_STATUS chatSessionStatus = CHAT_SESSION_STATUS.CONFIGURING;

    final mChatSessionStatus = map['chatSessionStatus'];

    switch (mChatSessionStatus.toString().toUpperCase()) {
      case 'CONFIGURING':
        chatSessionStatus = CHAT_SESSION_STATUS.CONFIGURING;
        break;
      case 'ENDED':
        chatSessionStatus = CHAT_SESSION_STATUS.ENDED;
        break;
      case 'ENDING':
        chatSessionStatus = CHAT_SESSION_STATUS.ENDING;
        break;
      case 'INITIALIZING':
        chatSessionStatus = CHAT_SESSION_STATUS.INITIALIZING;
        break;
      case 'STARTED':
        chatSessionStatus = CHAT_SESSION_STATUS.STARTED;
        break;
    }

    ChatDepartment? chatDepartment = map['department'] == null
        ? null
        : ChatDepartment.fromJson(map['department']);

    return ChatProviderModel(
      isChatting,
      chatSessionStatus,
      agents,
      logs,
      queuePosition,
      queueId,
      chatDepartment,
    );
  }
}

class ChatDepartment {
  final String name;
  final String id;
  final DEPARTMENT_STATUS status;

  ChatDepartment(
    this.name,
    this.id,
    this.status,
  );

  factory ChatDepartment.fromJson(Map json) {
    String name = json['name'];
    String id = json['id'];
    DEPARTMENT_STATUS status = DEPARTMENT_STATUS.OFFLINE;
    switch (json['status']) {
      case 'AWAY':
        status = DEPARTMENT_STATUS.AWAY;
        break;
      case 'ONLINE':
        status = DEPARTMENT_STATUS.ONLINE;
        break;
      case 'OFFLINE':
        status = DEPARTMENT_STATUS.OFFLINE;
        break;
      default:
        status = DEPARTMENT_STATUS.OFFLINE;
    }
    return ChatDepartment(
      name,
      id,
      status,
    );
  }
}

class Agent {
  final String? avatar;
  final String displayName;
  final bool isTyping;
  final String nick;

  Agent(this.avatar, this.displayName, this.isTyping, this.nick);

  factory Agent.fromJson(Map map) {
    String? avatar = map['avatar'];
    String displayName = map['displayName'];
    bool isTyping = map['isTyping'];
    String nick = map['nick'];
    return Agent(avatar, displayName, isTyping, nick);
  }
}

class ChatLog {
  final bool createdByVisitor;
  final DateTime createdTimestamp;
  final String displayName;
  final DateTime lastModifiedTimestamp;
  final String nick;
  final ChatLogDeliveryStatus chatLogDeliveryStatus;
  final ChatLogType chatLogType;
  final CHAT_PARTICIPANT chatParticipant;

  ChatLog(
    this.createdByVisitor,
    this.createdTimestamp,
    this.displayName,
    this.lastModifiedTimestamp,
    this.nick,
    this.chatLogDeliveryStatus,
    this.chatLogType,
    this.chatParticipant,
  );

  factory ChatLog.fromJson(Map map) {
    bool createdByVisitor = map['createdByVisitor'];
    String displayName = map['displayName'];

    final mCreatedTimestamp = map['createdTimestamp'];
    final mLastModifiedTimestamp = map['lastModifiedTimestamp'];

    DateTime createdTimestamp = DateTime.fromMillisecondsSinceEpoch(
        mCreatedTimestamp is double
            ? mCreatedTimestamp.toInt()
            : mCreatedTimestamp);

    DateTime lastModifiedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        mLastModifiedTimestamp is double
            ? mLastModifiedTimestamp.toInt()
            : mLastModifiedTimestamp);

    String nick = map['nick'];

    ChatLogDeliveryStatus chatLogDeliveryStatus =
        ChatLogDeliveryStatus.fromJson(map['deliveryStatus']);

    ChatLogType chatLogType = ChatLogType.fromJson(map['type']);

    CHAT_PARTICIPANT chatParticipant = CHAT_PARTICIPANT.SYSTEM;
    String mChatParticipant = map['chatParticipant'];

    switch (mChatParticipant) {
      case 'AGENT':
        chatParticipant = CHAT_PARTICIPANT.AGENT;
        break;
      case 'SYSTEM':
        chatParticipant = CHAT_PARTICIPANT.SYSTEM;
        break;
      case 'TRIGGER':
        chatParticipant = CHAT_PARTICIPANT.TRIGGER;
        break;
      case 'VISITOR':
        chatParticipant = CHAT_PARTICIPANT.VISITOR;
        break;
    }

    return ChatLog(
      createdByVisitor,
      createdTimestamp,
      displayName,
      lastModifiedTimestamp,
      nick,
      chatLogDeliveryStatus,
      chatLogType,
      chatParticipant,
    );
  }
}

class ChatLogDeliveryStatus {
  final bool isFailed;
  final DELIVERY_STATUS deliveryStatus;

  ChatLogDeliveryStatus(this.isFailed, this.deliveryStatus);

  factory ChatLogDeliveryStatus.fromJson(Map map) {
    bool isFailed = map['isFailed'] ?? false;

    String? mDeliveryStatus = map['status'];
    DELIVERY_STATUS deliveryStatus = DELIVERY_STATUS.PENDING;

    switch (mDeliveryStatus) {
      case 'DELIVERED':
        deliveryStatus = DELIVERY_STATUS.DELIVERED;
        break;
      case 'PENDING':
        deliveryStatus = DELIVERY_STATUS.PENDING;
        break;
      case 'FAILED':
        deliveryStatus = DELIVERY_STATUS.FAILED;
        break;
    }

    return ChatLogDeliveryStatus(isFailed, deliveryStatus);
  }
}

class ChatLogType {
  final LOG_TYPE logType;
  final ChatMessage? chatMessage;
  final ChatOptionsMessage? chatOptionsMessage;
  final ChatAttachment? chatAttachment;

  ChatLogType(
    this.logType,
    this.chatMessage,
    this.chatOptionsMessage,
    this.chatAttachment,
  );

  factory ChatLogType.fromJson(Map map) {
    String mLogType = map['type'];

    LOG_TYPE logType = LOG_TYPE.OPTIONS_MESSAGE;

    switch (mLogType) {
      case 'ATTACHMENT_MESSAGE':
        logType = LOG_TYPE.ATTACHMENT_MESSAGE;
        break;
      case 'MEMBER_JOIN':
        logType = LOG_TYPE.MEMBER_JOIN;
        break;
      case 'MEMBER_LEAVE':
        logType = LOG_TYPE.MEMBER_LEAVE;
        break;
      case 'MESSAGE':
        logType = LOG_TYPE.MESSAGE;
        break;
      case 'OPTIONS_MESSAGE':
        logType = LOG_TYPE.OPTIONS_MESSAGE;
        break;
    }

    ChatOptionsMessage? chatOptionsMessage;
    ChatMessage? chatMessage;
    ChatAttachment? chatAttachment;

    switch (logType) {
      case LOG_TYPE.ATTACHMENT_MESSAGE:
        chatAttachment = ChatAttachment.fromJson(map['chatAttachment']);
        break;
      case LOG_TYPE.MEMBER_JOIN:
      case LOG_TYPE.MEMBER_LEAVE:
        break;
      case LOG_TYPE.MESSAGE:
        chatMessage = ChatMessage.fromJson(map['chatMessage']);
        break;
      case LOG_TYPE.OPTIONS_MESSAGE:
        chatOptionsMessage =
            ChatOptionsMessage.fromJson(map['chatOptionsMessage']);
        break;
    }
    return ChatLogType(
      logType,
      chatMessage,
      chatOptionsMessage,
      chatAttachment,
    );
  }
}

class ChatMessage {
  final String? id;
  final String? message;

  ChatMessage(
    this.id,
    this.message,
  );

  factory ChatMessage.fromJson(Map map) {
    String? id = map['id'];
    String? message = map['message'];
    return ChatMessage(id, message);
  }
}

class ChatOptionsMessage {
  final String? message;
  final Iterable<String> options;

  ChatOptionsMessage(this.message, this.options);

  factory ChatOptionsMessage.fromJson(Map map) {
    final String? message = map['message'];
    final Iterable<String> options =
        ((map['options'] ?? []) as Iterable).map((o) => o.toString());
    return ChatOptionsMessage(message, options);
  }
}

class ChatAttachment {
  final String? id;
  final String? message;
  final String? url;
  final ChatAttachmentAttachment chatAttachmentAttachment;

  ChatAttachment(
    this.id,
    this.message,
    this.url,
    this.chatAttachmentAttachment,
  );

  factory ChatAttachment.fromJson(Map map) {
    String? id = map['id'];
    String? message = map['message'];
    String? url = map['url'];
    ChatAttachmentAttachment chatAttachmentAttachment =
        ChatAttachmentAttachment.fromJson(
            map['chatAttachmentAttachment'] ?? {});
    return ChatAttachment(id, message, url, chatAttachmentAttachment);
  }
}

class ChatAttachmentAttachment {
  final String? name;
  final String? localUrl;
  final String? mimeType;
  final int? size;
  final String? url;
  final String? attachmentError;

  ChatAttachmentAttachment(
    this.name,
    this.localUrl,
    this.mimeType,
    this.size,
    this.url,
    this.attachmentError,
  );

  factory ChatAttachmentAttachment.fromJson(Map map) {
    String? name = map['name'];
    String? localUrl = map['localUrl'];
    String? mimeType = map['mimeType'];
    int? size = map['size'];
    String? url = map['url'];
    String? attachmentError = map['error'];

    return ChatAttachmentAttachment(
      name,
      localUrl,
      mimeType,
      size,
      url,
      attachmentError,
    );
  }
}
