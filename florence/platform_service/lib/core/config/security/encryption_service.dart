/// Encryption Service for FLORENCE Digital Health Platform
/// Provides data encryption utilities for sensitive health information

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for encrypting and decrypting sensitive data
class EncryptionService {
  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Encryption key (In production, store securely in environment/keychain)
  static const String _encryptionKey = 'FLORENCE_ENCRYPTION_KEY_32_CHARS';

  /// Hash a password using SHA-256
  String hashPassword(String password, {String? salt}) {
    final saltValue = salt ?? _generateSalt();
    final bytes = utf8.encode(password + saltValue);
    final hash = sha256.convert(bytes);
    return '${hash.toString()}:$saltValue';
  }

  /// Verify a password against a hash
  bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final hash = parts[0];
    final salt = parts[1];

    final newHash = hashPassword(password, salt: salt);
    return newHash == hashedPassword;
  }

  /// Encrypt sensitive data (simplified version)
  /// In production, use packages like 'encrypt' for AES encryption
  String encryptData(String plaintext) {
    try {
      // Simple Base64 encoding for demonstration
      // TODO: Replace with proper AES-256 encryption in production
      final bytes = utf8.encode(plaintext);
      final encoded = base64Encode(bytes);
      return 'ENC:$encoded';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt sensitive data
  String decryptData(String ciphertext) {
    try {
      if (!ciphertext.startsWith('ENC:')) {
        return ciphertext; // Not encrypted
      }

      final encoded = ciphertext.substring(4);
      final bytes = base64Decode(encoded);
      return utf8.decode(bytes);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Encrypt health data fields
  Map<String, dynamic> encryptHealthData(Map<String, dynamic> data) {
    final encrypted = <String, dynamic>{};

    data.forEach((key, value) {
      // Encrypt sensitive fields
      if (_isSensitiveField(key)) {
        encrypted[key] = encryptData(value.toString());
      } else {
        encrypted[key] = value;
      }
    });

    return encrypted;
  }

  /// Decrypt health data fields
  Map<String, dynamic> decryptHealthData(Map<String, dynamic> data) {
    final decrypted = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String && value.startsWith('ENC:')) {
        decrypted[key] = decryptData(value);
      } else {
        decrypted[key] = value;
      }
    });

    return decrypted;
  }

  /// Check if a field contains sensitive information
  bool _isSensitiveField(String fieldName) {
    const sensitiveFields = [
      'email',
      'phone',
      'address',
      'medical_history',
      'notes',
      'doctor_notes',
      'ssn',
      'national_id',
    ];

    return sensitiveFields.any((field) => fieldName.toLowerCase().contains(field));
  }

  /// Generate a hash for data integrity verification
  String generateDataHash(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify data integrity
  bool verifyDataIntegrity(Map<String, dynamic> data, String expectedHash) {
    final actualHash = generateDataHash(data);
    return actualHash == expectedHash;
  }

  /// Generate a random salt
  String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  /// Generate secure token
  String generateSecureToken({int length = 32}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = timestamp + random + _encryptionKey;
    final hash = sha256.convert(utf8.encode(combined)).toString();
    return hash.substring(0, length);
  }
}

// TODO: For production, integrate proper encryption:
// 1. Add 'encrypt' package to pubspec.yaml
// 2. Use AES-256-GCM encryption
// 3. Store keys in secure storage (flutter_secure_storage)
// 4. Implement key rotation
// 5. Add encryption metadata (algorithm, IV, etc.)
