import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/models/ppl.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Ppl> getPplData(String uid) async {
    final doc = await _firestore.collection('Ppl').doc(uid).get();
    return Ppl.fromJson(doc.data() as Map<String, dynamic>);
  }
}