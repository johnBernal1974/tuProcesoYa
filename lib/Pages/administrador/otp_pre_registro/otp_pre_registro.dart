import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// OtpPreRegistroPage
/// Recibe por arguments:
/// {
///   'pre_registro_id': '<docId>',
///   'celular': '3001112233' // normalizado (10 dígitos CO) idealmente
/// }
///
/// Flujo:
/// 1) Enviar OTP
/// 2) Confirmar OTP
/// 3) Ejecutar RegistroFinalizador.finalizarRegistroDespuesOtp(preRegistroId)
/// 4) Navegar a home
class OtpPreRegistroPage extends StatefulWidget {
  const OtpPreRegistroPage({super.key});

  @override
  State<OtpPreRegistroPage> createState() => _OtpPreRegistroPageState();
}

class _OtpPreRegistroPageState extends State<OtpPreRegistroPage> {
  // ---- args ----
  String _preRegistroId = '';
  String _celular = '';

  // ---- ui ----
  final TextEditingController _codeCtrl = TextEditingController();
  bool _cargando = false;
  bool _otpEnviado = false;
  String? _error;

  // ---- auth web (phone) ----
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _preRegistroId = (args['pre_registro_id'] ?? '').toString();
      _celular = (args['celular'] ?? '').toString();
    }
  }

  String _toE164CO(String celular10) {
    // Espera 10 dígitos en CO y arma +57XXXXXXXXXX
    var s = celular10.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (s.startsWith('57') && s.length >= 12) s = s.substring(2);
    return '+57$s';
  }

  Future<void> _enviarOtp() async {
    if (_preRegistroId.isEmpty || _celular.isEmpty) {
      setState(() => _error = 'Faltan datos: pre_registro_id o celular.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final phoneE164 = _toE164CO(_celular);

      // ✅ Flutter Web: usa signInWithPhoneNumber -> ConfirmationResult
      _confirmationResult =
      await FirebaseAuth.instance.signInWithPhoneNumber(phoneE164);

      if (!mounted) return;

      setState(() {
        _otpEnviado = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código enviado a $phoneE164')),
      );
    } catch (e) {
      setState(() => _error = 'Error enviando OTP: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarOtp() async {
    if (_confirmationResult == null) {
      setState(() => _error = 'Primero debes enviar el OTP.');
      return;
    }

    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'El código debe tener 6 dígitos.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // ✅ Confirma OTP -> autentica usuario (currentUser queda listo)
      await _confirmationResult!.confirm(code);

      // ✅ Finaliza registro (pasa data del pre-registro a Ppl/{uid}, índices, etc.)
      final finalizador = RegistroFinalizador();
      await finalizador.finalizarRegistroDespuesOtp(preRegistroId: _preRegistroId);

      if (!mounted) return;

      // ✅ Ir a Home
      Navigator.pushReplacementNamed(context, 'home');
    } catch (e) {
      setState(() => _error = 'Código inválido o error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneE164 = _celular.isEmpty ? '' : _toE164CO(_celular);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación por OTP'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirma tu número',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phoneE164.isEmpty
                      ? 'Cargando datos...'
                      : 'Te enviaremos un código a: $phoneE164',
                ),
                const SizedBox(height: 16),

                // ---- error ----
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ---- enviar otp ----
                ElevatedButton(
                  onPressed: _cargando ? null : _enviarOtp,
                  child: _cargando
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_otpEnviado ? 'Reenviar código' : 'Enviar código'),
                ),

                const SizedBox(height: 12),

                // ---- input código ----
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código (6 dígitos)',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  enabled: _otpEnviado && !_cargando,
                ),

                const SizedBox(height: 12),

                // ---- confirmar ----
                ElevatedButton(
                  onPressed: (!_otpEnviado || _cargando) ? null : _confirmarOtp,
                  child: _cargando
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Confirmar'),
                ),

                const SizedBox(height: 10),

                Text(
                  'Pre-registro: ${_preRegistroId.isEmpty ? "—" : _preRegistroId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistroFinalizador {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RegistroFinalizador({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String _normalizarCelular(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (s.startsWith('57') && s.length >= 12) s = s.substring(2);
    return s;
  }

  Future<void> finalizarRegistroDespuesOtp({
    required String preRegistroId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final preRef = _db.collection('pre_registro_ppl').doc(preRegistroId);
    final pplRef = _db.collection('Ppl').doc(user.uid);

    await _db.runTransaction((tx) async {
      final preSnap = await tx.get(preRef);
      if (!preSnap.exists) throw Exception('Pre-registro no existe.');

      final pre = (preSnap.data() as Map<String, dynamic>?) ?? {};
      final acudiente = (pre['acudiente'] as Map<String, dynamic>?) ?? {};
      final ppl = (pre['ppl'] as Map<String, dynamic>?) ?? {};
      final otp = (pre['otp'] as Map<String, dynamic>?) ?? {};

      final celularRaw = (acudiente['celular_raw'] ?? '').toString();
      final celularNorm =
      _normalizarCelular((acudiente['celular'] ?? celularRaw).toString());

      final numeroDocumentoPpl =
      (ppl['numero_documento'] ?? '').toString().trim();

      if (celularNorm.length < 10) throw Exception('Celular inválido.');
      if (numeroDocumentoPpl.isEmpty) {
        throw Exception('Documento del PPL es obligatorio.');
      }

      // índices
      final idxCelularRef = _db.collection('indices_celulares').doc(celularNorm);
      final idxDocPplRef =
      _db.collection('indices_documentos_ppl').doc(numeroDocumentoPpl);

      final idxCelSnap = await tx.get(idxCelularRef);
      if (idxCelSnap.exists) {
        final data = (idxCelSnap.data() as Map<String, dynamic>?) ?? {};
        final uidExistente = (data['uid'] ?? '').toString();
        if (uidExistente.isNotEmpty && uidExistente != user.uid) {
          throw Exception('Este celular ya está registrado.');
        }
      }

      final idxDocSnap = await tx.get(idxDocPplRef);
      if (idxDocSnap.exists) {
        final data = (idxDocSnap.data() as Map<String, dynamic>?) ?? {};
        final uidExistente = (data['uid'] ?? '').toString();
        if (uidExistente.isNotEmpty && uidExistente != user.uid) {
          throw Exception('Este documento ya está registrado.');
        }
      }

      final now = FieldValue.serverTimestamp();

      // doc final
      tx.set(
        pplRef,
        <String, dynamic>{
          'uid': user.uid,
          'celular': celularNorm,
          'celular_raw': celularRaw,
          'estado_registro': 'activo',

          'ppl': ppl,
          'acudiente': acudiente,
          'selecciones': pre['selecciones'] ?? {},

          'pre_registro_id': preRegistroId,
          'analisis_condena_id': pre['analisis_condena_id'] ?? preRegistroId,

          'created_at': now,
          'updated_at': now,
          if (pre.containsKey('created_at'))
            'created_at_pre_registro': pre['created_at'],
        },
        SetOptions(merge: true),
      );

      // indices
      tx.set(
        idxCelularRef,
        {
          'uid': user.uid,
          'celular': celularNorm,
          'updated_at': now,
          'created_at': idxCelSnap.exists
              ? ((idxCelSnap.data() as Map<String, dynamic>)['created_at'] ?? now)
              : now,
        },
        SetOptions(merge: true),
      );

      tx.set(
        idxDocPplRef,
        {
          'uid': user.uid,
          'numero_documento_ppl': numeroDocumentoPpl,
          'updated_at': now,
          'created_at': idxDocSnap.exists
              ? ((idxDocSnap.data() as Map<String, dynamic>)['created_at'] ?? now)
              : now,
        },
        SetOptions(merge: true),
      );

      // marcar pre-registro
      final estadoOtp = (otp['estado'] ?? 'pendiente').toString();
      if (estadoOtp != 'verificado') {
        tx.update(preRef, {
          'otp.estado': 'verificado',
          'otp.verificado_en': now,
          'uid': user.uid,
          'updated_at': now,
        });
      } else {
        // idempotente: igual actualiza uid si faltara
        tx.update(preRef, {
          'uid': user.uid,
          'updated_at': now,
        });
      }
    });
  }
}
