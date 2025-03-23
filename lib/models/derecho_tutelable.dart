class DerechoTutelable {
  final String id;
  final String titulo;
  final String descripcion;
  final List<Fundamento> fundamentos;
  final List<String> pretensiones;

  DerechoTutelable({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fundamentos,
    required this.pretensiones,
  });

  factory DerechoTutelable.fromJson(Map<String, dynamic> json) {
    return DerechoTutelable(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fundamentos: (json['fundamentos'] as List)
          .map((f) => Fundamento.fromJson(f))
          .toList(),
      pretensiones: List<String>.from(json['pretensiones']),
    );
  }
}

class Fundamento {
  final String tipo;
  final String titulo;
  final String detalle;

  Fundamento({
    required this.tipo,
    required this.titulo,
    required this.detalle,
  });

  factory Fundamento.fromJson(Map<String, dynamic> json) {
    return Fundamento(
      tipo: json['tipo'],
      titulo: json['titulo'],
      detalle: json['detalle'],
    );
  }
}
