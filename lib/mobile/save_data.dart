import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

Future<String> uploadImageToFirebase(File? file, String path) async {
  if (file == null) return "";
  final ref = FirebaseStorage.instance.ref().child(path);
  final uploadTask = await ref.putFile(file);
  return await uploadTask.ref.getDownloadURL();
}

Future<void> saveUserProfileData({
  required String uid,
  required Map<String, dynamic> data,
}) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set(data, SetOptions(merge: true));
}
