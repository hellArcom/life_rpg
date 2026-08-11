import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/server_service.dart';
import '../ui/screens/update_screen.dart';

class UpdateService {
  // S'il n'y a pas de mise à jour à faire, rien ne s'affiche.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final data = await ServerService.fetchUpdate();
      if (data == null) return;

      final String latestVersion = data['version'] ?? '';
      final String downloadUrl = data['download_url'] ?? '';
      final String releaseNotes = data['release_notes'] ?? '';
      if (latestVersion.isEmpty || downloadUrl.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      if (_isVersionGreater(latestVersion, currentVersion) && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UpdateScreen(
              version: latestVersion,
              downloadUrl: downloadUrl,
              releaseNotes: releaseNotes,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la mise à jour : $e');
    }
  }

  static bool _isVersionGreater(String latest, String current) {
    final int? latestNum = _parse(latest);
    final int? currentNum = _parse(current);
    if (latestNum == null || currentNum == null) return false;
    return latestNum > currentNum;
  }

  static int? _parse(String v) {
    final parts = v.trim().split('.');
    var total = 0;
    for (var i = 0; i < parts.length; i++) {
      final n = int.tryParse(parts[i]);
      if (n == null || n < 0) return null;
      total = total * 1000 + n;
    }
    return total;
  }
}