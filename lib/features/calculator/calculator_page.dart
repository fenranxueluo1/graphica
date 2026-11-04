import 'package:flutter/material.dart';

import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/segmented_control.dart';
import 'basic_page.dart';
import 'scientific_page.dart';

enum CalculatorMode { scientific, basic }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  CalculatorMode _mode = CalculatorMode.scientific;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('calc.title'),
            subtitle: l10n.t('calc.subtitle'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedControl<CalculatorMode>(
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
              options: [
                SegmentOption(
                  value: CalculatorMode.scientific,
                  label: l10n.t('calc.scientific'),
                  icon: Icons.functions_rounded,
                ),
                SegmentOption(
                  value: CalculatorMode.basic,
                  label: l10n.t('calc.basic'),
                  icon: Icons.calculate_outlined,
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _mode.index,
              children: const [ScientificCalculator(), BasicCalculator()],
            ),
          ),
        ],
      ),
    );
  }
}
