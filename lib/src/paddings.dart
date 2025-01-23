import 'dart:typed_data';

/// Base class for padding implementations
abstract class PaddingBase {
  /// Block size for the padding
  final int blockSize;

  /// Creates a new padding instance with the given block size
  const PaddingBase(this.blockSize);

  /// Encodes (pads) the source data
  Uint8List encode(Uint8List source);

  /// Decodes (removes padding from) the source data
  Uint8List decode(Uint8List source);
}

/// Zero padding implementation as specified in ISO/IEC 10118-1 and ISO/IEC 9797-1
class ZeroPadding extends PaddingBase {
  /// Creates a new zero padding instance
  const ZeroPadding(super.blockSize);

  @override
  Uint8List encode(Uint8List source) {
    final padSize = blockSize - ((source.length + blockSize - 1) % blockSize + 1);
    return Uint8List.fromList([...source, ...List.filled(padSize, 0)]);
  }

  @override
  Uint8List decode(Uint8List source) {
    if (source.length % blockSize != 0) {
      throw ArgumentError('Input length must be multiple of block size');
    }
    if (source.isEmpty) {
      return Uint8List(0);
    }

    var offset = source.length;
    final end = offset - blockSize + 1;

    while (offset > end) {
      offset--;
      if (source[offset] != 0) {
        return Uint8List.fromList(source.sublist(0, offset + 1));
      }
    }

    return Uint8List.fromList(source.sublist(0, end));
  }
}

/// PKCS7 padding implementation as defined in RFC 2315
class Pkcs7Padding extends PaddingBase {
  /// Creates a new PKCS7 padding instance
  const Pkcs7Padding(super.blockSize);

  @override
  Uint8List encode(Uint8List source) {
    var amountToPad = blockSize - (source.length % blockSize);
    if (amountToPad == 0) {
      amountToPad = blockSize;
    }

    return Uint8List.fromList([...source, ...List.filled(amountToPad, amountToPad)]);
  }

  @override
  Uint8List decode(Uint8List source) {
    return Uint8List.fromList(source.sublist(0, source.length - source.last));
  }
} 