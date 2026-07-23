import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  // Singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get techniciansRef =>
      _firestore.collection('technicians');
  CollectionReference get servicesRef => _firestore.collection('services');
  CollectionReference get complaintsRef => _firestore.collection('complaints');
  CollectionReference get bookingsRef => _firestore.collection('bookings');
  CollectionReference get reviewsRef => _firestore.collection('reviews');

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── FIRESTORE ─────────────────────────────────────────────────────────────
Future<void> setDocument({
  required String collection,
  required String docId,
  required Map<String, dynamic> data,
}) async {
  print("🔥 Writing to Firestore...");
  print("UID: ${FirebaseAuth.instance.currentUser?.uid}");
  print("DocID: $docId");

  try {
    await _firestore.collection(collection).doc(docId).set(data);
    print("✅ Firestore write success");
  } catch (e) {
    print("❌❌❌ FIRESTORE WRITE FAILED: $e");
    rethrow; 
  }
}

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  Stream<DocumentSnapshot> streamDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Stream<QuerySnapshot> streamCollection({
    required String collection,
    List<List<dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);
    if (whereConditions != null) {
      for (var condition in whereConditions) {
        query = query.where(condition[0], isEqualTo: condition[1]);
      }
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }

  // ─── STORAGE ───────────────────────────────────────────────────────────────

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String folderPath,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadFile(
        file: files[i],
        path: '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }

  /// Flutter Web + Mobile dono ke liye — XFile se bytes read karke upload karo
  Future<List<String>> uploadMultipleXFiles({
    required List<XFile> xfiles,
    required String folderPath,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < xfiles.length; i++) {
      final xfile = xfiles[i];
      final bytes = await xfile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = _storage.ref('$folderPath/$fileName');
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }

  // ─── BATCH ─────────────────────────────────────────────────────────────────

  Future<void> runBatch(Function(WriteBatch batch) operations) async {
    final batch = _firestore.batch();
    operations(batch);
    await batch.commit();
  }

  Future<List<String>> uploadMultipleBytes({
    required List<Uint8List> bytesFiles,
    required List<String> fileNames,
    required String folderPath,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < bytesFiles.length; i++) {
      final ref = storage.ref('$folderPath/${fileNames[i]}');
      await ref.putData(bytesFiles[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<List<String>> uploadToCloudinary({
    required List<XFile> xfiles,
  }) async {
    const cloudName = 'dajyf1zd0';
    const uploadPreset = 'al_hamra_preset';

    final List<String> urls = [];
    for (final xfile in xfiles) {
      final bytes = await xfile.readAsBytes();

      // ── Base64 ki jagah Multipart use karo ──────────────────
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        urls.add(data['secure_url']);
      } else {
        print('Cloudinary error: ${response.body}');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    }
    return urls;
  }
}
