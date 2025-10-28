class DetalleProducto {
  final int id;
  final int idproducto;
  final String atributo;
  final String valor;
  final DateTime createdon;
  final DateTime updatedon;
  final DateTime? deletedon;
  final int cantidad;

  DetalleProducto({
    required this.id,
    required this.idproducto,
    required this.atributo,
    required this.valor,
    required this.createdon,
    required this.updatedon,
    this.deletedon,
    required this.cantidad,
  });

  factory DetalleProducto.fromJson(Map<String, dynamic> json) {
    return DetalleProducto(
      id: json['id'],
      idproducto: json['idproducto'],
      atributo: json['atributo'],
      valor: json['valor'],
      createdon: DateTime.parse(json['createdon']),
      updatedon: DateTime.parse(json['updatedon']),
      deletedon: json['deletedon'] != null ? DateTime.tryParse(json['deletedon']) : null,
      cantidad: json['cantidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idproducto': idproducto,
      'atributo': atributo,
      'valor': valor,
      'cantidad': cantidad,
    };
  }
}
