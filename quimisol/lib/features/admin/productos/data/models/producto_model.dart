class Producto {
  int? idproducto;
  String codigo;
  String nombre;
  String descripcion;
  int idunidad;
  String? imagen;
  double precio;

  // 🔹 Campo adicional desde backend
  int stockDisponible;

  DateTime? createdon;
  DateTime? updatedon;
  DateTime? deletedon;

  Producto({
    this.idproducto,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.idunidad,
    required this.precio,
    this.imagen,
    this.stockDisponible = 0, // ✅ valor por defecto
    this.createdon,
    this.updatedon,
    this.deletedon,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idproducto: json['idproducto'],
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      idunidad: json['idunidad'] ?? 0,
      imagen: json['imagen'],
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      stockDisponible: int.tryParse(json['stock_disponible']?.toString() ?? '0') ?? 0, // ✅ nuevo
      createdon: json['createdon'] != null ? DateTime.tryParse(json['createdon']) : null,
      updatedon: json['updatedon'] != null ? DateTime.tryParse(json['updatedon']) : null,
      deletedon: json['deletedon'] != null ? DateTime.tryParse(json['deletedon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'idunidad': idunidad,
      'imagen': imagen,
      'precio': precio,
      // 🔹 stockDisponible NO se envía al backend
    };
  }
}
