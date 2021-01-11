import 'package:zendesk2/zendesk2.dart';

class ProviderModel {
  final bool isOnline;
  final bool isChatting;
  final bool hasAgents;
  final bool isFileSendingEnabled;
  final CONNECTION_STATUS connectionStatus;
  final CHAT_SESSION_STATUS chatSessionStatus;
  final List<Agent> agents;
  final List<ChatLog> logs;
  final int queuePosition;
  final String rating;
  final String comment;

  ProviderModel(
    this.isOnline,
    this.isChatting,
    this.hasAgents,
    this.isFileSendingEnabled,
    this.connectionStatus,
    this.chatSessionStatus,
    this.agents,
    this.logs,
    this.queuePosition,
    this.rating,
    this.comment,
  );

  factory ProviderModel.fromJson(Map map) {
    bool isOnline = map['isOnline'];
    bool isChatting = map['isChatting'];
    bool hasAgents = map['hasAgents'];
    bool isFileSendingEnabled = map['isFileSendingEnabled'];
    List<Agent> agents = ((map['agents'] ?? []) as Iterable)
        .map((e) => Agent.fromJson(e))
        .toList();

    List<ChatLog> logs = ((map['logs'] ?? []) as Iterable)
        .map((e) => ChatLog.fromJson(e))
        .toList();

    int queuePosition = map['queuePosition'];
    String rating = map['rating'];
    String comment = map['comment'];

    CONNECTION_STATUS connectionStatus;
    CHAT_SESSION_STATUS chatSessionStatus;

    final mConnectionStatus = map['connectionStatus'];
    final mChatSessionStatus = map['chatSessionStatus'];

    switch (mConnectionStatus) {
      case 'CONNECTED':
        connectionStatus = CONNECTION_STATUS.CONNECTED;
        break;
      case 'CONNECTING':
        connectionStatus = CONNECTION_STATUS.CONNECTING;
        break;
      case 'DISCONNECTED':
        connectionStatus = CONNECTION_STATUS.DISCONNECTED;
        break;
      case 'FAILED':
        connectionStatus = CONNECTION_STATUS.FAILED;
        break;
      case 'RECONNECTING':
        connectionStatus = CONNECTION_STATUS.RECONNECTING;
        break;
      case 'UNREACHABLE':
        connectionStatus = CONNECTION_STATUS.UNREACHABLE;
        break;
      default:
        connectionStatus = CONNECTION_STATUS.UNKNOWN;
    }

    switch (mChatSessionStatus) {
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
      default:
        chatSessionStatus = CHAT_SESSION_STATUS.UNKNOWN;
    }

    return ProviderModel(
      isOnline,
      isChatting,
      hasAgents,
      isFileSendingEnabled,
      connectionStatus,
      chatSessionStatus,
      agents,
      logs,
      queuePosition,
      rating,
      comment,
    );
  }
}

class Agent {
  final String avatar;
  final String displayName;
  final bool isTyping;
  final String nick;

  Agent(this.avatar, this.displayName, this.isTyping, this.nick);

  factory Agent.fromJson(Map map) {
    String avatar = map['avatar'];
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
  final ChatLogParticipant chatLogParticipant;
  final ChatLogDeliveryStatus chatLogDeliveryStatus;
  final ChatLogType chatLogType;

  ChatLog(
    this.createdByVisitor,
    this.createdTimestamp,
    this.displayName,
    this.lastModifiedTimestamp,
    this.nick,
    this.chatLogParticipant,
    this.chatLogDeliveryStatus,
    this.chatLogType,
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
    ChatLogParticipant chatLogParticipant =
        ChatLogParticipant.fromJson(map['participant'] ?? {});
    ChatLogDeliveryStatus chatLogDeliveryStatus =
        ChatLogDeliveryStatus.fromJson(map['deliveryStatus'] ?? {});
    ChatLogType chatLogType = ChatLogType.fromJson(map['type'] ?? {});
    return ChatLog(
      createdByVisitor,
      createdTimestamp,
      displayName,
      lastModifiedTimestamp,
      nick,
      chatLogParticipant,
      chatLogDeliveryStatus,
      chatLogType,
    );
  }
}

class ChatLogParticipant {
  final CHAT_PARTICIPANT chatParticipant;

  ChatLogParticipant(this.chatParticipant);

  factory ChatLogParticipant.fromJson(Map map) {
    CHAT_PARTICIPANT chatParticipant;
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

    return ChatLogParticipant(chatParticipant);
  }
}

class ChatLogDeliveryStatus {
  final bool isFailed;
  final DELIVERY_STATUS deliveryStatus;

  ChatLogDeliveryStatus(this.isFailed, this.deliveryStatus);

  factory ChatLogDeliveryStatus.fromJson(Map map) {
    bool isFailed = map['isFailed'];

    String mDeliveryStatus = map['status'];
    DELIVERY_STATUS deliveryStatus;

    switch (mDeliveryStatus) {
      case 'DELIVERED':
        deliveryStatus = DELIVERY_STATUS.DELIVERED;
        break;
      case 'PENDING':
        deliveryStatus = DELIVERY_STATUS.PENDING;
        break;
      case 'UNKNOWN':
        deliveryStatus = DELIVERY_STATUS.UNKNOWN;
        break;
    }

    return ChatLogDeliveryStatus(isFailed, deliveryStatus);
  }
}

class ChatLogType {
  final LOG_TYPE logType;
  final ChatMessage chatMessage;
  final ChatOptionsMessage chatOptionsMessage;
  final ChatAttachment chatAttachment;
  final ChatComment chatComment;
  final ChatRating chatRating;

  ChatLogType(
    this.logType,
    this.chatMessage,
    this.chatOptionsMessage,
    this.chatAttachment,
    this.chatComment,
    this.chatRating,
  );

  factory ChatLogType.fromJson(Map map) {
    String mLogType = map['type'];
    ChatMessage chatMessage = ChatMessage.fromJson(map['chatMessage'] ?? {});
    ChatOptionsMessage chatOptionsMessage =
        ChatOptionsMessage.fromJson(map['chatOptionsMessage'] ?? {});
    ChatAttachment chatAttachment =
        ChatAttachment.fromJson(map['chatAttachment'] ?? {});
    ChatComment chatComment = ChatComment.fromJson(map['chatComment'] ?? {});
    ChatRating chatRating = ChatRating.fromJson(map['chatRating'] ?? {});
    LOG_TYPE logType;

    switch (mLogType) {
      case 'ATTACHMENT_MESSAGE':
        logType = LOG_TYPE.ATTACHMENT_MESSAGE;
        break;
      case 'CHAT_COMMENT':
        logType = LOG_TYPE.CHAT_COMMENT;
        break;
      case 'CHAT_RATING':
        logType = LOG_TYPE.CHAT_RATING;
        break;
      case 'CHAT_RATING_REQUEST':
        logType = LOG_TYPE.CHAT_RATING_REQUEST;
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
      case 'UNKNOWN':
        logType = LOG_TYPE.UNKNOWN;
        break;
    }

    return ChatLogType(
      logType,
      chatMessage,
      chatOptionsMessage,
      chatAttachment,
      chatComment,
      chatRating,
    );
  }
}

class ChatMessage {
  final String id;
  final String message;

  ChatMessage(
    this.id,
    this.message,
  );

  factory ChatMessage.fromJson(Map map) {
    String id = map['id'];
    String message = map['message'];
    return ChatMessage(id, message);
  }
}

class ChatOptionsMessage {
  final String message;
  final List<String> options;

  ChatOptionsMessage(this.message, this.options);

  factory ChatOptionsMessage.fromJson(Map map) {
    final String message = map['message'];
    final List<String> options =
        ((map['options'] ?? []) as Iterable).map((e) => e.toString()).toList();
    return ChatOptionsMessage(message, options);
  }
}

class ChatComment {
  final String comment;
  final String newComment;

  ChatComment(this.comment, this.newComment);

  factory ChatComment.fromJson(Map map) {
    String comment = map['comment'];
    String newComment = map['newComment'];
    return ChatComment(comment, newComment);
  }
}

class ChatRating {
  final RATING rating;

  ChatRating(this.rating);

  factory ChatRating.fromJson(Map map) {
    String mRating = map['rating'];

    RATING rating;
    switch (mRating) {
      case 'GOOD':
        rating = RATING.GOOD;
        break;
      case 'BAD':
        rating = RATING.BAD;
        break;
      default:
        rating = RATING.NONE;
    }

    return ChatRating(rating);
  }
}

class ChatAttachment {
  final String id;
  final String message;
  final String url;
  final ChatAttachmentAttachment chatAttachmentAttachment;

  ChatAttachment(
    this.id,
    this.message,
    this.url,
    this.chatAttachmentAttachment,
  );

  factory ChatAttachment.fromJson(Map map) {
    String id = map['id'];
    String message = map['message'];
    String url = map['url'];
    ChatAttachmentAttachment chatAttachmentAttachment =
        ChatAttachmentAttachment.fromJson(
            map['chatAttachmentAttachment'] ?? {});
    return ChatAttachment(id, message, url, chatAttachmentAttachment);
  }
}

class ChatAttachmentAttachment {
  final String name;
  final String localUrl;
  final String mimeType;
  final int size;
  final String url;
  final ATTACHMENT_ERROR attachmentError;

  ChatAttachmentAttachment(
    this.name,
    this.localUrl,
    this.mimeType,
    this.size,
    this.url,
    this.attachmentError,
  );

  factory ChatAttachmentAttachment.fromJson(Map map) {
    String name = map['name'];
    String localUrl = map['localUrl'];
    String mimeType = map['mimeType'];
    int size = map['size'];
    String url = map['url'];
    String mAttachmentError = map['error'];

    ATTACHMENT_ERROR attachmentError;
    switch (mAttachmentError) {
      case 'NONE':
        attachmentError = ATTACHMENT_ERROR.NONE;
        break;
      case 'SIZE_LIMIT':
        attachmentError = ATTACHMENT_ERROR.SIZE_LIMIT;
        break;
      default:
        attachmentError = ATTACHMENT_ERROR.NONE;
    }

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
