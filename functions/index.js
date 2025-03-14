const functions = require("firebase-functions");
const admin = require("firebase-admin"); // 📌 Importamos Firebase Admin SDK
const nodemailer = require("nodemailer");
const cors = require("cors");
const express = require("express");
admin.initializeApp(); // 📌 Inicializa Firebase Admin

const db = admin.firestore(); // 📌 Referencia a Firestore

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post("/enviarCorreo", async (req, res) => {
  try {
    const { destinatario, asunto, mensaje, archivos } = req.body;

    let transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "johnnever.bernal@gmail.com",
        pass: "yqfo mify fcso edam",
      },
    });

    let adjuntos = [];

    if (archivos && archivos.length > 0) {
      archivos.forEach((archivo) => {
        if (archivo.base64) {
          adjuntos.push({
            filename: archivo.nombre,
            content: archivo.base64,
            encoding: "base64",
          });
        }
      });
    }

    let mailOptions = {
      from: "johnnever.bernal@gmail.com",
      to: destinatario,
      subject: asunto,
      html: mensaje,
      attachments: adjuntos.length > 0 ? adjuntos : undefined,
    };

    let info = await transporter.sendMail(mailOptions);
    res.status(200).json({ message: "Correo enviado con éxito", response: info.response });

  } catch (error) {
    console.error("🚨 Error al enviar correo:", error);
    res.status(500).json({ error: "Error al enviar el correo", details: error.message });
  }
});

exports.enviarCorreo = functions.https.onRequest(app);

exports.wompiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;

    if (!event || !event.event || !event.data || !event.data.transaction) {
      console.error("⚠️ Evento inválido recibido:", event);
      return res.status(400).json({ error: "Evento inválido recibido" });
    }

    console.log("📩 Evento recibido de Wompi:", JSON.stringify(event, null, 2));

    const transaction = event.data.transaction;
    const transactionId = transaction.id;
    const status = transaction.status;
    const reference = transaction.reference;
    const amount = transaction.amount_in_cents / 100; // Convertir a pesos
    const paymentMethod = transaction.payment_method_type;
    const createdAt = transaction.created_at; // Fecha de la transacción

    // 📌 Extraer el ID del usuario desde la referencia
    const referenceParts = reference.split("_");
    if (referenceParts.length < 3) {
      console.error("⚠️ Referencia inválida:", reference);
      return res.status(400).json({ error: "Referencia inválida" });
    }

    const tipoTransaccion = referenceParts[0]; // "suscripcion" o "recarga"
    const userId = referenceParts[1]; // ID del usuario en Firestore

    // 📌 Obtener documento del usuario en Firestore
    const userRef = db.collection("Ppl").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error("⚠️ No se encontró el usuario con ID:", userId);
      return res.status(404).json({ error: "Usuario no encontrado en Firestore" });
    }

    // 📌 Guardar transacción en la colección "recargas"
    const recargaRef = db.collection("recargas").doc(transactionId);
    await recargaRef.set({
      userId: userId,
      amount: amount,
      status: status,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      reference: reference,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(createdAt)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Transacción guardada en "recargas": ${transactionId}`);

    // 📌 Si es una suscripción, activar isPaid
    if (tipoTransaccion === "suscripcion") {
      await userRef.update({
        isPaid: status === "APPROVED",
        transactionId: transactionId,
        paymentStatus: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Suscripción actualizada para ${userId}: ${status}`);
    }

    // 📌 Si es una recarga, sumar el saldo
    if (tipoTransaccion === "recarga") {
      const saldoActual = userDoc.data().saldo || 0;
      const nuevoSaldo = saldoActual + amount;

      await userRef.update({
        saldo: nuevoSaldo,
        transactionId: transactionId,
        paymentStatus: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Recarga completada para ${userId}: Nuevo saldo ${nuevoSaldo}`);
    }

    return res.status(200).json({ message: "Estado de pago actualizado con éxito y guardado en recargas" });

  } catch (error) {
    console.error("🚨 Error en el webhook de Wompi:", error);
    return res.status(500).json({ error: "Error procesando el webhook", details: error.message });
  }
});






