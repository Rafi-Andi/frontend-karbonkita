import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/ui/widgets/validation_error_sheet.dart';

void main() {
  group('friendlyValidationMessage', () {
    test('max kilobytes file -> Indonesia + MB', () {
      expect(
        friendlyValidationMessage(
          'foto_ktp',
          'The foto ktp must not be greater than 5120 kilobytes.',
        ),
        'Ukuran file maksimal 5 MB.',
      );
    });

    test('MIME tidak didukung', () {
      expect(
        friendlyValidationMessage(
          'foto_ktp',
          'The foto ktp must be a file of type: jpeg, png, jpg.',
        ),
        contains('Format file harus'),
      );
    });

    test('duplikat -> sudah terdaftar', () {
      expect(
        friendlyValidationMessage('email', 'The email has already been taken.'),
        'Sudah terdaftar, gunakan yang lain.',
      );
    });

    test('KTP digit + required + email', () {
      expect(
        friendlyValidationMessage(
          'nomor_ktp',
          'The nomor ktp must be 16 digits.',
        ),
        'Harus tepat 16 digit angka.',
      );
      expect(
        friendlyValidationMessage('name', 'The name field is required.'),
        'Wajib diisi.',
      );
      expect(
        friendlyValidationMessage(
          'email',
          'The email must be a valid email address.',
        ),
        'Format email tidak valid.',
      );
    });

    test('pesan Indonesia backend diteruskan apa adanya', () {
      const msg = 'Nomor KTP harus 16 digit angka.';
      expect(friendlyValidationMessage('nomor_ktp', msg), msg);
    });
  });

  group('collectValidationErrors', () {
    test('semua pesan per field ikut dengan label Indonesia', () {
      final items = collectValidationErrors({
        'foto_ktp': ['The foto ktp must not be greater than 5120 kilobytes.'],
        'email': ['The email has already been taken.'],
        'custom_field': ['Something odd happened.'],
      });

      expect(items, hasLength(3));
      expect(items[0].label, 'Foto KTP');
      expect(items[0].message, 'Ukuran file maksimal 5 MB.');
      expect(items[1].label, 'Email');
      expect(items[2].label, 'Custom Field');
      expect(items[2].message, 'Something odd happened.');
    });

    test('pesan kosong dilewati', () {
      final items = collectValidationErrors({
        'email': ['   '],
      });
      expect(items, isEmpty);
    });
  });
}
