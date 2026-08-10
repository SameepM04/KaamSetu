import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/dev_config.dart';

/// Uploads profile photos to ImageKit.
///
/// ImageKit (not Firebase Storage) is used specifically for profile images
/// because the Firebase project is currently on the Spark (free) plan —
/// Firebase Storage requires the paid Blaze plan, which is why the old
/// code path (`FirebaseAuthService`/`FakeAuthService` calling
/// `FirebaseStorage.instance`) could never actually succeed in dev mode.
/// Firebase continues to own everything else (Auth, Firestore, jobs,
/// applications, ratings) — see `kaamsetu_profile_photo_final_fix.md`,
/// section 8.
///
/// SECURITY: only the ImageKit *public* key and URL endpoint live in this
/// client. The private key must never ship in the app. A real upload needs
/// a short-lived `token` / `expire` / `signature` triple, which ImageKit
/// requires to be generated **server-side** (their private key signs it).
/// [kImageKitAuthEndpoint] must point at that secure backend endpoint
/// (e.g. a Firebase Cloud Function) — see `dev_config.dart` for wiring
/// instructions. Until that endpoint is configured, this service fails
/// loudly with [ImageKitException] instead of pretending to succeed.
class ImageKitService {
  ImageKitService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  /// Uploads [bytes] as [fileName] under [folder] and returns the public
  /// ImageKit URL for the uploaded file. Throws [ImageKitException] on any
  /// failure — callers must NOT fall back to a local file path or a
  /// fabricated URL (see spec section 13, "Failure behavior").
  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    String folder = '/profile-photos',
  }) async {
    if (kImageKitPublicKey.isEmpty || kImageKitUrlEndpoint.isEmpty) {
      throw ImageKitException(
        'ImageKit is not configured yet — kImageKitPublicKey / '
        'kImageKitUrlEndpoint are empty in lib/config/dev_config.dart.',
      );
    }
    if (kImageKitAuthEndpoint.isEmpty) {
      throw ImageKitException(
        'No ImageKit authentication endpoint is configured. Profile-photo '
        'uploads need a server-issued token/signature/expire (ImageKit\'s '
        'private key must stay server-side) — set kImageKitAuthEndpoint '
        'in lib/config/dev_config.dart to your Cloud Function URL once '
        'it is deployed.',
      );
    }

    final auth = await _fetchUploadAuth();

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['publicKey'] = kImageKitPublicKey
      ..fields['signature'] = auth.signature
      ..fields['expire'] = auth.expire
      ..fields['token'] = auth.token
      ..fields['fileName'] = fileName
      ..fields['folder'] = folder
      ..fields['useUniqueFileName'] = 'true'
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: fileName));

    final http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request);
    } catch (e) {
      throw ImageKitException('ImageKit upload request failed: $e');
    }
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('ImageKit upload failed', response);
      throw ImageKitException(
          'ImageKit upload failed (HTTP ${response.statusCode}).');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _log('ImageKit upload returned unparsable response', response);
      throw ImageKitException('ImageKit returned an unexpected response.');
    }

    final url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      _log('ImageKit response had no url field', response);
      throw ImageKitException('ImageKit response did not include a URL.');
    }
    return url;
  }

  Future<_UploadAuth> _fetchUploadAuth() async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(kImageKitAuthEndpoint));
    } catch (e) {
      throw ImageKitException('ImageKit authentication failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('ImageKit authentication endpoint failed', response);
      throw ImageKitException(
          'ImageKit authentication failed (HTTP ${response.statusCode}).');
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _UploadAuth(
        token: data['token'] as String,
        expire: data['expire'].toString(),
        signature: data['signature'] as String,
      );
    } catch (e) {
      _log('ImageKit authentication response malformed', response);
      throw ImageKitException(
          'ImageKit authentication returned an unexpected response.');
    }
  }

  /// Logs the real technical error in debug builds only — never in
  /// release, and never including secrets (only the public key, endpoint
  /// URL, and response body/status are ever exposed to this client).
  void _log(String message, http.Response response) {
    if (kDebugMode) {
      debugPrint('[ImageKitService] $message\n'
          'HTTP status: ${response.statusCode}\n'
          'Response: ${response.body}');
    }
  }
}

class _UploadAuth {
  _UploadAuth(
      {required this.token, required this.expire, required this.signature});
  final String token;
  final String expire;
  final String signature;
}

/// Thrown for any ImageKit failure. [message] is safe to log; show the
/// user a generic message and keep the previously-persisted photo.
class ImageKitException implements Exception {
  ImageKitException(this.message);
  final String message;

  @override
  String toString() => 'ImageKitException: $message';
}
