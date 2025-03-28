const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const express = require("express");
const crypto = require("crypto");
const { defineSecret } = require("firebase-functions/params");
const { onRequest } = require("firebase-functions/v2/https");
const AWS = require("aws-sdk");
const { Buffer } = require("buffer");
const { getFirestore } = require("firebase-admin/firestore");
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");


const WOMPI_PUBLIC_KEY = defineSecret("WOMPI_PUBLIC_KEY");
const WOMPI_INTEGRITY_SECRET = defineSecret("WOMPI_INTEGRITY_SECRET");

admin.initializeApp();
const db = admin.firestore();

// Firebase config secrets
const FIREBASE_API_KEY = defineSecret("FB_API_KEY");
const FIREBASE_AUTH_DOMAIN = defineSecret("FB_AUTH_DOMAIN");
const FIREBASE_PROJECT_ID = defineSecret("FB_PROJECT_ID");
const FIREBASE_STORAGE_BUCKET = defineSecret("FB_STORAGE_BUCKET");
const FIREBASE_APP_ID = defineSecret("FB_APP_ID");
const FIREBASE_MESSAGING_SENDER_ID = defineSecret("FB_MESSAGING_SENDER_ID");

let cachedConfig = null;
let lastFetchTime = 0;
const CACHE_DURATION_MS = 5 * 60 * 1000;

exports.getFirestoreConfig = onRequest({
  cors: true,
  secrets: [
    FIREBASE_API_KEY,
    FIREBASE_AUTH_DOMAIN,
    FIREBASE_PROJECT_ID,
    FIREBASE_STORAGE_BUCKET,
    FIREBASE_APP_ID,
    FIREBASE_MESSAGING_SENDER_ID,
  ],
}, async (req, res) => {
  try {
    const now = Date.now();
    if (!cachedConfig || now - lastFetchTime > CACHE_DURATION_MS) {
      cachedConfig = {
        apiKey: FIREBASE_API_KEY.value(),
        authDomain: FIREBASE_AUTH_DOMAIN.value(),
        projectId: FIREBASE_PROJECT_ID.value(),
        storageBucket: FIREBASE_STORAGE_BUCKET.value(),
        appId: FIREBASE_APP_ID.value(),
        messagingSenderId: FIREBASE_MESSAGING_SENDER_ID.value(),
      };
      lastFetchTime = now;
    }
    return res.status(200).json(cachedConfig);
  } catch (error) {
    return res.status(500).json({ error: "Error interno del servidor", details: error.message });
  }
});

exports.wompiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;
    if (!event?.event || !event?.data?.transaction) {
      console.error("⚠️ Evento inválido recibido:", event);
      return res.status(400).json({ error: "Evento inválido recibido" });
    }

    const transaction = event.data.transaction;
    const { id: transactionId, status, reference, amount_in_cents, payment_method_type, created_at } = transaction;

    const referenceParts = reference.split("_");
    if (referenceParts.length < 3) {
      console.error("⚠️ Referencia inválida:", reference);
      return res.status(400).json({ error: "Referencia inválida" });
    }

    const tipoTransaccion = referenceParts[0];
    const userId = referenceParts[1];
    const userRef = db.collection("Ppl").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error("⚠️ No se encontró el usuario con ID:", userId);
      return res.status(404).json({ error: "Usuario no encontrado en Firestore" });
    }

    const amount = amount_in_cents / 100;
    const recargaRef = db.collection("recargas").doc(transactionId);
    await recargaRef.set({
      userId,
      amount,
      status,
      paymentMethod: payment_method_type,
      transactionId,
      reference,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(created_at)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const saldoActual = userDoc.data().saldo || 0;
    const nuevoSaldo = saldoActual + amount;

    if (tipoTransaccion === "suscripcion" && status === "APPROVED") {
      await userRef.update({ isPaid: true });
    }

    if (["recarga", "peticion"].includes(tipoTransaccion) && status === "APPROVED") {
      await userRef.update({ saldo: nuevoSaldo });
    }

    return res.status(200).json({ message: "Estado de pago actualizado con éxito y guardado en recargas" });
  } catch (error) {
    console.error("🚨 Error en el webhook de Wompi:", error);
    return res.status(500).json({ error: "Error procesando el webhook", details: error.message });
  }
});

exports.wompiCheckoutUrl = onRequest({
  cors: true,
  secrets: ["WOMPI_PUBLIC_KEY", "WOMPI_INTEGRITY_SECRET"],
}, async (req, res) => {
  try {
    console.log("📥 Headers:", req.headers);
    console.log("📥 Body (raw):", JSON.stringify(req.body));

    if (!req.body || typeof req.body !== "object") {
      return res.status(400).json({ error: "Cuerpo de solicitud inválido" });
    }

    const { referencia, monto } = req.body;

    console.log("📥 Datos recibidos:", req.body);

    if (!referencia || typeof referencia !== "string") {
      return res.status(400).json({ error: "Referencia faltante o inválida" });
    }

    if (typeof monto !== "number" || monto % 1 !== 0) {
      return res.status(400).json({ error: "El monto debe ser un número entero en centavos" });
    }

    if (!WOMPI_PUBLIC_KEY.value() || !WOMPI_INTEGRITY_SECRET.value()) {
      return res.status(500).json({ error: "Variables de entorno no configuradas" });
    }

    const moneda = "COP";
    const publicKey = WOMPI_PUBLIC_KEY.value().replace(/"/g, "");
    const cadena = `${referencia}${monto}${moneda}${WOMPI_INTEGRITY_SECRET.value()}`;
    const firma = crypto.createHash("sha256").update(cadena).digest("hex");

    const queryParams = new URLSearchParams({
      currency: moneda,
      "amount-in-cents": monto.toString(),
      reference: referencia,
      "public-key": publicKey,
      "signature:integrity": firma,
    });

    const url = `https://checkout.wompi.co/p/?${queryParams.toString()}`;

    console.log("✅ URL generada:", url);

    return res.status(200).json({ url });
  } catch (error) {
    console.error("❌ Error generando URL de Wompi:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

exports.sendEmailWithSES = onRequest({
  secrets: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SES_REGION"],
}, async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  try {
    const { to, cc, subject, html, archivos, idDocumento, enviadoPor } = req.body;

    if (!to || !subject || !html || !idDocumento || !enviadoPor) {
      return res.status(400).json({ error: "Faltan campos obligatorios: to, subject, html, idDocumento, enviadoPor" });
    }

    const normalizeEmails = (field) => Array.isArray(field) ? field : field ? [field] : [];
    const toAddresses = normalizeEmails(to);
    const ccAddresses = normalizeEmails(cc);

    const ses = new AWS.SES({
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      region: process.env.AWS_SES_REGION,
    });

    const boundary = "NextPart";
    let rawMessage = "";

    rawMessage += `From: Tu Proceso Ya <tuproceso.ya@gmail.com>\n`;
    rawMessage += `To: ${toAddresses.join(", ")}\n`;
    if (ccAddresses.length) rawMessage += `Cc: ${ccAddresses.join(", ")}\n`;
    rawMessage += `Subject: ${subject}\n`;
    rawMessage += `MIME-Version: 1.0\n`;
    rawMessage += `Content-Type: multipart/mixed; boundary="${boundary}"\n\n`;

    rawMessage += `--${boundary}\n`;
    rawMessage += `Content-Type: text/html; charset="UTF-8"\n`;
    rawMessage += `Content-Transfer-Encoding: 7bit\n\n`;
    rawMessage += `${html}\n\n`;

    if (Array.isArray(archivos)) {
      for (const archivo of archivos) {
        if (archivo.nombre && archivo.base64) {
          rawMessage += `--${boundary}\n`;
          rawMessage += `Content-Type: application/octet-stream; name="${archivo.nombre}"\n`;
          rawMessage += `Content-Description: ${archivo.nombre}\n`;
          rawMessage += `Content-Disposition: attachment; filename="${archivo.nombre}"; size=${Buffer.from(archivo.base64, 'base64').length};\n`;
          rawMessage += `Content-Transfer-Encoding: base64\n\n`;
          rawMessage += `${archivo.base64}\n\n`;
        }
      }
    }

    rawMessage += `--${boundary}--`;

    const result = await ses.sendRawEmail({
      RawMessage: { Data: Buffer.from(rawMessage) },
      Source: "tuproceso.ya@gmail.com",
      Destinations: toAddresses,
    }).promise();

    // 🧠 SUBIR HTML AL STORAGE
    const firestore = getFirestore();
    const bucket = admin.storage().bucket();
    const timestamp = new Date().toISOString();
    const pdfPath = `derechos_peticion/${idDocumento}/correos_enviados/correo-${timestamp}.html`;

    await bucket.file(pdfPath).save(Buffer.from(html, "utf-8"), {
      metadata: { contentType: "text/html; charset=utf-8" },
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${pdfPath}`;

    // ✅ GUARDAR EN log_correos
    await firestore
      .collection("derechos_peticion_solicitados")
      .doc(idDocumento)
      .collection("log_correos")
      .add({
        to: toAddresses,
        cc: ccAddresses,
        subject,
        html,
        htmlUrl: publicUrl,
        archivos: archivos?.map(a => ({ nombre: a.nombre })),
        enviadoPor,
        messageId: result.MessageId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Error enviando correo SES:", error);
    return res.status(500).json({ error: "Error enviando correo SES" });
  }
});

exports.generarTextoIA = onRequest({
  cors: true,
  secrets: [OPENAI_API_KEY],
}, async (req, res) => {
  try {
    const { categoria, subcategoria, respuestasUsuario } = req.body;

    if (!categoria || !subcategoria || !Array.isArray(respuestasUsuario)) {
      return res.status(400).json({ error: "Faltan campos requeridos" });
    }

    const prompt = `
    Quiero que actúes como un asistente legal. A partir de las respuestas de un ciudadano a un formulario de derecho de petición en la categoría "${categoria}" y subcategoría "${subcategoria}", redacta un texto coherente, organizado y bien redactado que unifique estas respuestas en un solo párrafo. Las respuestas del usuario son:
    ${respuestasUsuario.map((r, i) => `(${i + 1}) ${r}`).join("\n")}
    `;

    const OpenAI = require("openai");
    const openai = new OpenAI({
      apiKey: OPENAI_API_KEY.value(),
    });

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: "Eres un asistente legal experto en redacción clara y formal." },
        { role: "user", content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 500,
    });

    const texto = completion.data.choices[0].message.content;

    return res.status(200).json({ texto });
  } catch (error) {
    console.error("❌ Error al generar texto con OpenAI:", error);
    return res.status(500).json({
      error: "Error generando texto IA",
      message: error.message,
      stack: error.stack,
    });
  }
});

exports.generarTextoIAExtendido = onRequest({
  cors: true,
  secrets: [OPENAI_API_KEY],
}, async (req, res) => {
  try {
    const { categoria, subcategoria, respuestasUsuario } = req.body;

    if (!categoria || !subcategoria || !Array.isArray(respuestasUsuario)) {
      return res.status(400).json({ error: "Faltan campos requeridos" });
    }

    const prompt = `
Redacta para un derecho de petición en Colombia en base a estas respuestas del usuario. Dame tres secciones separadas:
1. Consideraciones claras y bien estructuradas.
2. Fundamentos jurídicos aplicables según Constitución, Leyes y Jurisprudencia colombiana.
3. Una petición concreta basada en lo anterior.

Categoría: ${categoria}
Subcategoría: ${subcategoria}

Respuestas:
${respuestasUsuario.map((r, i) => `(${i + 1}) ${r}`).join("\n")}
`;

    const OpenAI = require("openai");
    const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: "Eres un redactor legal colombiano, claro y técnico." },
        { role: "user", content: prompt }
      ],
      temperature: 0.6,
      max_tokens: 1000,
    });

    const respuesta = completion.choices[0].message.content;

    // Separar secciones esperadas por delimitadores específicos
    const consideraciones = respuesta.split("2. Fundamentos")[0].trim();
    const fundamentos = respuesta.split("2. Fundamentos")[1].split("3. Una petición")[0].trim();
    const peticion = respuesta.split("3. Una petición")[1]?.trim() ?? '';

    return res.status(200).json({
      consideraciones,
      fundamentos,
      peticion,
    });

  } catch (error) {
    return res.status(500).json({
      error: "Error generando texto IA extendido",
      message: error.message,
      stack: error.stack,
    });
  }
});








