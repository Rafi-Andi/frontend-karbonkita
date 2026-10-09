import 'package:image_picker/image_picker.dart';

import 'pick_copy_stub.dart' if (dart.library.io) 'pick_copy_io.dart' as impl;

/// Salin foto hasil image_picker ke direktori dokumen aplikasi.
///
/// Latar: image_picker menyimpan ke direktori *cache*; di HP tertentu OS
/// (installd) menggusur file cache saat kuota terlampaui → submit kemudian
/// crash PathNotFoundException. Dokumen app tidak digusur OS.
///
/// Di web (tanpa dart:io) fungsi ini passthrough: blob tidak digusur OS.
Future<XFile?> persistPickedPhoto(XFile file, String field) =>
    impl.persistPickedPhoto(file, field);

/// Hapus satu file hasil [persistPickedPhoto] (best-effort).
Future<void> discardPersistedPhoto(XFile? file) =>
    impl.discardPersistedPhoto(file);

/// Bersihkan sisa salinan sesi sebelumnya (best-effort).
Future<void> clearStalePersistedPhotos() => impl.clearStalePersistedPhotos();
