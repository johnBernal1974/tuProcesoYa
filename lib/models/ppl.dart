import 'dart:convert';

// Método para decodificar JSON a Ppl
Ppl pplFromJson(String str) => Ppl.fromJson(json.decode(str));

// Método para codificar Ppl a JSON
String pplToJson(Ppl data) => json.encode(data.toJson());

class Ppl {
  final String id;
  final String nombreAcudiente;
  final String apellidoAcudiente;
  final String parentescoRepresentante;
  final String celular;
  final String email;
  final String nombrePpl;
  final String apellidoPpl;
  final String tipoDocumentoPpl;
  final String numeroDocumentoPpl;
  final String regional;
  final String centroReclusion;
  final String juzgadoEjecucionPenas;
  final String juzgadoEjecucionPenasEmail;
  final String ciudad;
  final String juzgadoQueCondeno;
  final String juzgadoQueCondenoEmail;
  final String delito;
  final String radicado;
  final int tiempoCondena;
  final String td;
  final String nui;
  final String patio;
  final DateTime? fechaCaptura;
  final DateTime? fechaInicioDescuento;
  final String laborDescuento;
  final String status;
  final bool isNotificatedActivated;

  // Constructor
  Ppl({
    required this.id,
    required this.nombreAcudiente,
    required this.apellidoAcudiente,
    required this.parentescoRepresentante,
    required this.celular,
    required this.email,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.tipoDocumentoPpl,
    required this.numeroDocumentoPpl,
    required this.regional,
    required this.centroReclusion,
    required this.juzgadoEjecucionPenas,
    required this.juzgadoEjecucionPenasEmail,
    required this.ciudad,
    required this.juzgadoQueCondeno,
    required this.juzgadoQueCondenoEmail,
    required this.delito,
    required this.radicado,
    required this.tiempoCondena,
    required this.td,
    required this.nui,
    required this.patio,
    required this.fechaCaptura,
    required this.fechaInicioDescuento,
    required this.laborDescuento,
    required this.status,
    required this.isNotificatedActivated,
  });

  // Factory para crear una instancia de Ppl desde JSON
  factory Ppl.fromJson(Map<String, dynamic> json) => Ppl(
    id: json["id"] ?? '',
    nombreAcudiente: json["nombre_acudiente"] ?? '',
    apellidoAcudiente: json["apellido_acudiente"] ?? '',
    parentescoRepresentante: json["parentesco_representante"] ?? '',
    celular: json["celular"] ?? '',
    email: json["email"] ?? '',
    nombrePpl: json["nombre_ppl"] ?? '',
    apellidoPpl: json["apellido_ppl"] ?? '',
    tipoDocumentoPpl: json["tipo_documento_ppl"] ?? '',
    numeroDocumentoPpl: json["numero_documento_ppl"] ?? '',
    regional: json["regional"] ?? '',
    centroReclusion: json["centro_reclusion"] ?? '',
    juzgadoEjecucionPenas: json["juzgado_ejecucion_penas"] ?? '',
    juzgadoEjecucionPenasEmail: json["juzgado_ejecucion_penas_email"] ?? '',
    ciudad: json["ciudad"] ?? '',
    juzgadoQueCondeno: json["juzgado_que_condeno"] ?? '',
    juzgadoQueCondenoEmail: json["juzgado_que_condeno_email"] ?? '',
    delito: json["delito"] ?? '',
    radicado: json["radicado"] ?? '',
    tiempoCondena: json["tiempo_condena"] ?? 0,
    td: json["td"] ?? '',
    nui: json["nui"] ?? '',
    patio: json["patio"] ?? '',
    fechaCaptura: json["fecha_captura"] != null ? DateTime.parse(json["fecha_captura"]) : null,
    fechaInicioDescuento: json["fecha_inicio_descuento"] != null ? DateTime.parse(json["fecha_inicio_descuento"]) : null,
    laborDescuento: json["labor_descuento"] ?? '',
    status: json["status"] ?? '',
    isNotificatedActivated: json["isNotificatedActivated"] ?? false,
  );

  // Método para convertir una instancia de Ppl a JSON
  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre_acudiente": nombreAcudiente,
    "apellido_acudiente": apellidoAcudiente,
    "parentesco_representante": parentescoRepresentante,
    "celular": celular,
    "email": email,
    "nombre_ppl": nombrePpl,
    "apellido_ppl": apellidoPpl,
    "tipo_documento_ppl": tipoDocumentoPpl,
    "numero_documento_ppl": numeroDocumentoPpl,
    "regional": regional,
    "centro_reclusion": centroReclusion,
    "juzgado_ejecucion_penas": juzgadoEjecucionPenas,
    "juzgado_ejecucion_penas_email": juzgadoEjecucionPenasEmail,
    "ciudad": ciudad,
    "juzgado_que_condeno": juzgadoQueCondeno,
    "juzgado_que_condeno_email": juzgadoQueCondenoEmail,
    "delito": delito,
    "radicado": radicado,
    "tiempo_condena": tiempoCondena,
    "td": td,
    "nui": nui,
    "patio": patio,
    "fecha_captura": fechaCaptura?.toIso8601String(),
    "fecha_inicio_descuento": fechaInicioDescuento?.toIso8601String(),
    "labor_descuento": laborDescuento,
    "status": status,
    "isNotificatedActivated": isNotificatedActivated,
  };
}
