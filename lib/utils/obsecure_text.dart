// ignore_for_file: unused_local_variable

import 'dart:math';

String obscureString(String input) {
  final random = Random();
  final charsToObfuscate = (input.length * 0.1).ceil();
  final indexes = List.generate(input.length, (index) => index);
  indexes.shuffle();

  final obscuredIndexes = indexes.take(charsToObfuscate);

  final obscuredChars = input.runes
      .map((rune) => obscuredIndexes.contains(input.indexOf(String.fromCharCode(rune))) ? '*' : String.fromCharCode(rune))
      .toList();

  return obscuredChars.join("");
}