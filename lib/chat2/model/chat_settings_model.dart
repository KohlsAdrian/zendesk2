class ChatSettingsModel {
  final bool? isFileSendingEnabled;
  final Iterable<String>? supportedFileTypes;
  final int? fileSizeLimit;

  ChatSettingsModel(
    this.isFileSendingEnabled,
    this.supportedFileTypes,
    this.fileSizeLimit,
  );

  factory ChatSettingsModel.fromJson(Map map) {
    bool? isFileSendingEnabled = map['isFileSendingEnabled'];
    Iterable<String>? supportedFileTypes =
        (map['supportedFileTypes'] as Iterable).map((ext) => ext);
    int? fileSizeLimit = map['fileSizeLimit'];
    return ChatSettingsModel(
      isFileSendingEnabled,
      supportedFileTypes,
      fileSizeLimit,
    );
  }
}
