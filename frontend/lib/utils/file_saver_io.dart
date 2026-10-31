import 'dart:io';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareCSV(String csvContent, String filename) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(csvContent);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: filename,
    text: 'Exported customer list.',
    sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
  );
}
