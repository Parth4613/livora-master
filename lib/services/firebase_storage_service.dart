import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static Future<String> uploadImage(
    String imagePath, {
    String folder = 'buddy_images',
  }) async {
    final file = File(imagePath);
    final fileName = file.uri.pathSegments.last;
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Create a reference from the URL
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }
}
