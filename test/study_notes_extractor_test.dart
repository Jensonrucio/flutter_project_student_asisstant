import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:student_assistant_app/features/ai_quiz/data/study_notes_extractor.dart';

void main() {
  const extractor = StudyNotesExtractor();

  test('extracts UTF-8 text notes and removes a byte-order mark', () async {
    final notes = await extractor.extract(
      bytes: Uint8List.fromList(utf8.encode('\uFEFFCell biology notes')),
      extension: 'txt',
    );

    expect(notes, 'Cell biology notes');
  });

  test('rejects unsupported note file types', () async {
    await expectLater(
      extractor.extract(
        bytes: Uint8List.fromList(utf8.encode('notes')),
        extension: 'rtf',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts paragraphs from a DOCX notes document', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'word/document.xml',
          '<w:document xmlns:w="urn:word"><w:body>'
              '<w:p><w:r><w:t>Cell membranes</w:t></w:r></w:p>'
              '<w:p><w:r><w:t>Control transport</w:t></w:r></w:p>'
              '</w:body></w:document>',
        ),
      );
    final bytes = ZipEncoder().encode(archive);

    final notes = await extractor.extract(
      bytes: Uint8List.fromList(bytes),
      extension: 'docx',
    );

    expect(notes, 'Cell membranes\nControl transport');
  });

  test('extracts selectable text from a PDF notes document', () async {
    final document = PdfDocument();
    document.pages.add().graphics.drawString(
      'Photosynthesis notes',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    final bytes = document.saveSync();
    document.dispose();

    final notes = await extractor.extract(
      bytes: Uint8List.fromList(bytes),
      extension: 'pdf',
    );

    expect(notes, contains('Photosynthesis notes'));
  });
}
