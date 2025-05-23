import 'package:flutter/painting.dart';

/// GitHub Dark theme based on GitHub's dark mode syntax highlighting
final Map<String, TextStyle> githubDarkTheme = {
  'root': const TextStyle(
    backgroundColor: Color(0xFF0d1117),
    color: Color(0xFFc9d1d9),
  ),
  'comment':
      const TextStyle(color: Color(0xFF8b949e), fontStyle: FontStyle.italic),
  'quote':
      const TextStyle(color: Color(0xFF8b949e), fontStyle: FontStyle.italic),
  'keyword': const TextStyle(color: Color(0xFFff7b72)),
  'selector-tag': const TextStyle(color: Color(0xFFff7b72)),
  'literal': const TextStyle(color: Color(0xFFff7b72)),
  'name': const TextStyle(color: Color(0xFFff7b72)),
  'type': const TextStyle(color: Color(0xFFff7b72)),
  'section':
      const TextStyle(color: Color(0xFFd2a8ff), fontWeight: FontWeight.bold),
  'title': const TextStyle(color: Color(0xFFd2a8ff)),
  'tag': const TextStyle(color: Color(0xFFd2a8ff)),
  'attr': const TextStyle(color: Color(0xFf79c0ff)),
  'number': const TextStyle(color: Color(0xFFf8b86d)),
  'string': const TextStyle(color: Color(0xFFa5d6ff)),
  'doctag': const TextStyle(color: Color(0xFFa5d6ff)),
  'built_in': const TextStyle(color: Color(0xFFd2a8ff)),
  'variable': const TextStyle(color: Color(0xFFd2a8ff)),
  'template-variable': const TextStyle(color: Color(0xFFd2a8ff)),
  'function': const TextStyle(color: Color(0xFFd2a8ff)),
  'attribute': const TextStyle(color: Color(0xFF79c0ff)),
  'regexp': const TextStyle(color: Color(0xFFa5d6ff)),
  'symbol': const TextStyle(color: Color(0xFFd2a8ff)),
  'link': const TextStyle(
      color: Color(0xFFa5d6ff), decoration: TextDecoration.underline),
  'meta': const TextStyle(color: Color(0xFFe3b341)),
  'deletion': const TextStyle(
      color: Color(0xFFffa198), backgroundColor: Color(0xFF5d0000)),
  'addition': const TextStyle(
      color: Color(0xFF9ec8a1), backgroundColor: Color(0xFF033a16)),
  'subst': const TextStyle(color: Color(0xFFc9d1d9)),
  'strong': const TextStyle(fontWeight: FontWeight.bold),
  'emphasis': const TextStyle(fontStyle: FontStyle.italic),
};
