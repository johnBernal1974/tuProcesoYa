import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/Pages/client/derecho_de_peticion_solicitud/derecho_de_peticion_solicitud.dart';
import 'package:tuprocesoya/Pages/client/derechos_info/derechos_info.dart';
import 'package:tuprocesoya/Pages/nosotros/nosotros_page.dart';
import 'package:tuprocesoya/Pages/splash/splash.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'Pages/administrador/atender_derecho_peticion_admin/atender_derecho_peticion_admin.dart';
import 'Pages/administrador/atender_prision_domiciliaria_admin/atender_prision_domiciliaria_admin.dart';
import 'Pages/administrador/atender_tutela_admin/atender_tutela.dart';
import 'Pages/administrador/buzon_sugerencias_administrador/buzon_sugerencias_administrador.dart';
import 'Pages/administrador/derechos_peticion_enviados_por_correo/derechos_peticion_enviados_por_correo.dart';
import 'Pages/administrador/editar_registro/editar_registro.dart';
import 'Pages/administrador/historial_solicitudes_derechos_peticion_admin/historial_solicitudes_derechos_peticion_admin.dart';
import 'Pages/administrador/historial_solicitudes_prision_domiciliaria_admin/historial_solicitudes_prision_domiciliaria_admin.dart';
import 'Pages/administrador/historial_solicitudes_tutela_admin/historial_solicitudes_tutela_admin.dart';
import 'Pages/administrador/historial_transacciones_admin/historial_transacciones.dart';
import 'Pages/administrador/home_admin/home_admin.dart';
import 'Pages/administrador/operadores_page_admin/operadores_page.dart';
import 'Pages/administrador/registrar_admin/registrar_admin.dart';
import 'Pages/administrador/respuesta_sugerencia_admin/respuesta_sugerencia_admin.dart';
import 'Pages/administrador/terminos_y_condiciones/terminos_y_condiciones.dart';
import 'Pages/administrador/tutelas/derechos_tutelables_page.dart';
import 'Pages/alimentar_base_datos_temporal/alimentar_base_datos_temporal.dart';
import 'Pages/bloqueado_page/bloqueado.dart';
import 'Pages/client/buzon_sugerencias/buzon_sugerencias.dart';
import 'Pages/client/derecho_de_peticion/derecho_de_peticion.dart';
import 'Pages/client/estamos_validando/estamos_validando.dart';
import 'Pages/client/historial_solicitudes_derecho_peticion/historial_solicitudes_derecho_peticion.dart';
import 'Pages/client/home/home.dart';
import 'Pages/client/mis_datos/mis_datos.dart';
import 'Pages/client/mis_redenciones/mis_redenciones.dart';
import 'Pages/client/mis_transacciones/mis_transacciones.dart';
import 'Pages/client/register/register.dart';
import 'Pages/client/solicitud_exitosa_derecho_peticion_page/solicitud_exitosa_derecho_peticion_page.dart';
import 'Pages/client/solicitud_exitosa_domiciliaria/solicitud_exitosa_domiciliaria.dart';
import 'Pages/client/solicitudes_beneficios/solicitud_domiciliaria_page.dart';
import 'Pages/client/tutela/tutela.dart';
import 'Pages/client/tutela_solicitud/tutela_solicitud.dart';
import 'Pages/configuraciones/configuraciones.dart';
import 'Pages/detalle_de_correo_page/detalle_de_correo_page.dart';
import 'Pages/landing_page/info_page.dart';
import 'Pages/login/login.dart';
import 'Pages/recuperar_cuenta/recuperar_cuenta.dart';
import 'commons/wompi/checkout_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;


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

  // Luego corre la aplicación
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
          final doc = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
          return EditarRegistroPage(doc: doc);
        },
        'home_admin': (context) => const HomeAdministradorPage(),
        'buzon_sugerencias_administrador': (context) => const BuzonSugerenciasAdministradorPage(),
        'historial_solicitudes_derecho_peticion_admin': (context) => const HistorialSolicitudesDerechoPeticionAdminPage(),
        'historial_solicitudes_tutelas_admin': (context) => const HistorialSolicitudesTutelaPageAdmin(),
        'historial_solicitudes_prision_domiciliaria_admin': (context) => const HistorialSolicitudesDomiciliariaAdminPage(),
        'registrar_operadores': (context) => const RegistrarOperadoresPage(),
        'operadores_page': (context) => const OperadoresPage(),
        'admin_transacciones': (context) => const AdminTransaccionesPage(),
        'configuraciones': (context) => ConfiguracionesPage(),
        'derechos_tutelables_page': (context) => const DerechosTutelablesPage(),

        //Usuario
        'home': (context) => const HomePage(), // Página principal
        'register': (context) => RegistroPage(),
        'mis_datos': (context) => const MisDatosPage(),
        'nosotros': (context) => const NosotrosPage(),
        'derecho_peticion_solicitud': (context) => const DerechoDePeticionSolicitudPage(),
        'historial_solicitudes_derechos_peticion': (context) => const HistorialSolicitudesDerechosPeticionPage(),
        'estamos_validando': (context) => EstamosValidandoPage(),
        'derechos_info': (context) => const DerechosInfoPage(),
        'buzon_sugerencias': (context) => const BuzonSugerenciasPage(),
        'forgot_password': (context) => const RecuperarCuentaPage(),
        'mis_redenciones': (context) => const HistorialRedencionesPage(),
        'terminos_y_condiciones': (context) => const TerminosCondicionesPage(),
        //'checkout_wompi': (context) => const CheckoutPage(),
        'mis_transacciones': (context) => const MisTransaccionesPage(),
        'solicitud_72h_page': (context) => const MisTransaccionesPage(),
        'solicitud_domiciliaria_page': (context) => const SolicitudDomiciliariaPage(),


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
          } else if (settings.name == 'solicitud_exitosa_derecho_peticion') {
            final numeroSeguimiento = settings.arguments as String; // Recibe el argumento
            return MaterialPageRoute(
              builder: (context) => SolicitudExitosaDerechoPeticionPage(
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
          else if (settings.name == 'atender_solicitud_prision_domiciliaria_page') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AtenderPrisionDomiciliariaPage(
                status: args['status'] ?? "Diligenciado",
                idDocumento: args['idDocumento'],
                numeroSeguimiento: args['numero_seguimiento'] ?? "Sin seguimiento",
                direccion: args['direccion'] ?? "",
                departamento: args['departamento'] ?? "",
                municipio: args['municipio'] ?? "",
                nombreResponsable: args['nombre_responsable'] ?? "",
                cedulaResponsable: args['cedula_responsable'] ?? "",
                celularResponsable: args['celular_responsable'] ?? "",
                fecha: args['fecha'],
                idUser: args['idUser'],
                archivos: List<String>.from(args['archivos'] ?? []),
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
