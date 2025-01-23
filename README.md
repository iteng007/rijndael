# Rijndael

A pure Dart implementation of the Rijndael (AES) cipher, supporting multiple block sizes, CBC mode, and various padding schemes.

## Features

- Pure Dart implementation
- Supports block sizes: 16, 24, and 32 bytes
- CBC mode support
- PKCS7 and Zero padding implementations
- No external dependencies

## Usage

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:rijndael/rijndael.dart';

void main() {
  // Basic usage
  const key = 'qBS8uRhEIBsr8jr8vuY9uUpGFefYRL2HSTtrKhaI1tk=';
  final rijndael = Rijndael(base64.decode(key), blockSize: 32);
  
  final plainText = Uint8List.fromList(utf8.encode('Hello, World!'));
  final paddedText = Uint8List(32)
    ..setAll(0, plainText)
    ..fillRange(plainText.length, 32, 0x1b);
  
  final cipher = rijndael.encrypt(paddedText);
  final decrypted = rijndael.decrypt(cipher);

  // CBC mode with padding
  const iv = 'kByhT6PjYHzJzZfXvb8Aw5URMbQnk6NM+g3IV5siWD4=';
  final rijndaelCbc = RijndaelCbc(
    base64.decode(key),
    base64.decode(iv),
    const ZeroPadding(32),
    blockSize: 32
  );

  final cbcCipher = rijndaelCbc.encrypt(plainText);
  final cbcDecrypted = rijndaelCbc.decrypt(cbcCipher);
}
```

## Additional Information

This is a port of the Python implementation to Dart, maintaining the same functionality and API where possible.

For more examples, see the `example` directory.