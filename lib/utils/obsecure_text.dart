// ignore_for_file: unused_local_variable

import 'dart:math';

String obscureString(String input) {
  final random = Random();
  final length = input.length;
  final obscuredChars = List.generate(length, (_) => '');

  // Determine the number of characters to obscure (approximately 10%)
  final int numToObscure = (length * 0.1).ceil();

  // Generate random indices to obscure
  final List<int> indices = [];
  while (indices.length < numToObscure) {
    int randomIndex = random.nextInt(length);
    if (!indices.contains(randomIndex)) {
      indices.add(randomIndex);
    }
  }

  // Replace characters at random indices with asterisks
  for (int i = 0; i < length; i++) {
    if (indices.contains(i)) {
      obscuredChars[i] = '*';
    } else {
      obscuredChars[i] = input[i];
    }
  }

  return obscuredChars.join();
}