import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> firebaseConfig = {};

/// 🔹 Carga la configuración de Firebase de forma segura
Future<void> loadFirebaseConfig() async {
  try {
    // 🔹 Cargar `config.json`
    String configJson = await rootBundle.loadString("assets/config/config.json");
    firebaseConfig = jsonDecode(configJson);
  } catch (e) {
    print("⚠️ No se encontró `config.json`, intentando cargar `.env`");

    // 🔹 Cargar `.env` si `config.json` no está disponible
    await dotenv.load(fileName: "assets/config/env.json");
    firebaseConfig = {
      "FIREBASE_API_KEY_WEB": dotenv.env['FIREBASE_API_KEY_WEB'] ?? "",
      "FIREBASE_APP_ID_WEB": dotenv.env['FIREBASE_APP_ID_WEB'] ?? "",
      "FIREBASE_MESSAGING_SENDER_ID_WEB": dotenv.env['FIREBASE_MESSAGING_SENDER_ID_WEB'] ?? "",
      "FIREBASE_PROJECT_ID_WEB": dotenv.env['FIREBASE_PROJECT_ID_WEB'] ?? "",
      "FIREBASE_AUTH_DOMAIN_WEB": dotenv.env['FIREBASE_AUTH_DOMAIN_WEB'] ?? "",
      "FIREBASE_STORAGE_BUCKET_WEB": dotenv.env['FIREBASE_STORAGE_BUCKET_WEB'] ?? "",
      "WOMPI_PUBLIC_KEY": dotenv.env['WOMPI_PUBLIC_KEY'] ?? "",
      "WOMPI_INTEGRITY_SECRET": dotenv.env['WOMPI_INTEGRITY_SECRET'] ?? "",
    };
    print("✅ Firebase config cargado desde `.env`.");
  }

  // 🔥 Validar que las claves se han cargado correctamente
  if (firebaseConfig.values.contains("")) {
    print("🚨 Error: Algunas claves están vacías o mal configuradas.");
  }
}
