import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manox/features/home/data/media_signature_validator.dart';

void main() {
  group('MediaSignatureValidator image signatures', () {
    test('accepts supported image headers', () {
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
          'jpg',
        ),
        isTrue,
      );
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          ]),
          'png',
        ),
        isTrue,
      );
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList('GIF89a'.codeUnits),
          'gif',
        ),
        isTrue,
      );
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList([
            ...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits,
          ]),
          'webp',
        ),
        isTrue,
      );
    });

    test('rejects spoofed, truncated and unsupported image files', () {
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList('not an image'.codeUnits),
          'png',
        ),
        isFalse,
      );
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList([0xFF, 0xD8]),
          'jpg',
        ),
        isFalse,
      );
      expect(
        MediaSignatureValidator.hasImageSignature(
          Uint8List.fromList([0, 1, 2, 3]),
          'svg',
        ),
        isFalse,
      );
    });
  });

  group('MediaSignatureValidator video signatures', () {
    test('accepts ISO base media and WebM headers', () {
      expect(
        MediaSignatureValidator.hasVideoSignature(
          Uint8List.fromList([
            0, 0, 0, 24, ...'ftyp'.codeUnits, ...'isom'.codeUnits, 0, 0, 0, 0,
          ]),
          'mp4',
        ),
        isTrue,
      );
      expect(
        MediaSignatureValidator.hasVideoSignature(
          Uint8List.fromList([0x1A, 0x45, 0xDF, 0xA3, 0x00]),
          'webm',
        ),
        isTrue,
      );
    });

    test('rejects spoofed, truncated and unsupported video files', () {
      expect(
        MediaSignatureValidator.hasVideoSignature(
          Uint8List.fromList('hello world!'.codeUnits),
          'mp4',
        ),
        isFalse,
      );
      expect(
        MediaSignatureValidator.hasVideoSignature(
          Uint8List.fromList([0, 0, 0, 0, ...'ftyp'.codeUnits]),
          'mov',
        ),
        isFalse,
      );
      expect(
        MediaSignatureValidator.hasVideoSignature(
          Uint8List.fromList([1, 2, 3, 4]),
          'avi',
        ),
        isFalse,
      );
    });
  });
}
