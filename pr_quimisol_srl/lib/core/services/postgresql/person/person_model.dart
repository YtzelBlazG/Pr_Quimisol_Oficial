class Person {
  final int id;
  final String name;
  final String? phone;
  final DateTime? createdOn;
  final DateTime? updatedOn;
  final DateTime? deletedOn;

  Person({
    required this.id,
    required this.name,
    this.phone,
    this.createdOn,
    this.updatedOn,
    this.deletedOn,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: (json['idpersona'] as int?)?? 0,
      name: json['nombre'] ?? '',
      phone: json['telefono'],
      createdOn: json['createdon'] != null
          ? DateTime.tryParse(json['createdon'])
          : null,
      updatedOn: json['updatedon'] != null
          ? DateTime.tryParse(json['updatedon'])
          : null,
      deletedOn: json['deletedon'] != null
          ? DateTime.tryParse(json['deletedon'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idpersona': id,
      'nombre': name,
      'telefono': phone,
    };
  }
}
