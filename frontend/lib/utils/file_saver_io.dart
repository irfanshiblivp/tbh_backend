import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareCSV(String csvContent, String filename) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(csvContent);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: filename,
    text: 'Exported customer list.',
  );
}
