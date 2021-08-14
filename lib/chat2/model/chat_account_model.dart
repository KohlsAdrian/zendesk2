import 'package:zendesk2/zendesk2.dart';

class ChatAccountModel {
  final bool isOnline;
  final Iterable<ChatAccountDepartmentModel> departments;

  ChatAccountModel(
    this.isOnline,
    this.departments,
  );

  factory ChatAccountModel.fromJson(Map json) {
    bool isOnline = json['isOnline'];
    Iterable<ChatAccountDepartmentModel> departments =
        (json['departments'] as Iterable)
            .map((d) => ChatAccountDepartmentModel.fromJson(d));
    return ChatAccountModel(isOnline, departments);
  }
}

class ChatAccountDepartmentModel {
  final String name;
  final String id;
  final DEPARTMENT_STATUS status;

  ChatAccountDepartmentModel(
    this.name,
    this.id,
    this.status,
  );

  factory ChatAccountDepartmentModel.fromJson(Map json) {
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

    return ChatAccountDepartmentModel(name, id, status);
  }
}
