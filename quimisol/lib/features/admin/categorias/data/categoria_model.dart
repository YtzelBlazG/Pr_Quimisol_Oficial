class Categoria {
  final int id;
  final String nombre;
  final String descripcion;

  final DateTime? createdOn;
  final DateTime? updatedOn;
  final DateTime? deletedOn;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.createdOn,
    this.updatedOn,
    this.deletedOn,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      createdOn: json['createdon'] != null ? DateTime.parse(json['createdon']) : null,
      updatedOn: json['updatedon'] != null ? DateTime.parse(json['updatedon']) : null,
      deletedOn: json['deletedon'] != null ? DateTime.parse(json['deletedon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
