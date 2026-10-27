import 'dart:typed_data';

/// Lightweight file-signature checks used before media is uploaded.
/// These checks reject obvious extension/MIME spoofing; they do not replace
/// server-side scanning or a full media decoder.
class MediaSignatureValidator {
  const MediaSignatureValidator._();

  static bool hasImageSignature(Uint8List bytes, String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
      case 'jpg':
      case 'jpeg':
        return bytes.length >= 3 &&
            bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      case 'png':
        return bytes.length >= 8 &&
            bytes[0] == 0x89 && bytes[1] == 0x50 &&
            bytes[2] == 0x4E && bytes[3] == 0x47 &&
            bytes[4] == 0x0D && bytes[5] == 0x0A &&
            bytes[6] == 0x1A && bytes[7] == 0x0A;
      case 'gif':
        if (bytes.length < 6) return false;
        final header = String.fromCharCodes(bytes.sublist(0, 6));
        return header == 'GIF87a' || header == 'GIF89a';
      case 'webp':
        return bytes.length >= 12 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      default:
        return false;
    }
  }

  static bool hasVideoSignature(Uint8List bytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'webm') {
      return bytes.length >= 4 &&
          bytes[0] == 0x1A && bytes[1] == 0x45 &&
          bytes[2] == 0xDF && bytes[3] == 0xA3;
    }
    if (!{'mp4', 'mov', 'm4v', '3gp'}.contains(ext)) return false;
    return bytes.length >= 12 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 &&
        bytes[6] == 0x79 && bytes[7] == 0x70;
  }
}
