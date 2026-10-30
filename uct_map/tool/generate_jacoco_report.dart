// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  final lcovFile = File('coverage/lcov.info');
  final outputFile = File('coverage/jacoco.xml');
  const targetThreshold = 90.0;
  final failUnder = args.contains('--fail-under');

  if (!lcovFile.existsSync()) {
    stderr.writeln('Error: Archivo coverage/lcov.info no encontrado.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  final files = <_FileCoverage>[];

  _FileCoverage? current;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      current = _FileCoverage(path: line.substring(3).trim());
    } else if (line.startsWith('DA:') && current != null) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final lineNum = int.tryParse(parts[0]) ?? 0;
        final count = int.tryParse(parts[1]) ?? 0;
        current.lines[lineNum] = count;
      }
    } else if (line.startsWith('LF:') && current != null) {
      current.linesFound = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:') && current != null) {
      current.linesHit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.trim() == 'end_of_record' && current != null) {
      files.add(current);
      current = null;
    }
  }

  int totalFound = 0;
  int totalHit = 0;
  for (final f in files) {
    totalFound += f.linesFound;
    totalHit += f.linesHit;
  }

  final coveragePct = totalFound > 0 ? (totalHit / totalFound) * 100 : 0.0;
  final totalMissed = totalFound - totalHit;

  // Group by directory as packages
  final packages = <String, List<_FileCoverage>>{};
  for (final f in files) {
    final segments = f.path.split('/');
    final pkgName = segments.length > 1
        ? segments.sublist(0, segments.length - 1).join('.')
        : 'default';
    packages.putIfAbsent(pkgName, () => []).add(f);
  }

  final xml = StringBuffer();
  xml.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  xml.writeln('<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd">');
  xml.writeln('<report name="uct_map">');

  for (final entry in packages.entries) {
    final pkg = entry.key;
    final pkgFiles = entry.value;
    int pkgFound = 0;
    int pkgHit = 0;

    for (final f in pkgFiles) {
      pkgFound += f.linesFound;
      pkgHit += f.linesHit;
    }
    final pkgMissed = pkgFound - pkgHit;

    xml.writeln('  <package name="$pkg">');
    for (final f in pkgFiles) {
      final fileName = f.path.split('/').last;
      final className = f.path.replaceAll('.dart', '');
      final fileMissed = f.linesFound - f.linesHit;

      xml.writeln('    <class name="$className" sourcefilename="$fileName">');
      xml.writeln('      <counter type="LINE" missed="$fileMissed" covered="${f.linesHit}"/>');
      xml.writeln('    </class>');
      xml.writeln('    <sourcefile name="$fileName">');
      final sortedLines = f.lines.keys.toList()..sort();
      for (final nr in sortedLines) {
        final hit = f.lines[nr]! > 0;
        xml.writeln('      <line nr="$nr" mi="${hit ? 0 : 1}" ci="${hit ? 1 : 0}"/>');
      }
      xml.writeln('      <counter type="LINE" missed="$fileMissed" covered="${f.linesHit}"/>');
      xml.writeln('    </sourcefile>');
    }
    xml.writeln('    <counter type="LINE" missed="$pkgMissed" covered="$pkgHit"/>');
    xml.writeln('  </package>');
  }

  xml.writeln('  <counter type="INSTRUCTION" missed="$totalMissed" covered="$totalHit"/>');
  xml.writeln('  <counter type="LINE" missed="$totalMissed" covered="$totalHit"/>');
  xml.writeln('</report>');

  outputFile.writeAsStringSync(xml.toString());

  print('======================================================');
  print('          REPORTE DE COBERTURA JACOCO                 ');
  print('======================================================');
  print('Archivo generado: ${outputFile.path}');
  print('Líneas evaluadas: $totalFound');
  print('Líneas cubiertas: $totalHit ($totalMissed no cubiertas)');
  print('Cobertura actual: ${coveragePct.toStringAsFixed(2)}%');
  print('Umbral objetivo : ${targetThreshold.toStringAsFixed(2)}%');
  print('======================================================');

  if (coveragePct >= targetThreshold) {
    print('✅ Cobertura cumple con el umbral del $targetThreshold%');
  } else {
    print('⚠️ Cobertura actual (${coveragePct.toStringAsFixed(2)}%) inferior al umbral del $targetThreshold%');
    if (failUnder) {
      stderr.writeln('Fallo por umbral mínimo de cobertura de JaCoCo (< $targetThreshold%).');
      exit(1);
    }
  }
}

class _FileCoverage {
  final String path;
  int linesFound = 0;
  int linesHit = 0;
  final Map<int, int> lines = {};

  _FileCoverage({required this.path});
}
