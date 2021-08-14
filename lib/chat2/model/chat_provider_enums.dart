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
}

///
/// The enum name says it all :)
///
enum DELIVERY_STATUS {
  DELIVERED,
  PENDING,
}

///
/// The enum name says it all :)
///
enum LOG_TYPE {
  ATTACHMENT_MESSAGE,
  MEMBER_JOIN,
  MEMBER_LEAVE,
  MESSAGE,
  OPTIONS_MESSAGE,
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
enum DEPARTMENT_STATUS {
  ONLINE,
  OFFLINE,
  AWAY,
}