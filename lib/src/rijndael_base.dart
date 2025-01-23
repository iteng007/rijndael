// // TODO: Put public facing types in this file.

// /// Checks if you are awesome. Spoiler: you are.
// class Awesome {
//   bool get isAwesome => true;
// }

import 'dart:typed_data';
import 'constants.dart';
import 'paddings.dart';

/// Rijndael cipher implementation
///
/// Implements the Rijndael cipher with support for multiple block sizes.
/// This is the base implementation that operates on single blocks.
class Rijndael {
  final int blockSize;
  final Uint8List key;
  late final List<List<int>> Ke; // encryption round keys
  late final List<List<int>> Kd; // decryption round keys

  Rijndael(this.key, {this.blockSize = 16}) {
    if (![16, 24, 32].contains(blockSize)) {
      throw ArgumentError('Invalid block size: $blockSize');
    }
    if (![16, 24, 32].contains(key.length)) {
      throw ArgumentError('Invalid key size: ${key.length}');
    }

    final rounds = numRounds[key.length]![blockSize]!;
    final bc = blockSize ~/ 4;
    
    // Exactly like Python: k_e = [[0] * b_c for _ in range(rounds + 1)]
    Ke = List.generate(rounds + 1, (_) => List.filled(bc, 0));
    Kd = List.generate(rounds + 1, (_) => List.filled(bc, 0));
    
    final roundKeyCount = (rounds + 1) * bc;
    final kc = key.length ~/ 4;

    // Exactly like Python: tk = []
    var tk = <int>[];
    
    // Exactly like Python's byte handling with ord()
    for (var i = 0; i < kc; i++) {
      tk.add(
        (key[i * 4] << 24) |
        (key[i * 4 + 1] << 16) |
        (key[i * 4 + 2] << 8) |
        key[i * 4 + 3]
      );
    }

    // Exactly like Python's copy into round key arrays
    var t = 0;
    var j = 0;
    while (j < kc && t < roundKeyCount) {
      Ke[t ~/ bc][t % bc] = tk[j];
      Kd[rounds - (t ~/ bc)][t % bc] = tk[j];
      j++;
      t++;
    }

    // Exactly like Python's key schedule generation
    var rconPointer = 0;
    while (t < roundKeyCount) {
      var tt = tk[kc - 1];
      tk[0] ^= (S[(tt >> 16) & 0xFF] << 24) ^
               (S[(tt >> 8) & 0xFF] << 16) ^
               (S[tt & 0xFF] << 8) ^
               S[(tt >> 24) & 0xFF] ^
               (rCon[rconPointer] << 24);
      rconPointer++;

      if (kc != 8) {
        for (var i = 1; i < kc; i++) {
          tk[i] ^= tk[i - 1];
        }
      } else {
        for (var i = 1; i < kc ~/ 2; i++) {
          tk[i] ^= tk[i - 1];
        }
        tt = tk[kc ~/ 2 - 1];
        tk[kc ~/ 2] ^= S[tt & 0xFF] ^
                       (S[(tt >> 8) & 0xFF] << 8) ^
                       (S[(tt >> 16) & 0xFF] << 16) ^
                       (S[(tt >> 24) & 0xFF] << 24);
        for (var i = kc ~/ 2 + 1; i < kc; i++) {
          tk[i] ^= tk[i - 1];
        }
      }

      j = 0;
      while (j < kc && t < roundKeyCount) {
        Ke[t ~/ bc][t % bc] = tk[j];
        Kd[rounds - (t ~/ bc)][t % bc] = tk[j];
        j++;
        t++;
      }
    }

    // Exactly like Python's inverse MixColumn
    for (var r = 1; r < rounds; r++) {
      for (var j = 0; j < bc; j++) {
        var tt = Kd[r][j];
        Kd[r][j] = U1[(tt >> 24) & 0xFF] ^
                   U2[(tt >> 16) & 0xFF] ^
                   U3[(tt >> 8) & 0xFF] ^
                   U4[tt & 0xFF];
      }
    }
  }

  Uint8List encrypt(Uint8List source) {
    if (source.length != blockSize) {
      throw ArgumentError('Wrong block length, expected $blockSize got ${source.length}');
    }

    final bc = blockSize ~/ 4;
    final rounds = Ke.length - 1;
    final sc = bc == 4 ? 0 : (bc == 6 ? 1 : 2);
    
    final s1 = shifts[sc][1][0];
    final s2 = shifts[sc][2][0];
    final s3 = shifts[sc][3][0];

    // Exactly like Python: t = []
    var t = <int>[];
    var a = List<int>.filled(bc, 0);

    // Exactly like Python's byte handling
    for (var i = 0; i < bc; i++) {
      t.add(
        (source[i * 4] << 24) |
        (source[i * 4 + 1] << 16) |
        (source[i * 4 + 2] << 8) |
        source[i * 4 + 3]
      );
      t[i] ^= Ke[0][i];
    }

    // Exactly like Python's round transforms
    for (var r = 1; r < rounds; r++) {
      for (var i = 0; i < bc; i++) {
        a[i] = T1[(t[i] >> 24) & 0xFF] ^
               T2[(t[(i + s1) % bc] >> 16) & 0xFF] ^
               T3[(t[(i + s2) % bc] >> 8) & 0xFF] ^
               T4[t[(i + s3) % bc] & 0xFF] ^
               Ke[r][i];
      }
      t = List<int>.from(a);
    }

    // Exactly like Python's final round
    var result = <int>[];
    for (var i = 0; i < bc; i++) {
      var tt = Ke[rounds][i];
      result.add((S[(t[i] >> 24) & 0xFF] ^ (tt >> 24)) & 0xFF);
      result.add((S[(t[(i + s1) % bc] >> 16) & 0xFF] ^ (tt >> 16)) & 0xFF);
      result.add((S[(t[(i + s2) % bc] >> 8) & 0xFF] ^ (tt >> 8)) & 0xFF);
      result.add((S[t[(i + s3) % bc] & 0xFF] ^ tt) & 0xFF);
    }

    return Uint8List.fromList(result);
  }

  Uint8List decrypt(Uint8List cipher) {
    if (cipher.length != blockSize) {
      throw ArgumentError(
          'Wrong block length, expected $blockSize got ${cipher.length}');
    }

    final bc = blockSize ~/ 4;
    final rounds = Kd.length - 1;
    final sc = blockSize == 16 ? 0 : (blockSize == 24 ? 1 : 2);
    
    final s1 = shifts[sc][1][1];
    final s2 = shifts[sc][2][1];
    final s3 = shifts[sc][3][1];

    var t = List<int>.filled(bc, 0);
    var a = List<int>.filled(bc, 0);

    // Cipher to ints + key
    for (var i = 0; i < bc; i++) {
      t[i] = ((cipher[i * 4] & 0xFF) << 24) |
             ((cipher[i * 4 + 1] & 0xFF) << 16) |
             ((cipher[i * 4 + 2] & 0xFF) << 8) |
             (cipher[i * 4 + 3] & 0xFF);
      t[i] ^= Kd[0][i];
    }

    // Apply round transforms
    for (var r = 1; r < rounds; r++) {
      for (var i = 0; i < bc; i++) {
        a[i] = T5[(t[i] >> 24) & 0xFF] ^
               T6[(t[(i + s1) % bc] >> 16) & 0xFF] ^
               T7[(t[(i + s2) % bc] >> 8) & 0xFF] ^
               T8[t[(i + s3) % bc] & 0xFF] ^
               Kd[r][i];
      }
      t = List<int>.from(a);
    }

    // Final round
    final result = Uint8List(blockSize);
    var pos = 0;
    
    for (var i = 0; i < bc; i++) {
      final tt = Kd[rounds][i];
      result[pos++] = (Si[(t[i] >> 24) & 0xFF] ^ (tt >> 24)) & 0xFF;
      result[pos++] = (Si[(t[(i + s1) % bc] >> 16) & 0xFF] ^ (tt >> 16)) & 0xFF;
      result[pos++] = (Si[(t[(i + s2) % bc] >> 8) & 0xFF] ^ (tt >> 8)) & 0xFF;
      result[pos++] = (Si[t[(i + s3) % bc] & 0xFF] ^ tt) & 0xFF;
    }

    return result;
  }
}

/// Rijndael CBC mode implementation
///
/// Implements the Cipher Block Chaining (CBC) mode of operation
/// for the Rijndael cipher.
class RijndaelCbc extends Rijndael {
  final Uint8List iv;
  final PaddingBase padding;

  RijndaelCbc(Uint8List key, this.iv, this.padding, {int blockSize = 16})
      : super(key, blockSize: blockSize);

  @override
  Uint8List encrypt(Uint8List source) {
    final ppt = padding.encode(source);
    var offset = 0;
    var ct = Uint8List(0);
    var v = iv;

    while (offset < ppt.length) {
      var block = ppt.sublist(offset, offset + blockSize);
      block = xorBlock(block, v);
      block = super.encrypt(block);
      ct = Uint8List.fromList([...ct, ...block]);
      offset += blockSize;
      v = block;
    }
    return ct;
  }

  @override
  Uint8List decrypt(Uint8List cipher) {
    if (cipher.length % blockSize != 0) {
      throw ArgumentError('Invalid cipher length');
    }

    var offset = 0;
    var ppt = Uint8List(0);
    var v = iv;

    while (offset < cipher.length) {
      final block = cipher.sublist(offset, offset + blockSize);
      final decrypted = super.decrypt(block);
      ppt = Uint8List.fromList([...ppt, ...xorBlock(decrypted, v)]);
      offset += blockSize;
      v = block;
    }

    return padding.decode(ppt);
  }

  Uint8List xorBlock(Uint8List b1, Uint8List b2) {
    var r = Uint8List(0);
    for (var i = 0; i < blockSize; i++) {
      r = Uint8List.fromList([...r, b1[i] ^ b2[i]]);
    }
    return r;
  }
}
