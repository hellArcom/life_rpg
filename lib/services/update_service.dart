import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // url pas encore parfaitement fonctionnelle. A cause de la redirection 
  static const String _updateUrl = 'https://liferpg.dpdns.org/static/version.json';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_updateUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = data['version'];
        final String downloadUrl = data['download_url'];
        final String releaseNotes = data['release_notes'] ?? '';

        final packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (_isVersionGreater(latestVersion, currentVersion) && context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la mise à jour : $e');
    }
  }

  static bool _isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Mise à jour disponible ($version)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Une nouvelle version de Life RPG est disponible.'),
            if (notes.isNotEmpty) ...[
              SizedBox(height: 10),
              Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(notes),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}
