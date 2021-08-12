///
/// The enum name says it all :)
///
enum CONNECTION_STATUS {
  CONNECTED,
  CONNECTING,
  DISCONNECTED,
  FAILED,
  RECONNECTING,
  UNREACHABLE,
  UNKNOWN,
}

///
/// The enum name says it all :)
///
enum CHAT_SESSION_STATUS {
  CONFIGURING,
  ENDED,
  ENDING,
  INITIALIZING,
  STARTED,
  UNKNOWN,
}

///
/// The enum name says it all :)
///
enum DELIVERY_STATUS {
  DELIVERED,
  PENDING,
  UNKNOWN,
}

///
/// The enum name says it all :)
///
enum LOG_TYPE {
  ATTACHMENT_MESSAGE,
  CHAT_COMMENT,
  MEMBER_JOIN,
  MEMBER_LEAVE,
  MESSAGE,
  OPTIONS_MESSAGE,
  UNKNOWN,
}

///
/// The enum name says it all :)
///
enum CHAT_PARTICIPANT {
  AGENT,
  SYSTEM,
  TRIGGER,
  VISITOR,
}

///
/// The enum name says it all :)
///
enum ATTACHMENT_ERROR {
  NONE,
  SIZE_LIMIT,
}
