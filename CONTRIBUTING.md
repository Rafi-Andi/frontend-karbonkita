# Panduan Kolaborasi (Contributing Guidelines)

Selamat datang di project **KarbonKitaApp**! Untuk menjaga kode kita tetap rapi, bersih, dan mudah dibaca oleh seluruh anggota tim, mohon ikuti beberapa aturan dan panduan di bawah ini sebelum mulai berkontribusi.

## 🛠 Teknologi & Library Utama
Pastikan Anda memahami fungsi dari package utama yang digunakan dalam project ini:
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Networking/API:** [dio](https://pub.dev/packages/dio)
- **Local Storage:** 
  - [shared_preferences](https://pub.dev/packages/shared_preferences) (untuk data ringan non-sensitif).
  - [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (untuk token, password, atau data rahasia).
- **UI Components:** 
  - Cupertino Icons (Asset icon standar).
  - [art_sweetalert](https://pub.dev/packages/art_sweetalert) (Untuk dialog/alert).

---

## 📂 Struktur Folder
Semua kode berada di dalam folder `lib/`. Harap jangan membuat folder baru di luar struktur yang sudah disepakati, kecuali memang benar-benar diperlukan.

```text
lib/
 ├── bloc/         # Logic State Management BLoC / Cubit.
 ├── models/       # Class/Model data untuk mapping hasil API (JSON) atau data lokal.
 ├── services/     # Logic yang berhubungan dengan sisi luar aplikasi (Dio Client, API Service, Local Storage Service).
 ├── ui/
 │    ├── screens/ # Halaman (Page) utama yang memuat gabungan widget.
 │    └── widgets/ # Potongan UI (Component) yang bersifat reusable (bisa dipakai berulang kali).
 └── main.dart     # Entry point aplikasi.
```

---

## 📝 Aturan Penulisan Kode (Coding Rules)

1. **Gunakan BLoC/Cubit untuk Logic UI:**
   - Hindari menulis *business logic* panjang atau pemanggilan API secara langsung di dalam file UI (di dalam fungsi `build`).
   - UI hanya boleh mendengarkan state (State Listener/Builder) dan mengirim *event* ke BLoC.

2. **Pemisahan Tanggung Jawab (Separation of Concerns):**
   - **`services/`**: Hanya berisi code untuk request ke endpoint (GET, POST, dll).
   - **`models/`**: Hanya berisi definisi variabel, `fromJson`, dan `toJson`.
   - **`bloc/`**: Tempat memanggil fungsi `services` lalu mengubah hasilnya (sukses/gagal) menjadi sebuah *State*.

3. **Penamaan File dan Class:**
   - Nama file wajib menggunakan huruf kecil dan garis bawah *snake_case* (contoh: `home_screen.dart`, `auth_bloc.dart`).
   - Nama Class menggunakan *PascalCase* (contoh: `HomeScreen`, `AuthBloc`).
   - Nama variabel/fungsi menggunakan *camelCase* (contoh: `fetchUserData()`, `userName`).

4. **Widget Extraction:**
   - Jika Anda melihat sebuah fungsi `build` dalam UI memakan lebih dari 100 baris, pecahlah UI tersebut menjadi bagian-bagian kecil dan letakkan ke dalam folder `ui/widgets/`.

5. **Akses Data Sensitif:**
   - JANGAN pernah menggunakan `shared_preferences` untuk menyimpan **Token Login** atau **Password**. Selalu gunakan **`flutter_secure_storage`** pada file service Anda.

---

## 🚀 Sebelum Membuat Commit/Pull Request
Sebelum Anda push kode atau membuat Pull Request, pastikan untuk:
1. Menjalankan perintah `flutter format lib/` untuk merapikan kode.
2. Memastikan tidak ada error linter / analyze dengan menjalankan `flutter analyze`.
3. Selalu buat *branch* baru dari `main` saat mengerjakan fitur baru, contoh penamaan branch:
   - `feature/login-screen`
   - `bugfix/fix-null-pointer-profile`

Terima kasih atas kontribusi Anda. Mari bersama-sama membuat **KarbonKitaApp** menjadi lebih baik! 🚀
