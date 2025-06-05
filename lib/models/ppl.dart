import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

Ppl pplFromJson(String str) => Ppl.fromJson(json.decode(str));
String pplToJson(Ppl data) => json.encode(data.toJson());

class Ppl {
  final String id;
  final String nombreAcudiente;
  final String apellidoAcudiente;
  final String parentescoRepresentante;
  final String celular;
  final String celularWhatsapp;
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
  final int mesesCondena;
  final int diasCondena;
  final String td;
  final String nui;
  final String patio;
  final DateTime? fechaCaptura;
  final String status;
  final bool isNotificatedActivated;
  final bool isPaid;
  final String assignedTo;
  final DateTime? fechaRegistro;
  final DateTime? fechaActivacion;
  final String departamento;
  final String municipio;
  final String direccion;
  final String situacion;
  final String version;
  final bool exento;
  final List<String> beneficiosAdquiridos;
  final List<String> beneficiosNegados;

  Ppl({
    required this.id,
    required this.nombreAcudiente,
    required this.apellidoAcudiente,
    required this.parentescoRepresentante,
    required this.celular,
    required this.celularWhatsapp,
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
    required this.mesesCondena,
    required this.diasCondena,
    required this.td,
    required this.nui,
    required this.patio,
    required this.fechaCaptura,
    required this.status,
    required this.isNotificatedActivated,
    required this.isPaid,
    required this.assignedTo,
    required this.fechaRegistro,
    required this.fechaActivacion,
    required this.departamento,
    required this.municipio,
    required this.direccion,
    required this.situacion,
    required this.version,
    required this.exento,
    required this.beneficiosAdquiridos,
    required this.beneficiosNegados,
  });

  factory Ppl.fromJson(Map<String, dynamic> json) => Ppl(
    id: json["id"] ?? '',
    nombreAcudiente: json["nombre_acudiente"] ?? '',
    apellidoAcudiente: json["apellido_acudiente"] ?? '',
    parentescoRepresentante: json["parentesco_representante"] ?? '',
    celular: json["celular"] ?? '',
    celularWhatsapp: json["celularWhatsapp"] ?? '',
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
    mesesCondena: json["meses_condena"] ?? 0,
    diasCondena: json["dias_condena"] ?? 0,
    td: json["td"] ?? '',
    nui: json["nui"] ?? '',
    patio: json["patio"] ?? '',
    fechaCaptura: json["fecha_captura"] != null
        ? (json["fecha_captura"] is String
        ? DateTime.tryParse(json["fecha_captura"])
        : (json["fecha_captura"] is Timestamp
        ? json["fecha_captura"].toDate()
        : null))
        : null,
    status: json["status"] ?? '',
    isNotificatedActivated: json["isNotificatedActivated"] ?? false,
    isPaid: json["isPaid"] ?? false,
    assignedTo: json["assignedTo"] ?? "",
    fechaRegistro: json["fechaRegistro"] != null
        ? (json["fechaRegistro"] is String
        ? DateTime.tryParse(json["fechaRegistro"])
        : (json["fechaRegistro"] is Timestamp
        ? json["fechaRegistro"].toDate()
        : null))
        : null,
    fechaActivacion: json["fechaActivacion"] != null
        ? (json["fechaActivacion"] is String
        ? DateTime.tryParse(json["fechaActivacion"])
        : (json["fechaActivacion"] is Timestamp
        ? json["fechaActivacion"].toDate()
        : null))
        : null,
    departamento: json["departamento"] ?? '',
    municipio: json["municipio"] ?? '',
    direccion: json["direccion"] ?? '',
    situacion: json["situacion"] ?? '',
    version: json["version"] ?? '',
    exento: json["exento"] ?? false,
    beneficiosAdquiridos:
    List<String>.from(json["beneficiosAdquiridos"] ?? []),
    beneficiosNegados:
    List<String>.from(json["beneficiosNegados"] ?? []),
  );

  factory Ppl.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Ppl(
      id: doc.id,
      nombreAcudiente: data["nombre_acudiente"] ?? '',
      apellidoAcudiente: data["apellido_acudiente"] ?? '',
      parentescoRepresentante: data["parentesco_representante"] ?? '',
      celular: data["celular"] ?? '',
      celularWhatsapp: data["celularWhatsapp"] ?? '',
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
      mesesCondena: data["meses_condena"] ?? 0,
      diasCondena: data["dias_condena"] ?? 0,
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
      fechaActivacion: data["fechaActivacion"] != null
          ? (data["fechaActivacion"] is String
          ? DateTime.tryParse(data["fechaActivacion"])
          : (data["fechaActivacion"] is Timestamp
          ? (data["fechaActivacion"] as Timestamp).toDate()
          : null))
          : null,
      departamento: data["departamento"] ?? '',
      municipio: data["municipio"] ?? '',
      direccion: data["direccion"] ?? '',
      situacion: data["situacion"] ?? '',
      version: data["version"] ?? '',
      exento: data["exento"] ?? false,
      beneficiosAdquiridos:
      List<String>.from(data["beneficiosAdquiridos"] ?? []),
      beneficiosNegados: List<String>.from(data["beneficiosNegados"] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre_acudiente": nombreAcudiente,
    "apellido_acudiente": apellidoAcudiente,
    "parentesco_representante": parentescoRepresentante,
    "celular": celular,
    "celularWhatsapp": celularWhatsapp,
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
    "meses_condena": mesesCondena,
    "dias_condena": diasCondena,
    "td": td,
    "nui": nui,
    "patio": patio,
    "fecha_captura": fechaCaptura?.toIso8601String(),
    "status": status,
    "isNotificatedActivated": isNotificatedActivated,
    "isPaid": isPaid,
    "assignedTo": assignedTo,
    "fechaRegistro": fechaRegistro,
    "fechaActivacion": fechaActivacion,
    "departamento": departamento,
    "municipio": municipio,
    "direccion": direccion,
    "situacion": situacion,
    "version": version,
    "exento": exento,
    "beneficiosAdquiridos": beneficiosAdquiridos,
    "beneficiosNegados": beneficiosNegados,
  };

  // Método auxiliar (opcional)
  double get condenaTotalEnMeses => mesesCondena + (diasCondena / 30.0);
}
