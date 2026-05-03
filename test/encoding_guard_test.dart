import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tracked text files do not contain mojibake or BOM', () {
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
    final targets = <String>{
      '.editorconfig',
      '.vscode/settings.json',
      'pubspec.yaml',
    };

    final readme = File('${root.path}${Platform.pathSeparator}README.md');
    if (readme.existsSync()) {
      targets.add('README.md');
    }

    final libDir = Directory('${root.path}${Platform.pathSeparator}lib');
    final testDir = Directory('${root.path}${Platform.pathSeparator}test');

    for (final dir in [libDir, testDir]) {
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          targets.add(_relativePath(root.path, entity.path));
        }
      }
    }

    final findings = <String>[];

    for (final relative in targets) {
      final fullPath =
          '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
      final file = File(fullPath);
      if (!file.existsSync()) continue;

      final bytes = file.readAsBytesSync();
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        findings.add('$relative: UTF-8 BOM found');
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final token in forbiddenTokens) {
          if (line.contains(token)) {
            findings.add(
              '$relative:${i + 1}: token "${_safeTokenLabel(token)}"',
            );
          }
        }
        if (line.contains(String.fromCharCode(0xFEFF))) {
          findings.add('$relative:${i + 1}: literal BOM marker found');
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

String _relativePath(String rootPath, String fullPath) {
  final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
      ? rootPath
      : '$rootPath${Platform.pathSeparator}';
  if (fullPath.startsWith(normalizedRoot)) {
    return fullPath.substring(normalizedRoot.length).replaceAll('\\', '/');
  }
  return fullPath.replaceAll('\\', '/');
}

String _safeTokenLabel(String token) {
  final units = token.codeUnits
      .map((unit) => unit.toRadixString(16).padLeft(4, '0'))
      .join(' ');
  return 'U+$units';
}
