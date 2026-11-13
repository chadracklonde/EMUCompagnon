import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Building blocks of the "clair et aéré" look: section titles, bordered
/// cards and tappable rows. Shared by the home and "Plus" screens so both
/// stay visually identical.

const double kCardRadius = 18;

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A white (or dark-surface) rounded card with a hairline border.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
      side: BorderSide(color: palette.border),
    );
    return Material(
      color: palette.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      // Announced as a button by screen readers when the whole card is tappable.
      child: onTap == null
          ? child
          : Semantics(button: true, child: InkWell(onTap: onTap, child: child)),
    );
  }
}

/// Square-ish tile: icon on top, title and subtitle at the bottom.
class AppTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleDot;
  final VoidCallback onTap;

  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: palette.accent, size: 24),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitleDot != null) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: subtitleDot,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: palette.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable line: tinted icon, title, optional subtitle and progress,
/// chevron. Use alone inside an [AppCard], or stacked in an [AppRowGroup].
class AppRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// 0..1 — draws a thin progress bar under the subtitle when set.
  final double? progress;

  /// Icon at the end of the line; a chevron unless told otherwise (for
  /// example "open in browser" for external links).
  final IconData trailingIcon;
  final VoidCallback onTap;

  const AppRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.progress,
    this.trailingIcon = Icons.chevron_right,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: palette.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: palette.field,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                trailingIcon,
                color: palette.muted,
                size: trailingIcon == Icons.chevron_right ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Several [AppRow]s in a single card, separated by hairlines.
class AppRowGroup extends StatelessWidget {
  final List<AppRow> rows;
  const AppRowGroup({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 64, color: palette.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// A quiet explanatory note (context, disclaimer) set apart from content.
class InfoNote extends StatelessWidget {
  final String text;
  final double lineHeightScale;
  const InfoNote(this.text, {super.key, this.lineHeightScale = 1});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5 * lineHeightScale,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon + message for "nothing here yet" and "no results".
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: palette.accent, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.4, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small tinted pill holding a short label such as a hymn number.
class NumberBadge extends StatelessWidget {
  final String label;
  const NumberBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.accent),
      ),
    );
  }
}

/// A plain list line for long, lazily built lists (search results,
/// dictionary terms): bold title, muted excerpt, optional leading widget.
class ResultRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int subtitleMaxLines;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool accentTitle;
  final VoidCallback onTap;

  const ResultRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleMaxLines = 2,
    this.leading,
    this.trailing,
    this.selected = false,
    this.accentTitle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? palette.accentSoft : Colors.transparent,
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: accentTitle ? palette.accent : scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: accentTitle ? scheme.onSurface : palette.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 4), trailing!],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Search field meant for an [AppBar] title: autofocused, with a clear
/// button once there is text.
class AppBarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const AppBarSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
