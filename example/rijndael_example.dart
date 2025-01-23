import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:rijndael/rijndael.dart';

void main() {
  // Basic Rijndael usage
  const key = 'qBS8uRhEIBsr8jr8vuY9uUpGFefYRL2HSTtrKhaI1tk=';
  final rijndael = Rijndael(base64.decode(key), blockSize: 32);
  
  final plainText = Uint8List.fromList(utf8.encode('Mahdi'));
  final paddedText = Uint8List(32)
    ..setAll(0, plainText)
    ..fillRange(plainText.length, 32, 0x1b);
  
  final cipher = rijndael.encrypt(paddedText);
  final decrypted = rijndael.decrypt(cipher);
  print('Decrypted text matches: ${ListEquality().equals(decrypted, paddedText)}');

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
  print('CBC decrypted text matches: ${utf8.decode(cbcDecrypted.sublist(0, plainText.length))}');
}