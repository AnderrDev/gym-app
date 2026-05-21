import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Renderer mínimo de texto enriquecido para `instructions` y `tips`.
///
/// Sintaxis soportada (subset deliberadamente chico para evitar añadir
/// `flutter_markdown` como dependencia):
///
/// - Párrafos separados por una línea en blanco.
/// - Bullets: líneas que empiezan con `- ` o `* `. Se renderizan en una
///   columna con un disco al inicio y wrapping del texto.
///
/// Cualquier otra "marca" markdown (bold, links, headers) se respeta como
/// texto literal — si en algún momento necesitamos más, sumamos la lib.
class ExerciseMarkdownLite extends StatelessWidget {
  const ExerciseMarkdownLite(this.text, {super.key, this.accent});

  final String text;

  /// Color del marker de los bullets. Default: `context.colors.primary`.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final bulletColor = accent ?? context.colors.primary;
    final paragraphs = _splitParagraphs(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.md),
          _renderBlock(context, paragraphs[i], bulletColor),
        ],
      ],
    );
  }

  static List<String> _splitParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    return normalized
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  Widget _renderBlock(BuildContext context, String block, Color bulletColor) {
    final lines = block.split('\n');
    final isBulletList = lines.every(
      (l) => l.trim().startsWith('- ') || l.trim().startsWith('* '),
    );
    if (isBulletList) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _BulletRow(
                text: line.trim().substring(2).trim(),
                color: bulletColor,
              ),
            ),
        ],
      );
    }
    return Text(
      block.replaceAll('\n', ' '),
      style: context.text.bodyMedium?.copyWith(
        color: context.colors.textPrimary,
        height: 1.45,
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
