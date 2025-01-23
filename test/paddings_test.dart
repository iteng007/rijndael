import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:rijndael/src/paddings.dart';

void main() {
  group('PaddingTestCase', () {
    test('test_zero_padding', () {
      final padding = ZeroPadding(16);

      // Full length
      final source = Uint8List.fromList('loremipsumdolors'.codeUnits);
      final encodedSource = padding.encode(source);
      expect(encodedSource, equals(source));
      expect(encodedSource.length, equals(16));
      expect(padding.decode(encodedSource), equals(source));

      // Length 2
      final source2 = Uint8List.fromList('hi'.codeUnits);
      final encodedSource2 = padding.encode(source2);
      expect(
        encodedSource2,
        equals(Uint8List.fromList([...source2, ...List.filled(14, 0)])),
      );
      expect(encodedSource2.length, equals(16));
      expect(padding.decode(encodedSource2), equals(source2));

      // Length 1
      final source3 = Uint8List.fromList('h'.codeUnits);
      final encodedSource3 = padding.encode(source3);
      expect(
        encodedSource3,
        equals(Uint8List.fromList([...source3, ...List.filled(15, 0)])),
      );
      expect(encodedSource3.length, equals(16));
      expect(padding.decode(encodedSource3), equals(source3));

      // Zero length
      expect(padding.decode(Uint8List(0)), equals(Uint8List(0)));

      // Wrong value to decode
      expect(
        () => padding.decode(Uint8List.fromList('no-padding'.codeUnits)),
        throwsArgumentError,
      );
    });

    test('test_pkcs7_padding', () {
      final padding = Pkcs7Padding(16);

      // Basic test
      final source = Uint8List.fromList('hi'.codeUnits);
      final encodedSource = padding.encode(source);
      expect(
        encodedSource,
        equals(Uint8List.fromList([...source, ...List.filled(14, 0x0e)])),
      );
      expect(encodedSource.length, equals(16));
      expect(padding.decode(encodedSource), equals(source));

      // Empty string
      final emptySource = Uint8List(0);
      final encodedEmpty = padding.encode(emptySource);
      expect(
        encodedEmpty,
        equals(Uint8List.fromList(List.filled(16, 0x10))),
      );
      expect(padding.decode(encodedEmpty), equals(emptySource));

      // Long string
      final longSource = Uint8List.fromList(
        'this string is long enough to span blocks'.codeUnits,
      );
      final encodedLong = padding.encode(longSource);
      expect(
        encodedLong,
        equals(Uint8List.fromList([...longSource, ...List.filled(7, 0x07)])),
      );
      expect(encodedLong.length, equals(48));
      expect(encodedLong.length % 16, equals(0));
      expect(padding.decode(encodedLong), equals(longSource));

      // Max block size
      final maxPadding = Pkcs7Padding(255);
      final shortSource = Uint8List.fromList('hi'.codeUnits);
      final encodedMax = maxPadding.encode(shortSource);
      expect(encodedMax.length, equals(255));
    });
  });
} 