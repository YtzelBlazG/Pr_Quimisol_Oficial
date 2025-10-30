class Producto {
  int? idproducto;
  String codigo;
  String nombre;
  String descripcion;
  int idunidad;
  int idcategoria;
  String? imagen;
  double precio;
  int stockDisponible;

  DateTime? createdon;
  DateTime? updatedon;
  DateTime? deletedon;

  // ✅ Nuevo campo opcional para mostrar en tabla
  String? categoria_nombre;

  Producto({
    this.idproducto,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.idunidad,
    required this.idcategoria,
    required this.precio,
    this.imagen,
    this.stockDisponible = 0,
    this.createdon,
    this.updatedon,
    this.deletedon,
    this.categoria_nombre, // 👈 agregado aquí
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idproducto: json['idproducto'],
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      idunidad: json['idunidad'] ?? 0,
      idcategoria: json['idcategoria'] ?? 0,
      imagen: json['imagen'],
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      stockDisponible: int.tryParse(json['stock_disponible']?.toString() ?? '0') ?? 0,
      createdon: json['createdon'] != null ? DateTime.tryParse(json['createdon']) : null,
      updatedon: json['updatedon'] != null ? DateTime.tryParse(json['updatedon']) : null,
      deletedon: json['deletedon'] != null ? DateTime.tryParse(json['deletedon']) : null,

      // ✅ lo mapeamos desde JSON
      categoria_nombre: json['categoria_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'idunidad': idunidad,
      'idcategoria': idcategoria,
      'imagen': imagen,
      'precio': precio,

      // ✅ opcional, por si lo quieres mandar en alguna parte
      'categoria_nombre': categoria_nombre,
    };
  }
}
