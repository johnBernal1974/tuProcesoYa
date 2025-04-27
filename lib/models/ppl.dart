import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String categoriaDelDelito;
  final String delito;
  final String radicado;
  final int tiempoCondena;
  final String td;
  final String nui;
  final String patio;
  final DateTime? fechaCaptura;
  final String status;
  final bool isNotificatedActivated;
  final bool isPaid;
  final String assignedTo;
  final DateTime? fechaRegistro;
  final String departamento;
  final String municipio;
  final String direccion;
  final String situacion;
  final List<String> beneficiosAdquiridos;
  final List<String> beneficiosNegados;

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
    required this.categoriaDelDelito,
    required this.delito,
    required this.radicado,
    required this.tiempoCondena,
    required this.td,
    required this.nui,
    required this.patio,
    required this.fechaCaptura,
    required this.status,
    required this.isNotificatedActivated,
    required this.isPaid,
    required this.assignedTo,
    required this.fechaRegistro,
    required this.departamento,
    required this.municipio,
    required this.direccion,
    required this.situacion,
    required this.beneficiosAdquiridos,
    required this.beneficiosNegados,
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
    categoriaDelDelito: json["categoria_delito"] ?? '',
    delito: json["delito"] ?? '',
    radicado: json["radicado"] ?? '',
    tiempoCondena: json["tiempo_condena"] ?? 0,
    td: json["td"] ?? '',
    nui: json["nui"] ?? '',
    patio: json["patio"] ?? '',
    fechaCaptura: json["fecha_captura"] != null
        ? (json["fecha_captura"] is String
        ? DateTime.tryParse(json["fecha_captura"]) // Si es String, intentar parsear
        : (json["fecha_captura"] is Timestamp
        ? json["fecha_captura"].toDate() // Si es Timestamp, convertir a DateTime
        : null)) // Si no es ni String ni Timestamp, devolver null
        : null,

    status: json["status"] ?? '',
    isNotificatedActivated: json["isNotificatedActivated"] ?? false,
    isPaid: json["isPaid"] ?? false,
    assignedTo: json["assignedTo"] ?? "",
    fechaRegistro: json["fechaRegistro"] != null
        ? (json["fechaRegistro"] is String
        ? DateTime.tryParse(json["fechaRegistro"]) // Si es String, intentar parsear
        : (json["fechaRegistro"] is Timestamp
        ? json["fechaRegistro"].toDate() // Si es Timestamp, convertir a DateTime
        : null)) // Si no es ni String ni Timestamp, devolver null
        : null,
    departamento: json["departamento"] ?? '',
    municipio: json["municipio"] ?? '',
    direccion: json["direccion"] ?? '',
    situacion: json["situacion"] ?? '',
    beneficiosAdquiridos: List<String>.from(json["beneficiosAdquiridos"] ?? []),
    beneficiosNegados: List<String>.from(json["beneficiosNegados"] ?? []),

  );

  // Factory para crear Ppl directamente desde Firestore
  factory Ppl.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Ppl(
      id: doc.id,
      nombreAcudiente: data["nombre_acudiente"] ?? '',
      apellidoAcudiente: data["apellido_acudiente"] ?? '',
      parentescoRepresentante: data["parentesco_representante"] ?? '',
      celular: data["celular"] ?? '',
      email: data["email"] ?? '',
      nombrePpl: data["nombre_ppl"] ?? '',
      apellidoPpl: data["apellido_ppl"] ?? '',
      tipoDocumentoPpl: data["tipo_documento_ppl"] ?? '',
      numeroDocumentoPpl: data["numero_documento_ppl"] ?? '',
      regional: data["regional"] ?? '',
      centroReclusion: data["centro_reclusion"] ?? '',
      juzgadoEjecucionPenas: data["juzgado_ejecucion_penas"] ?? '',
      juzgadoEjecucionPenasEmail: data["juzgado_ejecucion_penas_email"] ?? '',
      ciudad: data["ciudad"] ?? '',
      juzgadoQueCondeno: data["juzgado_que_condeno"] ?? '',
      juzgadoQueCondenoEmail: data["juzgado_que_condeno_email"] ?? '',
      categoriaDelDelito: data["categoria_delito"] ?? '',
      delito: data["delito"] ?? '',
      radicado: data["radicado"] ?? '',
      tiempoCondena: data["tiempo_condena"] ?? 0,
      td: data["td"] ?? '',
      nui: data["nui"] ?? '',
      patio: data["patio"] ?? '',
      fechaCaptura: data["fecha_captura"] != null
          ? (data["fecha_captura"] is String
          ? DateTime.tryParse(data["fecha_captura"])
          : (data["fecha_captura"] is Timestamp
          ? (data["fecha_captura"] as Timestamp).toDate()
          : null))
          : null,
      status: data["status"] ?? '',
      isNotificatedActivated: data["isNotificatedActivated"] ?? false,
      isPaid: data["isPaid"] ?? false,
      assignedTo: data["assignedTo"] ?? '',
      fechaRegistro: data["fechaRegistro"] != null
          ? (data["fechaRegistro"] is String
          ? DateTime.tryParse(data["fechaRegistro"])
          : (data["fechaRegistro"] is Timestamp
          ? (data["fechaRegistro"] as Timestamp).toDate()
          : null))
          : null,
      departamento: data["departamento"] ?? '',
      municipio: data["municipio"] ?? '',
      direccion: data["direccion"] ?? '',
      situacion: data["situacion"] ?? '',
      beneficiosAdquiridos: List<String>.from(data["beneficiosAdquiridos"] ?? []),
      beneficiosNegados: List<String>.from(data["beneficiosNegados"] ?? []),
    );
  }


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
    "categoria_delito": categoriaDelDelito,
    "delito": delito,
    "radicado": radicado,
    "tiempo_condena": tiempoCondena,
    "td": td,
    "nui": nui,
    "patio": patio,
    "fecha_captura": fechaCaptura?.toIso8601String(),
    "status": status,
    "isNotificatedActivated": isNotificatedActivated,
    "isPaid": isPaid,
    "assignedTo": assignedTo,
    "fechaRegistro": fechaRegistro,
    "departamento": departamento,
    "municipio": municipio,
    "direccion": direccion,
    "situacion": situacion,
    "beneficiosAdquiridos": beneficiosAdquiridos,
    "beneficiosNegados": beneficiosNegados,
  };
}
