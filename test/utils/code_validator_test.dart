import 'package:fluffy_link/core/utils/code_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts valid short codes', () {
    expect(CodeValidator.isValidShortCode('abc123'), isTrue);
    expect(CodeValidator.isValidShortCode('abcd'), isTrue);
    expect(CodeValidator.isValidShortCode('a1b2c3d4e5f6'), isTrue);
  });

  test('rejects invalid short codes', () {
    expect(CodeValidator.isValidShortCode('ab'), isFalse);
    expect(CodeValidator.isValidShortCode('abc!'), isFalse);
    expect(CodeValidator.isValidShortCode('ABC123'), isFalse);
    expect(CodeValidator.isValidShortCode('a1b2c3d4e5f6g'), isFalse);
  });
}
