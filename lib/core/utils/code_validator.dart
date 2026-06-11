class CodeValidator {
  CodeValidator._();

  static final RegExp _validCode = RegExp(r'^[a-z0-9]{4,12}$');

  static bool isValidShortCode(String code) => _validCode.hasMatch(code);
}
