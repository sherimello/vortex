import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:win32/win32.dart';

/// Reads AppsUseLightTheme directly from the Windows registry.
/// 1 = light mode → Brightness.light, 0 = dark mode → Brightness.dark.
/// Falls back to Brightness.light on any error.
Brightness getSystemBrightness() {
  final subKey =
      r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
          .toNativeUtf16();
  final valueName = 'AppsUseLightTheme'.toNativeUtf16();
  final data = calloc<Uint32>();
  final dataSize = calloc<Uint32>()..value = sizeOf<Uint32>();

  try {
    final result = RegGetValue(
      HKEY_CURRENT_USER,
      subKey,
      valueName,
      RRF_RT_REG_DWORD,
      nullptr,
      data,
      dataSize,
    );
    if (result == ERROR_SUCCESS) {
      return data.value == 1 ? Brightness.light : Brightness.dark;
    }
  } finally {
    free(subKey);
    free(valueName);
    free(data);
    free(dataSize);
  }
  return Brightness.light;
}
