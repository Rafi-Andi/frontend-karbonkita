import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Implementasi IO (Android/iOS/desktop): salin ke dokumen aplikasi.
Future<XFile?> persistPickedPhoto(XFile file, String field) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/mitra_uploads');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final name = file.name;
    final dot = name.lastIndexOf('.');
    final ext = (dot >= 0 && dot < name.length - 1)
        ? name.substring(dot + 1).toLowerCase()
        : 'jpg';
    final dest = '${target.path}/${field}_$stamp.$ext';
    await File(file.path).copy(dest);
    final size = await File(dest).length();
    debugPrint('[mitra-register] $field persisted: $dest (${size}B)');
    return XFile(dest, name: file.name);
  } catch (e) {
    // Gagal salin (mis. sumber sudah hilang) → pakai file asli agar alur
    // lama tetap jalan; _submit memverifikasi keterbacaan dengan retry.
    debugPrint('[mitra-register] persist $field gagal, pakai asli: $e');
    return file;
  }
}

Future<void> discardPersistedPhoto(XFile? file) async {
  try {
    if (file == null) return;
    final f = File(file.path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

Future<void> clearStalePersistedPhotos() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/mitra_uploads');
    if (await target.exists()) {
      await for (final entity in target.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
  } catch (_) {}
}
