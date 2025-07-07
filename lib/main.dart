import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/Pages/administrador/historial_solicitud_traslado_proceso_admin/historial_solicitud_traslado_proceso_admin.dart';
import 'package:tuprocesoya/Pages/client/derecho_de_peticion_solicitud/derecho_de_peticion_solicitud.dart';
import 'package:tuprocesoya/Pages/client/derechos_info/derechos_info.dart';
import 'package:tuprocesoya/Pages/client/historial_solicitudes_acumulacion/historial_solicitudes_acumulacion.dart';
import 'package:tuprocesoya/Pages/detalle_de_correo_page/detalle_correo_acumulacion.dart';
import 'package:tuprocesoya/Pages/nosotros/nosotros_page.dart';
import 'package:tuprocesoya/Pages/splash/splash.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'Pages/administrador/atender_ solicitud_redenciones/atender_ solicitud_redenciones.dart';
import 'Pages/administrador/atender_apelacion/atender_apelacion.dart';
import 'Pages/administrador/atender_derecho_peticion_admin/atender_derecho_peticion_admin.dart';
import 'Pages/administrador/atender_extincion_pena/atender_extincion_pena.dart';
import 'Pages/administrador/atender_libertad_condicional/atender_libertad_condicional.dart';
import 'Pages/administrador/atender_permiso_72horas/atender_permiso_72horas.dart';
import 'Pages/administrador/atender_prision_domiciliaria_admin/atender_prision_domiciliaria_admin.dart';
import 'Pages/administrador/atender_solicitud_acumulacion/atender_solicitud_acumulacion.dart';
import 'Pages/administrador/atender_traslado_proceso_admin/atender_traslado_proceso_admin.dart';
import 'Pages/administrador/atender_tutela_admin/atender_tutela.dart';
import 'Pages/administrador/buzon_sugerencias_administrador/buzon_sugerencias_administrador.dart';
import 'Pages/administrador/editar_registro/editar_registro.dart';
import 'Pages/administrador/historial_solicitudes_acumulacion_admin/historial_solicitudes_acumulacion_admin.dart';
import 'Pages/administrador/historial_solicitudes_apelacion_admin/historial_solicitudes_apelacion_admin.dart';
import 'Pages/administrador/historial_solicitudes_derechos_peticion_admin/historial_solicitudes_derechos_peticion_admin.dart';
import 'Pages/administrador/historial_solicitudes_extincion_pena_admin/historial_solicitudes_extincion_pena_admin.dart';
import 'Pages/administrador/historial_solicitudes_libertad_condicional_admin/historial_solicitudes_libertad_condicional_admin.dart';
import 'Pages/administrador/historial_solicitudes_permiso_72horas_admin/historial_solicitudes_permiso_72horas_admin.dart';
import 'Pages/administrador/historial_solicitudes_prision_domiciliaria_admin/historial_solicitudes_prision_domiciliaria_admin.dart';
import 'Pages/administrador/historial_solicitudes_redenciones_admin/historial_solicitudes_redenciones_admin.dart';
import 'Pages/administrador/historial_solicitudes_tutela_admin/historial_solicitudes_tutela_admin.dart';
import 'Pages/administrador/historial_transacciones_admin/historial_transacciones.dart';
import 'Pages/administrador/home_admin/home_admin.dart';
import 'Pages/administrador/operadores_page_admin/operadores_page.dart';
import 'Pages/administrador/referidores/agregar_referidores.dart';
import 'Pages/administrador/referidores/referidores.dart';
import 'Pages/administrador/registrar_admin/registrar_admin.dart';
import 'Pages/administrador/registro_asistido_admin/registro_asistido_admin.dart';
import 'Pages/administrador/respuesta_sugerencia_admin/respuesta_sugerencia_admin.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/acumulacion_enviadas_por_correo/acumulacion_enviadas_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/derechos_peticion_enviados_por_correo/derechos_peticion_enviados_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/extincion_pena_enviada_por_correo/extincion_perna_enviados_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/libertad_condicional_enviada_por_correo/libertad_condicional_enviada_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/permiso_72horas_enviadas_por_correo/permiso_72horas_enviadas_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/prision_domiciliaria_enviada_por_correo/prision_domiciliaria_enviada_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/redenciones_enviada_por_correo/redenciones_enviada_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/traslado_proceso_enviados_por_correo/traslado_proceso_enviados_por_correo.dart';
import 'Pages/administrador/solicitudes_enviadas_por_correo/tutelas_enviadas_por_correo/tutelas_enviadas_por_correo.dart';
import 'Pages/administrador/terminos_y_condiciones/terminos_y_condiciones.dart';
import 'Pages/administrador/tutelas/derechos_tutelables_page.dart';
import 'Pages/administrador/ver_correos_entrantes/ver_correos_entrantes.dart';
import 'Pages/alimentar_base_datos_temporal/alimentar_base_datos_temporal.dart';
import 'Pages/bloqueado_page/bloqueado.dart';
import 'Pages/client/buzon_sugerencias/buzon_sugerencias.dart';
import 'Pages/client/derecho_de_peticion/derecho_de_peticion.dart';
import 'Pages/client/estamos_validando/estamos_validando.dart';
import 'Pages/client/historial_solicitudes_apelacion/historial_solicitudes_apelacion.dart';
import 'Pages/client/historial_solicitudes_derecho_peticion/historial_solicitudes_derecho_peticion.dart';
import 'Pages/client/historial_solicitudes_extincion_pena/historial_solicitudes_extincion_pena.dart';
import 'Pages/client/historial_solicitudes_libertad_condicional/historial_solicitudes_libertad_condicional.dart';
import 'Pages/client/historial_solicitudes_permiso_72h/historial_solicitudes_permiso_72h.dart';
import 'Pages/client/historial_solicitudes_prision_domiciliaria/historial_solicitudes_prision_domiciliaria.dart';
import 'Pages/client/historial_solicitudes_redenciones/historial_solicitudes_redenciones.dart';
import 'Pages/client/historial_solicitudes_traslado_proceso/historial_solicitudes_traslado_proceso.dart';
import 'Pages/client/historial_solicitudes_tutela/historial_solicitudes_tutela.dart';
import 'Pages/client/historiales_page/historiales_page.dart';
import 'Pages/client/home/home.dart';
import 'Pages/client/info_previa_solicitud_beneficios/info_previa_permiso_72h.dart';
import 'Pages/client/info_previa_solicitud_beneficios/info_previa_solicitud_libertad_condicional.dart';
import 'Pages/client/info_previa_solicitud_beneficios/info_previa_solicitud_prision_domiciliaria.dart';
import 'Pages/client/mis_datos/mis_datos.dart';
import 'Pages/client/mis_redenciones/mis_redenciones.dart';
import 'Pages/client/mis_transacciones/mis_transacciones.dart';
import 'Pages/client/otras_solicitudes/solicitud_acumulacion.dart';
import 'Pages/client/otras_solicitudes/solicitud_apelacion.dart';
import 'Pages/client/otras_solicitudes/solicitud_redenciones.dart';
import 'Pages/client/otras_solicitudes/solicitud_traslado_proceso.dart';
import 'Pages/client/preguntas_frecuentes_page/preguntas_frecuentes_page.dart';
import 'Pages/client/register/register.dart';
import 'Pages/client/solicitar_page/solicitar_page.dart';
import 'Pages/client/solicitud_exitosa_derecho_peticion_page/solicitud_exitosa_derecho_peticion_page.dart';
import 'Pages/client/solicitud_exitosa_domiciliaria/solicitud_exitosa_domiciliaria.dart';
import 'Pages/client/solicitud_exitosa_extincion_pena/solicitud_exitosa_extincion_pena.dart';
import 'Pages/client/solicitud_exitosa_libertad_condicional/solicitud_exitosa_libertad_condicional.dart';
import 'Pages/client/solicitud_exitosa_permiso_72horas/solicitud_exitosa_permiso_72horas.dart';
import 'Pages/client/solicitudes_beneficios/solicitud_72h_page.dart';
import 'Pages/client/solicitudes_beneficios/solicitud_domiciliaria_page.dart';
import 'Pages/client/solicitudes_beneficios/solicitud_extincion_pena.dart';
import 'Pages/client/solicitudes_beneficios/solicitud_libertad_condicional.dart';
import 'Pages/client/tutela/tutela.dart';
import 'Pages/client/tutela_solicitud/tutela_solicitud.dart';
import 'Pages/configuraciones/configuraciones.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_apelacion.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_condicional.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_domiciliaria.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_extincion_pena.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_permiso_72horas.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_redenciones.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_traslado_proceso.dart';
import 'Pages/detalle_de_correo_page/detalle_correo_tutela.dart';
import 'Pages/detalle_de_correo_page/detalle_de_correo_page.dart';
import 'Pages/landing_page/info_page.dart';
import 'Pages/login/login.dart';
import 'Pages/recuperar_cuenta/recuperar_cuenta.dart';
import 'commons/wompi/checkout_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:async';


final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
Map<String, dynamic> envVars = {}; // 🔹 Variable global para almacenar las variables de entorno

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que la inicialización esté completa antes de correr la app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final config = await obtenerFirebaseConfig();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: config['apiKey'],
      authDomain: config['authDomain'],
      projectId: config['projectId'],
      storageBucket: config['storageBucket'],
      appId: config['appId'],
      messagingSenderId: config['messagingSenderId'],
    ),
  );

  WebViewPlatform.instance = WebWebViewPlatform();

  runApp(const MyApp());

}


Future<Map<String, dynamic>> obtenerFirebaseConfig() async {
  final response = await http.get(
    Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getFirestoreConfig"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Error obteniendo configuración: ${response.statusCode}");
  }
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'Tu Proceso Ya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primary, // Color personalizado
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ).copyWith(
          secondary: Colors.deepPurpleAccent, // Color secundario
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),

        ),
      ),
      initialRoute: 'splash', // Ruta inicial
      routes: {
        //administrador
        'editar_registro_admin': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args is DocumentSnapshot) {
            return EditarRegistroPage(doc: args);
          } else {
            return const Scaffold(
              backgroundColor: blanco,
              body: Center(
                child: Text(
                  '❌ Error: No se proporcionó el documento necesario.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
        },
        'home_admin': (context) => const HomeAdministradorPage(),
        'buzon_sugerencias_administrador': (context) => const BuzonSugerenciasAdministradorPage(),
        'historial_solicitudes_derecho_peticion_admin': (context) => const HistorialSolicitudesDerechoPeticionAdminPage(),
        'historial_solicitudes_tutelas_admin': (context) => const HistorialSolicitudesTutelaPageAdmin(),
        'historial_solicitudes_prision_domiciliaria_admin': (context) => const HistorialSolicitudesDomiciliariaAdminPage(),
        'historial_solicitudes_libertad_condicional_admin': (context) => const HistorialSolicitudesCondicionalAdminPage(),
        'historial_solicitudes_permiso_72horas_admin': (context) => const HistorialSolicitudesPermiso72HorasAdminPage(),
        'historial_solicitudes_extincion_pena_admin': (context) => const HistorialSolicitudesExtincionPenaAdminPage(),
        'historial_solicitudes_traslado_proceso_admin': (context) => const HistorialSolicitudesTrasladoProcesoAdminPage(),
        'historial_solicitudes_redenciones_admin': (context) => const HistorialSolicitudesRedencionesAdminPage(),
        'historial_solicitudes_acumulacion_admin': (context) => const HistorialSolicitudesAcumulacionAdminPage(),
        'historial_solicitudes_apelacion_admin': (context) => const HistorialSolicitudesApelacionAdminPage(),
        'registrar_operadores': (context) => const RegistrarOperadoresPage(),
        'operadores_page': (context) => const OperadoresPage(),
        'admin_transacciones': (context) => const AdminTransaccionesPage(),
        'configuraciones': (context) => ConfiguracionesPage(),
        'derechos_tutelables_page': (context) => const DerechosTutelablesPage(),
        'referidores_page_admin': (context) => const AdminReferidoresPage(),
        'registrar_referidores_page_admin': (context) => const RegistrarReferidorPage(),
        'registraro_asistido_page_admin': (context) => const RegistroAsistidoPage(),
        'ver_respuestas_correos_page_admin': (context) => const VerRespuestasCorreosPage(),

        //Usuario
        'home': (context) => const HomePage(), // Página principal
        'register': (context) => RegistroPage(),
        'mis_datos': (context) => const MisDatosPage(),
        'nosotros': (context) => const NosotrosPage(),
        'derecho_peticion_solicitud': (context) => const DerechoDePeticionSolicitudPage(),
        'historial_solicitudes_derechos_peticion': (context) => const HistorialSolicitudesDerechosPeticionPage(),
        'historial_solicitudes_prision_domiciliaria': (context) => const HistorialSolicitudesPrisionDomiciliariaPage(),
        'historial_solicitudes_libertad_condicional': (context) => const HistorialSolicitudesLibertadCondicionalPage(),
        'historial_solicitudes_tutela': (context) => const HistorialSolicitudesTutelaPage(),
        'historial_solicitudes_permiso_72horas': (context) => const HistorialSolicitudesPermiso72HorasPage(),
        'historial_solicitudes_extincion_pena': (context) => const HistorialSolicitudesExtincionPenaPage(),
        'historial_solicitudes_traslado_proceso': (context) => const HistorialSolicitudesTrasladoProcesoPage(),
        'historial_solicitudes_redenciones': (context) => const HistorialSolicitudesRedencionesPage(),
        'historial_solicitudes_acumulacion': (context) => const HistorialSolicitudesAcumulacionPage(),
        'historial_solicitudes_apelacion': (context) => const HistorialSolicitudesApelacionPage(),
        'estamos_validando': (context) => EstamosValidandoPage(),
        'derechos_info': (context) => const DerechosInfoPage(),
        'buzon_sugerencias': (context) => const BuzonSugerenciasPage(),
        'forgot_password': (context) => const RecuperarCuentaPage(),
        'mis_redenciones': (context) => const HistorialRedencionesPage(),
        'terminos_y_condiciones': (context) => const TerminosCondicionesPage(),
        //'checkout_wompi': (context) => const CheckoutPage(),
        'mis_transacciones': (context) => const MisTransaccionesPage(),
        'solicitud_72h_page': (context) => const SolicitudPermiso72HorasPage(),
        'solicitud_domiciliaria_page': (context) => const SolicitudDomiciliariaPage(),
        'solicitud_condicional_page': (context) => const SolicitudLibertadCondicionalPage(),
        'solicitud_extincion_pena_page': (context) => const SolicitudExtincionPenaPage(),
        'solicitud_traslado_proceso_page': (context) => const SolicitudTrasladoProcesoPage(),
        'solicitud_redenciones_page': (context) => const SolicitudRedencionPage(),
        'solicitud_acumulacion_page': (context) => const SolicitudAcumulacionPenasPage(),
        'solicitud_apelacion_page': (context) => const SolicitudApelacionPage(),
        'info_previa_solicitud_domiciliaria_page': (context) => const RequisitosPrisionDomiciliariaPage(),
        'info_previa_libertad_condicional_page': (context) => const RequisitosLibertadCondicionalPage(),
        'info_previa_72h_page': (context) => const RequisitosPermiso72hPage(),
        'historiales_page': (context) => HistorialSolicitudesPage(),
        'preguntas_frecuentes_page': (context) => const PreguntasFrecuentesPage(),
        'solicitar_page': (context) => SolicitarServiciosPage(),


        //general
        'login': (context) => const LoginPage(),
        'splash': (context) => SplashPage(),
        'cargar_info': (context) => AddDelitoPage(),
        'derecho_peticion': (context) => const DerechoDePeticionPage(),
        'tutela': (context) => const TutelaPage(),
        'tutela_solicitud': (context) => const TutelaSolicitudPage(),
        'info': (context) => const InfoPage(),
        'bloqueo_page': (context) => const BloqueadoPage(),

      },
        onGenerateRoute: (settings) {
          if (settings.name == 'respuesta_sugerencia_page_admin') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => RespuestaSugerenciaPage(
                userId: args['userId'],
                nombre: args['nombre'],
                sugerencia: args['sugerencia'],
                celular: args['celular'],
              ),
            );
          }
          else if (settings.name == 'solicitud_exitosa_derecho_peticion') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaDerechoPeticionPage(
                numeroSeguimiento: numeroSeguimiento,
              ),
            );
          }
          else if (settings.name == 'solicitud_exitosa_permiso_72horas') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaPermiso72HorasPage(
                numeroSeguimiento: numeroSeguimiento,
              ),
            );
          }
          else if (settings.name == 'solicitud_exitosa_prision_domiciliaria') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaDomiciliariaPage(
                numeroSeguimiento: numeroSeguimiento,
              ),
            );
          }
          else if (settings.name == 'solicitud_exitosa_libertad_condicional') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaLibertadCondicionalPage(
                numeroSeguimiento: numeroSeguimiento,
              ),
            );
          }
          else if (settings.name == 'solicitud_exitosa_extincion_pena') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaExtincionPenaPage(
                numeroSeguimiento: numeroSeguimiento,
              ),
            );
          }

          else if (settings.name == 'derechos_peticion_enviados_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DerechoSPeticionEnviadosPorCorreoPage(
                status: args['status'] ?? "Diligenciado",  // 👈 Evita error si es null
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'],
                subcategoria: args['subcategoria'],
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                preguntas: List<String>.from(args['preguntas'] ?? []), // Pasar preguntas
                respuestas: List<String>.from(args['respuestas'] ?? []), // Pasar respuestas
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }
          else if (settings.name == 'tutela_enviados_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => TutelasEnviadosPorCorreoPage(
                status: args['status'] ?? "Diligenciado",  // 👈 Evita error si es null
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'],
                subcategoria: args['subcategoria'],
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                preguntas: List<String>.from(args['preguntas'] ?? []), // Pasar preguntas
                respuestas: List<String>.from(args['respuestas'] ?? []), // Pasar respuestas
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }
          else if (settings.name == 'solicitudes_permiso_72_horas_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesPermiso72HorasEnviadasPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Prisión domiciliaria",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable'],
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),

                // 🟢 Usa las claves correctas aquí
                direccion: args['direccion'] ?? "",
                municipio: args['municipio'] ?? "",
                departamento: args['departamento'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "", // <== ✅ aquí cambia
                cedulaResponsable: args['cedulaResponsable'] ?? "", // <== ✅ aquí cambia
                celularResponsable: args['celularResponsable'] ?? "",
                sinRespuesta: args['sinRespuesta'] ?? false,
                reparacion: args['reparacion'] ?? "",
              ),
            );
          }
          else if (settings.name == 'solicitudes_prision_domiciliaria_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Prisión domiciliaria",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable'],
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),

                // 🟢 Usa las claves correctas aquí
                direccion: args['direccion'] ?? "",
                municipio: args['municipio'] ?? "",
                departamento: args['departamento'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "", // <== ✅ aquí cambia
                cedulaResponsable: args['cedulaResponsable'] ?? "", // <== ✅ aquí cambia
                celularResponsable: args['celularResponsable'] ?? "",
                sinRespuesta: args['sinRespuesta'] ?? false,
                reparacion: args['reparacion'] ?? "",
              ),
            );

          }
          else if (settings.name == 'solicitudes_libertad_condicional_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesLibertadCondicionalEnviadasPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Prisión domiciliaria",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable'],
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),

                // 🟢 Usa las claves correctas aquí
                direccion: args['direccion'] ?? "",
                municipio: args['municipio'] ?? "",
                departamento: args['departamento'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "", // <== ✅ aquí cambia
                cedulaResponsable: args['cedulaResponsable'] ?? "", // <== ✅ aquí cambia
                celularResponsable: args['celularResponsable'] ?? "",
                sinRespuesta: args['sinRespuesta'] ?? false,
                reparacion: args['reparacion'] ?? "",
              ),
            );
          }

          else if (settings.name == 'solicitudes_extincion_pena_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesExincionPenaPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Extinción de la pena",
                fecha: args['fecha'],
                idUser: args['idUser'],
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }
          else if (settings.name == 'solicitudes_traslado_proceso_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesTrasladoProcesoPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Extinción de la pena",
                fecha: args['fecha'],
                idUser: args['idUser'],
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }
          else if (settings.name == 'solicitudes_redencion_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesRedencionPenaPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Redención de pena",
                fecha: args['fecha'],
                idUser: args['idUser'],
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }
          else if (settings.name == 'solicitudes_acumulacion_enviadas_por_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SolicitudesAcumulacionEnviadasPorCorreoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'] ?? "Beneficios penitenciarios",
                subcategoria: args['subcategoria'] ?? "Redención de pena",
                fecha: args['fecha'],
                idUser: args['idUser'],
                sinRespuesta: args['sinRespuesta'] ?? false,
              ),
            );
          }

          else if (settings.name == 'atender_derecho_peticion_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderDerechoPeticionPage(
                status: args['status'] ?? "Diligenciado",  // 👈 Evita error si es null
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'],
                subcategoria: args['subcategoria'],
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                preguntas: List<String>.from(args['preguntas'] ?? []), // Pasar preguntas
                respuestas: List<String>.from(args['respuestas'] ?? []), // Pasar respuestas
              ),
            );
          }
          else if (settings.name == 'atender_tutela_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderTutelaPage(
                status: args['status'] ?? "Diligenciado",  // 👈 Evita error si es null
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'],
                categoria: args['categoria'],
                subcategoria: args['subcategoria'],
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                preguntas: List<String>.from(args['preguntas'] ?? []), // Pasar preguntas
                respuestas: List<String>.from(args['respuestas'] ?? []), // Pasar respuestas
              ),
            );
          }
          else if (settings.name == 'atender_solicitud_permiso_72_horas_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderPermiso72HorasPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                direccion: args['direccion'] ?? "",
                departamento: args['departamento'] ?? "",
                municipio: args['municipio'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "",
                cedulaResponsable: args['cedulaResponsable'] ?? "",
                celularResponsable: args['celularResponsable'] ?? "",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable']?.toString(),
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),
                parentesco: args['parentesco'] ?? "",
                reparacion: args['reparacion'] ?? "",
              ),
            );
          }
          else if (settings.name == 'atender_solicitud_prision_domiciliaria_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderPrisionDomiciliariaPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                direccion: args['direccion'] ?? "",
                departamento: args['departamento'] ?? "",
                municipio: args['municipio'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "",
                cedulaResponsable: args['cedulaResponsable'] ?? "",
                celularResponsable: args['celularResponsable'] ?? "",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable']?.toString(),
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),
                parentesco: args['parentesco'] ?? "",
                reparacion: args['reparacion'] ?? "",
              ),
            );
          }
          else if (settings.name == 'atender_solicitud_libertad_condicional_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderLibertadCondicionalPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                direccion: args['direccion'] ?? "",
                departamento: args['departamento'] ?? "",
                municipio: args['municipio'] ?? "",
                nombreResponsable: args['nombreResponsable'] ?? "",
                cedulaResponsable: args['cedulaResponsable'] ?? "",
                celularResponsable: args['celularResponsable'] ?? "",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
                urlArchivoCedulaResponsable: args['urlArchivoCedulaResponsable']?.toString(),
                urlsArchivosHijos: List<String>.from(args['urlsArchivosHijos'] ?? []),
                parentesco: args['parentesco'] ?? "",
                reparacion: args['reparacion'] ?? "",
              ),
            );
          }
          else if (settings.name == 'atender_extincion_pena_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderExtincionPenaPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                fecha: args['fecha'],
                idUser: args['idUser'],
              ),
            );
          }
          else if (settings.name == 'atender_traslado_proceso_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderTrasladoProcesoPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                fecha: args['fecha'],
                idUser: args['idUser'],
                fechaTraslado: args['fechaTraslado'],
                centroOrigen: args['centroOrigen'],
                ciudadOrigen: args['ciudadOrigen'],
                centroDestino: args['centroDestino'],
                ciudadDestino: args['ciudadDestino'],
              ),
            );
          }
          else if (settings.name == 'atender_redencion_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderSolicitudRedencionesPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                fecha: args['fecha'],
                idUser: args['idUser'],
              ),
            );
          }

          else if (settings.name == 'atender_acumulacion_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderSolicitudAcumulacionPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                fecha: args['fecha'],
                idUser: args['idUser'],
              ),
            );
          }

          else if (settings.name == 'atender_apelacion_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderApelacionPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numeroSeguimiento'] ?? "Sin seguimiento",
                fecha: args['fecha'],
                idUser: args['idUser'], archivos: [],
              ),
            );
          }


          else if (settings.name == 'detalle_correo') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_tutela') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoTutelaPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_permiso_72horas') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoPermiso72HorasPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_prision_domiciliaria') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoDomiciliariaPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_libertad_condicional') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoCondicionalPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_extincion_pena') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoExtincionPenaPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_traslado_proceso') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoTrasladoProcesoPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_redenciones') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoRedencionesPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_acumulacion') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoAcumulacionPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == 'detalle_correo_apelacion') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleCorreoApelacionPage(
                idDocumento: args['idDocumento'],
                correoId: args['correoId'],
              ),
            );
          }
          else if (settings.name == '/checkout_wompi') {
            final args = settings.arguments as Map<String, dynamic>;

            return MaterialPageRoute(
              builder: (_) => CheckoutPage(
                tipoPago: args['tipoPago'],
                valor: args['valor'],
                onTransaccionAprobada: args['onTransaccionAprobada'],
              ),
            );
          }
          else if (settings.name == '/info') {
            return MaterialPageRoute(builder: (context) => const InfoPage());
          }
          return null; // Manejar rutas desconocidas si es necesario
        },
        localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('es', ''), // Spanish, no country code
      ],
    );
  }
}
