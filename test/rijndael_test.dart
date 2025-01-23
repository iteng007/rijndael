import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:rijndael/src/rijndael_base.dart';
import 'package:rijndael/src/paddings.dart';

void main() {
  test('test_rijndael', () {
    const key = 'qBS8uRhEIBsr8jr8vuY9uUpGFefYRL2HSTtrKhaI1tk=';

    final rijndael = Rijndael(base64.decode(key), blockSize: 32);
    final plainText = Uint8List.fromList(utf8.encode('Mahdi'));
    final paddedText = Uint8List(32)
      ..setAll(0, plainText)
      ..fillRange(plainText.length, 32, 0x1b);
    final cipher = rijndael.encrypt(paddedText);
    final cipherText = base64.encode(cipher);
    expect(cipherText, equals('Kc8C3vjf+EpLRmgTZ5ckWTzJ/6n7WBHW8pkByDscI/E='));
    expect(rijndael.decrypt(cipher), equals(paddedText));

    // Block size
    for (final blockSize in [16, 24, 32]) {
      final rijndael2 = Rijndael(base64.decode(key), blockSize: blockSize);
      final plainText = 'lorem';
      final paddedText = Uint8List(blockSize)
        ..setAll(0, utf8.encode(plainText))
        ..fillRange(utf8.encode(plainText).length, blockSize, 0x1b);
      final cipher = rijndael2.encrypt(paddedText);
      expect(rijndael2.decrypt(cipher), equals(paddedText));
    }

    // Exceptions
    expect(() {
      final plainText = 'Hey' * 20;
      final paddedText = Uint8List(32)
        ..setAll(0, utf8.encode(plainText))
        ..fillRange(utf8.encode(plainText).length, 32, 0x1b);
      rijndael.encrypt(paddedText);
    }, throwsArgumentError);

    expect(() {
      Rijndael(base64.decode(key), blockSize: 62);
    }, throwsArgumentError);

    expect(() {
      final keyBytes = base64.decode(key);
      final longKey = Uint8List(keyBytes.length * 20)
        ..setAll(0, List.filled(20, keyBytes).expand((x) => x));
      Rijndael(longKey, blockSize: 32);
    }, throwsArgumentError);

    expect(() {
      final plainText = 'Hey';
      final paddedText = Uint8List(32)
        ..setAll(0, utf8.encode(plainText))
        ..fillRange(utf8.encode(plainText).length, 32, 0x1b);
      final cipher = rijndael.encrypt(paddedText);
      final longCipher = Uint8List(cipher.length * 12)
        ..setAll(0, List.filled(12, cipher).expand((x) => x));
      rijndael.decrypt(longCipher);
    }, throwsArgumentError);
  });

  test('test_rijndael_cbc', () {
    // Exactly like Python test
    const key = 'qBS8uRhEIBsr8jr8vuY9uUpGFefYRL2HSTtrKhaI1tk=';
    const iv = 'kByhT6PjYHzJzZfXvb8Aw5URMbQnk6NM+g3IV5siWD4=';
    
    final rijndaelCbc = RijndaelCbc(
      base64.decode(key),
      base64.decode(iv),
      const ZeroPadding(32),
      blockSize: 32
    );

    // First test case - exactly like Python
    final plainText = Uint8List.fromList(utf8.encode('Mahdi'));
    // Python: padded_text = plain_text.ljust(32, b'\x1b')
    final paddedText = Uint8List(32)
      ..setAll(0, plainText)
      ..fillRange(plainText.length, 32, 0x1b);
    
    final cipher = rijndaelCbc.encrypt(paddedText);
    final cipherText = base64.encode(cipher);
    
    expect(cipherText, equals('1KGc0PMt52Xbell+2y9qDJJp/Yy6b1JR1JWI3f9ALF4='));
    expect(rijndaelCbc.decrypt(cipher), equals(paddedText));

    // Second test case - exactly like Python
    // Python: plain_text = b'lorem' * 50
    final longPlainText = Uint8List.fromList(
      List.filled(50, 'lorem').join().codeUnits
    );
    // Python: padded_text = plain_text.ljust(32, b'\x1b')
    final longPaddedText = Uint8List(32)
      ..setAll(0, longPlainText.sublist(0, 32))
      ..fillRange(32, 32, 0x1b);
    
    final longCipher = rijndaelCbc.encrypt(longPaddedText);
    expect(rijndaelCbc.decrypt(longCipher), equals(longPaddedText));
  });
}
