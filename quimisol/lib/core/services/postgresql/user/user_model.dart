class UserModel {
  final int idUsuario;
  final int idPersona;
  final String correo;
  final String rol;
  final String telefono; // ✅ NUEVO CAMPO
  final DateTime createdOn;
  final DateTime? updatedOn;
  final DateTime? deletedOn;

  UserModel({
    required this.idUsuario,
    required this.idPersona,
    required this.correo,
    required this.rol,
    required this.telefono, // ✅ NUEVO
    required this.createdOn,
    this.updatedOn,
    this.deletedOn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['idusuario'] as int,
      idPersona: json['idpersona'] as int,
      correo: json['correo'] ?? '',
      rol: (json['rol'] ?? 'cliente').toString().toLowerCase(),
      telefono: json['telefono'] ?? '', // ✅ NUEVO
      createdOn: DateTime.parse(json['createdon']),
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
      'idusuario': idUsuario,
      'idpersona': idPersona,
      'correo': correo,
      'rol': rol,
      'telefono': telefono, // ✅ NUEVO
      'createdon': createdOn.toIso8601String(),
      'updatedon': updatedOn?.toIso8601String(),
      'deletedon': deletedOn?.toIso8601String(),
    };
  }
}
