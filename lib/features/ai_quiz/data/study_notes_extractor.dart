import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

class StudyNotesExtractor {
  const StudyNotesExtractor();

  Future<String> extract({
    required Uint8List bytes,
    required String extension,
  }) async {
    switch (extension.toLowerCase()) {
      case 'txt':
        return utf8
            .decode(bytes, allowMalformed: true)
            .replaceFirst('\uFEFF', '')
            .trim();
      case 'pdf':
        return compute(_extractPdfText, bytes);
      case 'docx':
        return compute(_extractDocxText, bytes);
      default:
        throw const FormatException('Choose a PDF, TXT, or DOCX notes file.');
    }
  }
}

String _extractPdfText(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    return PdfTextExtractor(document).extractText().trim();
  } finally {
    document.dispose();
  }
}

String _extractDocxText(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final documentFile = archive.findFile('word/document.xml');
  if (documentFile == null) {
    throw const FormatException(
      'This DOCX file does not contain readable notes.',
    );
  }

  final xmlDocument = XmlDocument.parse(utf8.decode(documentFile.content));
  final paragraphs = xmlDocument.findAllElements('w:p');
  final text = paragraphs
      .map(
        (paragraph) => paragraph
            .findAllElements('w:t')
            .map((node) => node.innerText)
            .join(),
      )
      .where((paragraph) => paragraph.trim().isNotEmpty)
      .join('\n');
  return text.trim();
}
