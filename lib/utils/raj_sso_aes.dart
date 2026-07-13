import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// Raj SSO password encryption (REST API Mobile v2.6.1 §3.1).
///
/// AES/CBC/PKCS5Padding is **mandated by Raj SSO** — cannot switch to GCM without
/// SSO platform change. Transport uses HTTPS only (`network_security_config.xml`).
class RajSsoAes {
  RajSsoAes._();

  static Key _keyFromSecret(String secretKey) {
    final parameterKeyBytes = utf8.encode(secretKey);
    final keyBytes = Uint8List(16);
    for (var i = 0; i < parameterKeyBytes.length && i < 16; i++) {
      keyBytes[i] = parameterKeyBytes[i];
    }
    return Key(keyBytes);
  }

  /// Encrypts [plainText] for Raj SSO REST `Password` field (Base64 output).
  static String encryptPassword(String plainText, String secretKey) {
    if (plainText.isEmpty) return '';
    final key = _keyFromSecret(secretKey);
    final iv = IV(key.bytes);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }
}
