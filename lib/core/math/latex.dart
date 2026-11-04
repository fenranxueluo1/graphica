import '../utils/formatters.dart';
import 'expression.dart';

/// Converts the parsed expression tree into LaTeX for typeset display.
///
/// Returns null when the source cannot be parsed, so callers can fall back to
/// the raw input.
String? expressionToLatex(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;
  try {
    return _tex(MathEngine.parse(trimmed), 0);
  } on MathException {
    return null;
  }
}

/// Renders a full equation such as `x^2 + y^2 = 9`.
String? equationToLatex(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;
  final index = trimmed.indexOf('=');
  if (index < 0) return expressionToLatex(trimmed);
  final left = trimmed.substring(0, index).trim();
  final right = trimmed.substring(index + 1).trim();
  if (left.isEmpty || right.isEmpty) return null;
  try {
    return '${_tex(MathEngine.parse(left), 0)} = '
        '${_tex(MathEngine.parse(right), 0)}';
  } on MathException {
    return null;
  }
}

const _precSum = 1;
const _precProduct = 2;
const _precUnary = 3;
const _precPower = 4;
const _precAtom = 5;

int _precedence(Expr expr) {
  if (expr is BinaryExpr) {
    return switch (expr.operator) {
      '+' || '-' => _precSum,
      '*' || '/' || '%' => _precProduct,
      '^' => _precPower,
      _ => _precAtom,
    };
  }
  if (expr is UnaryExpr) return _precUnary;
  return _precAtom;
}

String _tex(Expr expr, int parentPrecedence) {
  final text = _render(expr);
  if (_precedence(expr) < parentPrecedence) {
    return '\\left($text\\right)';
  }
  return text;
}

String _render(Expr expr) {
  if (expr is NumberExpr) return _number(expr.value);
  if (expr is VariableExpr) return _variable(expr.name);
  if (expr is UnaryExpr) {
    final operand = _tex(expr.operand, _precUnary);
    return expr.operator == '-' ? '-$operand' : operand;
  }
  if (expr is BinaryExpr) return _binary(expr);
  if (expr is CallExpr) return _call(expr);
  return '';
}

String _binary(BinaryExpr expr) {
  final left = _tex(expr.left, _precProduct);
  final right = _tex(expr.right, _precProduct);
  switch (expr.operator) {
    case '+':
      return '${_tex(expr.left, _precSum)} + ${_tex(expr.right, _precSum)}';
    case '-':
      return '${_tex(expr.left, _precSum)} - '
          '${_tex(expr.right, _precSum + 1)}';
    case '/':
      return '\\frac{${_tex(expr.left, 0)}}{${_tex(expr.right, 0)}}';
    case '^':
      final base = _tex(expr.left, _precPower + 1);
      final exponent = _tex(expr.right, 0);
      return '{${_brace(base)}}^{${_brace(exponent)}}';
    case '%':
      return '${_tex(expr.left, _precProduct)} \\bmod '
          '${_tex(expr.right, _precProduct + 1)}';
    case '*':
      if (expr.left is NumberExpr &&
          (expr.right is VariableExpr || expr.right is CallExpr)) {
        return '$left$right';
      }
      if (expr.left is NumberExpr && expr.right is UnaryExpr) {
        return '$left \\cdot $right';
      }
      return '$left \\cdot $right';
  }
  return '$left \\cdot $right';
}

String _brace(String value) => value;

String _call(CallExpr call) {
  final args = call.arguments.map((argument) => _tex(argument, 0)).toList();
  final a = args.isNotEmpty ? args[0] : '';
  switch (call.name) {
    case 'sqrt':
      return '\\sqrt{$a}';
    case 'cbrt':
      return '\\sqrt[3]{$a}';
    case 'abs':
      return '\\left|$a\\right|';
    case 'exp':
      return 'e^{$a}';
    case 'ln':
      return '\\ln\\left($a\\right)';
    case 'log':
      if (args.length == 2) {
        return '\\log_{${args[1]}}\\left($a\\right)';
      }
      return '\\log\\left($a\\right)';
    case 'log2':
      return '\\log_{2}\\left($a\\right)';
    case 'log10':
      return '\\log_{10}\\left($a\\right)';
    case 'sin':
    case 'cos':
    case 'tan':
    case 'sec':
    case 'csc':
    case 'cot':
    case 'sinh':
    case 'cosh':
    case 'tanh':
    case 'asin':
    case 'acos':
    case 'atan':
    case 'asinh':
    case 'acosh':
    case 'atanh':
      return '\\operatorname{${call.name}}\\left($a\\right)';
    case 'min':
    case 'max':
      return '\\${call.name}\\left(${args.join(', ')}\\right)';
    case 'pow':
      if (args.length == 2) {
        return '{${_brace(args[0])}}^{${_brace(args[1])}}';
      }
      return '\\mathrm{pow}\\left(${args.join(', ')}\\right)';
    case 'fact':
      return '{${_brace(a)}}!';
    case 'gamma':
      return '\\Gamma\\left($a\\right)';
    case 'floor':
      return '\\left\\lfloor $a\\right\\rfloor';
    case 'ceil':
      return '\\left\\lceil $a\\right\\rceil';
    case 'mod':
      if (args.length == 2) {
        return '${args[0]} \\bmod ${args[1]}';
      }
      break;
    case 'atan2':
      return '\\operatorname{atan2}\\left(${args.join(', ')}\\right)';
  }
  return '\\mathrm{${_functionName(call.name)}}\\left(${args.join(', ')}\\right)';
}

String _functionName(String name) {
  return name.replaceAll('_', '');
}

String _variable(String name) {
  switch (name) {
    case 'pi':
      return '\\pi';
    case 'tau':
      return '\\tau';
    case 'phi':
      return '\\varphi';
    case 'theta':
      return '\\theta';
    case 'alpha':
      return '\\alpha';
    case 'beta':
      return '\\beta';
    case 'gamma':
      return '\\gamma';
    case 'e':
      return 'e';
  }
  if (name.length == 1) return name;
  return '\\mathrm{${name.replaceAll('_', '')}}';
}

String _number(double value) {
  final formatted = formatNumber(value, precision: 10);
  if (formatted.contains('e')) {
    final parts = formatted.split('e');
    final exponent = int.tryParse(parts[1]);
    if (exponent != null) {
      return '${parts[0]}\\times 10^{$exponent}';
    }
  }
  return formatted;
}
