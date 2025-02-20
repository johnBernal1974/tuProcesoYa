const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors");
const express = require("express");

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




