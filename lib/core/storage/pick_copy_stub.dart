import 'package:image_picker/image_picker.dart';

/// Stub web/non-IO: tidak ada penyalinan, blob URL aman dari penggusuran OS.
Future<XFile?> persistPickedPhoto(XFile file, String field) async => file;

Future<void> discardPersistedPhoto(XFile? file) async {}

Future<void> clearStalePersistedPhotos() async {}
