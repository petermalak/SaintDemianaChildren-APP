enum AftekadType {
  phone_call,
  home_visit,
  whatsapp_message,
}

class AftekadModel {
  String? id;
  String? khademName;
  String? makhdoumId;
  String? makhdoumName;
  bool? status;
  AftekadType? type;
  DateTime? actualDate;
  AftekadModel({
    this.id,
    this.khademName,
    this.makhdoumId,
    this.makhdoumName,
    this.status,
    this.actualDate,
    this.type,
  });

  factory AftekadModel.fromJson(dynamic json) {
    return AftekadModel(
      id: json['id'],
      khademName: json['khademName'],
      makhdoumId: json['makhdoumId'],
      makhdoumName: json['makhdoumName'],
      status: json['status'] != null ? json['status'] == "completed" : null,
      actualDate: json['actualDate'] != null
          ? DateTime.tryParse(json['actualDate'])
          : null,
      type: json['type'] != null
          ? AftekadType.values
              .firstWhere((e) => e.toString() == 'AftekadType.${json['type']}')
          : null,
    );
  }
}
