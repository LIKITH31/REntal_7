import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile image, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      
      if (kIsWeb) {
        await ref.putData(await image.readAsBytes()).timeout(const Duration(seconds: 15));
      } else {
        await ref.putFile(File(image.path)).timeout(const Duration(seconds: 15));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw 'Image Upload Failed: $e. (Check Storage Rules/CORS)';
    }
  }

  Future<List<String>> uploadImages(List<XFile> images, String folder) async {
    final uploadTasks = images.map((image) => uploadImage(image, folder));
    return await Future.wait(uploadTasks);
  }
}
