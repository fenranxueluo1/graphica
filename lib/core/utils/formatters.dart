/// Number formatting helpers shared by calculators and graph labels.
String formatNumber(double value, {int precision = 10}) {
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
  if (value == 0) return '0';

  final magnitude = value.abs();
  if (magnitude >= 1e12 || magnitude < 1e-9) {
    final text = value.toStringAsExponential(6);
    return _trimExponent(text);
  }

  final text = value.toStringAsPrecision(precision);
  if (!text.contains('e') && !text.contains('E')) {
    return _trimZeros(text);
  }
  return _trimExponent(text);
}

String _trimZeros(String text) {
  if (!text.contains('.')) return text;
  var result = text;
  while (result.contains('.') && result.endsWith('0')) {
    result = result.substring(0, result.length - 1);
  }
  if (result.endsWith('.')) {
    result = result.substring(0, result.length - 1);
  }
  if (result == '-0') return '0';
  return result;
}

String _trimExponent(String text) {
  final parts = text.split('e');
  if (parts.length != 2) return _trimZeros(text);
  final mantissa = _trimZeros(parts[0]);
  final exponent = int.tryParse(parts[1]);
  if (exponent == null) return text;
  return '${mantissa}e${exponent >= 0 ? '+' : ''}$exponent';
}

/// A "nice" grid step: 1, 2, 5 multiplied by a power of ten.
double niceStep(double rawStep) {
  if (rawStep <= 0 || !rawStep.isFinite) return 1;
  final exponent = (rawStep.abs()).log10.floor();
  final power = _pow10(exponent);
  final fraction = rawStep / power;
  double nice;
  if (fraction <= 1) {
    nice = 1;
  } else if (fraction <= 2) {
    nice = 2;
  } else if (fraction <= 5) {
    nice = 5;
  } else {
    nice = 10;
  }
  return nice * power;
}

double _pow10(int exponent) {
  var result = 1.0;
  if (exponent >= 0) {
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
  } else {
    for (var i = 0; i < -exponent; i++) {
      result /= 10;
    }
  }
  return result;
}

extension on double {
  double get log10 => _log10(this);
}

double _log10(double value) {
  // Dart exposes log() through dart:math; this helper avoids extra imports at
  // this call site while keeping precision for the range we care about.
  var result = 0.0;
  var v = value;
  while (v >= 10) {
    v /= 10;
    result += 1;
  }
  while (v < 1) {
    v *= 10;
    result -= 1;
  }
  return result;
}
