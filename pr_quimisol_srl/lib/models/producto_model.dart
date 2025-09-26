class Producto {
  int? idproducto;
  String codigo;
  String nombre;
  String descripcion;
  int idunidad;
  String? imagen;

  DateTime? createdon;
  DateTime? updatedon;
  DateTime? deletedon;

  Producto({
    this.idproducto,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.idunidad,
    this.imagen,
    this.createdon,
    this.updatedon,
    this.deletedon,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idproducto: json['idproducto'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      idunidad: json['idunidad'],
      imagen: json['imagen'],
      createdon: json['createdon'] != null ? DateTime.parse(json['createdon']) : null,
      updatedon: json['updatedon'] != null ? DateTime.parse(json['updatedon']) : null,
      deletedon: json['deletedon'] != null ? DateTime.parse(json['deletedon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'idunidad': idunidad,
      'imagen': imagen,
    };
  }
}
