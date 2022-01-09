import 'package:firebase_storage/firebase_storage.dart';

class FirebaseApi {
  static Future<List<Map<String, dynamic>>> loadData(String path) async {
    List<Map<String, dynamic>> files = [];
    final Reference ref = FirebaseStorage.instance.ref(path);
    final ListResult result = await ref.list();
    final List<Reference> allFiles = result.items;

    await Future.forEach<Reference>(allFiles, (file) async {
      final String fileUrl = await file.getDownloadURL();
      final FullMetadata fileMeta = await file.getMetadata();
      files.add({
        "url": fileUrl,
        "title": fileMeta.customMetadata?['title'] ?? '',
        "location": fileMeta.customMetadata?['location'] ?? 'Unknown',
        "description":
            fileMeta.customMetadata?['description'] ?? 'No description'
      });
    });

    return files;
  }
}
