import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadUiFonts() async {
  var root = File(Platform.resolvedExecutable).parent;
  while (!Directory('${root.path}/bin/cache/artifacts/material_fonts')
      .existsSync()) {
    final parent = root.parent;
    if (parent.path == root.path) {
      throw StateError('El SDK de Flutter no contiene las fuentes de prueba.');
    }
    root = parent;
  }
  for (final (family, file) in [
    ('Roboto', 'Roboto-Regular.ttf'),
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
  ]) {
    final font = File('${root.path}/bin/cache/artifacts/material_fonts/$file');
    final loader = FontLoader(family)
      ..addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  }
}
