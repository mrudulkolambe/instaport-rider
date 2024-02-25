import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

final MaskTextInputFormatter phoneNumberMask = MaskTextInputFormatter(
  mask: '+91 ##### #####',
  filter: {"#": RegExp(r'[0-9]')},
);

final MaskTextInputFormatter ageMask = MaskTextInputFormatter(
  mask: '##',
  filter: {"#": RegExp(r'[0-9]')},
);

final MaskTextInputFormatter aadharcardMask = MaskTextInputFormatter(
  mask: '#### #### ####',
  filter: {"#": RegExp(r'[0-9]')},
);

final MaskTextInputFormatter pancardMask = MaskTextInputFormatter(
  mask: '#####****#',
  filter: {"#": RegExp(r'[A-Z]'), "*": RegExp(r'[0-9]')},
);
final MaskTextInputFormatter ifscMask = MaskTextInputFormatter(
  mask: '####0******',
  filter: {"#": RegExp(r'[A-Z]'), "*": RegExp(r'[0-9]')},
);
