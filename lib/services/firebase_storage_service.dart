import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static Future<String> uploadImage(
    dynamic imagePath, {
    String folder = 'buddy_images',
  }) async {
    try {
      print('Starting image upload for path: $imagePath');
      
      if (kIsWeb) {
        // Handle web platform
        if (imagePath is XFile) {
          return await _uploadWebImage(imagePath, folder);
        } else if (imagePath is String && imagePath.startsWith('blob:')) {
          // Convert blob URL to XFile if needed
          final xFile = XFile(imagePath);
          return await _uploadWebImage(xFile, folder);
        } else {
          throw Exception('Unsupported image format for web: $imagePath');
        }
      } else {
        // Handle mobile platform
        if (imagePath is String) {
    final file = File(imagePath);
          if (!await file.exists()) {
            throw Exception('Image file does not exist: $imagePath');
          }
          
          // Validate image file
          final isValid = await _validateImageFile(file);
          if (!isValid) {
            throw Exception('Invalid or corrupted image file: $imagePath');
          }
          
          return await _uploadMobileImage(file, folder);
        } else {
          throw Exception('Unsupported image format for mobile: $imagePath');
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      print('Image path: $imagePath');
      print('Folder: $folder');
      rethrow;
    }
  }

  static Future<String> _uploadWebImage(XFile xFile, String folder) async {
    try {
      print('Uploading web image: ${xFile.path}');
      
      // Read the file as bytes
      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }
      
      // Validate image bytes
      final isValid = await _validateImageBytes(bytes);
      if (!isValid) {
        throw Exception('Invalid or corrupted image file');
      }
      
      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = xFile.name;
      final fileName = '${timestamp}_$originalName';
      
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      
      print('Uploading to Firebase Storage: $folder/$fileName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Web image uploaded successfully. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading web image: $e');
      rethrow;
    }
  }

  static Future<String> _uploadMobileImage(File file, String folder) async {
    try {
      print('Uploading mobile image: ${file.path}');
      
      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = file.uri.pathSegments.last;
      final fileName = '${timestamp}_$originalName';
      
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      
      print('Uploading to Firebase Storage: $folder/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Mobile image uploaded successfully. Download URL: $downloadUrl');
    return downloadUrl;
    } catch (e) {
      print('Error uploading mobile image: $e');
      rethrow;
    }
  }

  static Future<bool> _validateImageFile(File file) async {
    try {
      // Check file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('Image file too large: ${fileSize} bytes');
        return false;
      }
      
      // Read file bytes
      final bytes = await file.readAsBytes();
      return await _validateImageBytes(bytes);
    } catch (e) {
      print('Image validation error: $e');
      return false;
    }
  }

  static Future<bool> _validateImageBytes(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        print('Image file is empty');
        return false;
      }
      
      // Try to decode the image to validate it
      try {
        final image = img.decodeImage(bytes);
        if (image == null) {
          print('Failed to decode image');
          return false;
        }
        
        // Check if image dimensions are reasonable
        if (image.width < 10 || image.height < 10) {
          print('Image dimensions too small: ${image.width}x${image.height}');
          return false;
        }
        
        if (image.width > 5000 || image.height > 5000) {
          print('Image dimensions too large: ${image.width}x${image.height}');
          return false;
        }
        
        print('Image validation successful: ${image.width}x${image.height}');
        return true;
      } catch (e) {
        print('Image decoding failed: $e');
        return false;
      }
    } catch (e) {
      print('Image validation error: $e');
      return false;
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      print('Deleting image from URL: $imageUrl');
      // Create a reference from the URL
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully');
    } catch (e) {
      print('Error deleting image: $e');
      print('Image URL: $imageUrl');
      rethrow;
    }
  }
}
