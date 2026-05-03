import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart files under lib/ and test/ do not contain mojibake or BOM', () {
    String fromCodeUnits(List<int> units) => String.fromCharCodes(units);

    final forbiddenTokens = <String>[
      fromCodeUnits([0x00C3]),
      fromCodeUnits([0x00C2]),
      fromCodeUnits([0x00F0, 0x0178]),
      fromCodeUnits([0xFFFD]),
      fromCodeUnits([0x00E2, 0x201A, 0x00AC]),
      fromCodeUnits([0x00E2, 0x20AC, 0x00A2]),
      fromCodeUnits([0x00E2, 0x0153]),
    ];

    final root = Directory.current;
    final targets = <Directory>[
      Directory('${root.path}${Platform.pathSeparator}lib'),
      Directory('${root.path}${Platform.pathSeparator}test'),
    ];

    final findings = <String>[];

    for (final dir in targets) {
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final bytes = entity.readAsBytesSync();
        if (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF) {
          findings.add('${entity.path}: UTF-8 BOM found');
        }

        final content = utf8.decode(bytes, allowMalformed: true);
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          for (final token in forbiddenTokens) {
            if (line.contains(token)) {
              findings.add(
                '${entity.path}:${i + 1}: token "${_safeTokenLabel(token)}"',
              );
            }
          }
          if (line.contains(String.fromCharCode(0xFEFF))) {
            findings.add('${entity.path}:${i + 1}: literal BOM marker found');
          }
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: findings.isEmpty
          ? null
          : 'Encoding issues found:\n${findings.join('\n')}',
    );
  });
}

String _safeTokenLabel(String token) {
  final units = token.codeUnits
      .map((unit) => unit.toRadixString(16).padLeft(4, '0'))
      .join(' ');
  return 'U+$units';
}
