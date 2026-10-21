import 'package:flutter/material.dart';

/// Customer-facing design only. Staff screens and capture retain their themes.
abstract final class EventDesign {
  static const red = Color(0xff740000);
  static const white = Color(0xfffffbfb);
  static const background = 'assets/event/app_background.png';
  static const display = 'RubikMonoOne';
  static const body = 'SpaceMono';

  static ThemeData theme(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: red,
      primary: red,
      onPrimary: white,
      surface: white,
      onSurface: red,
    ),
    textTheme: Theme.of(
      context,
    ).textTheme.apply(fontFamily: body, bodyColor: red, displayColor: red),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: red),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(white),
      thickness: WidgetStateProperty.all(7),
      radius: const Radius.circular(8),
    ),
  );
}

/// A complete kiosk composition, fitted on both axes without page scrolling.
/// The physical monitor is 16:10; the fixed design space also remains usable in
/// smaller windows. Individual choice lists own their bounded scrolling.
class EventCanvas extends StatelessWidget {
  const EventCanvas({
    super.key,
    required this.child,
    this.background = EventDesign.background,
  });
  final Widget child;
  final String background;

  @override
  Widget build(BuildContext context) => Theme(
    data: EventDesign.theme(context),
    child: Scaffold(
      backgroundColor: EventDesign.red,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1280,
            height: 800,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  background,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EventPage extends StatelessWidget {
  const EventPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => EventCanvas(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(44, 30, 44, 30),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: EventBackButton(onPressed: onBack),
                ),
                EventPlaque(title: title, subtitle: subtitle),
                if (trailing != null)
                  Align(alignment: Alignment.centerRight, child: trailing),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class EventBackButton extends StatelessWidget {
  const EventBackButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: EventDesign.red,
      backgroundColor: EventDesign.white,
      disabledBackgroundColor: EventDesign.white.withValues(alpha: .55),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    icon: const Icon(Icons.chevron_left_rounded, size: 34),
  );
}

class EventPlaque extends StatelessWidget {
  const EventPlaque({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: 460,
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    decoration: BoxDecoration(
      color: EventDesign.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: EventDesign.red, width: 4),
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/event/clickclick_logo_red.png',
          width: 55,
          height: 55,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: EventDesign.display,
                  fontSize: 25,
                  color: EventDesign.red,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: EventDesign.body,
                    fontSize: 10,
                    height: 1.4,
                    color: EventDesign.red,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class EventButton extends StatelessWidget {
  const EventButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 62,
    this.glossy = false,
    this.subtitle,
    this.display = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool glossy;
  final bool display;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .55 : 1,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(glossy ? height / 2 : 18),
        color: EventDesign.white,
        gradient: glossy
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xfffbfbfb),
                  Color(0xffeeeeee),
                  Color(0xffdedede),
                  Color(0xffc7c7c7),
                ],
                stops: [0, .35, .8, 1],
              )
            : null,
        border: glossy
            ? Border.all(color: const Color(0xffdedede), width: 3)
            : null,
        boxShadow: glossy
            ? const [
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 8,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(glossy ? height / 2 : 18),
          focusColor: EventDesign.red.withValues(alpha: .18),
          hoverColor: EventDesign.red.withValues(alpha: .06),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: EventDesign.red, size: 24),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: display
                                ? EventDesign.display
                                : EventDesign.body,
                            color: EventDesign.red,
                            fontWeight: FontWeight.bold,
                            fontSize: display
                                ? 22
                                : height < 56
                                ? 15
                                : 19,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: EventDesign.body,
                        fontSize: 16,
                        color: EventDesign.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class EventSection extends StatelessWidget {
  const EventSection({
    super.key,
    required this.title,
    required this.child,
    this.figure,
    this.figureWidth = 140,
    this.figureAtStart = false,
  });
  final String title;
  final Widget child;
  final String? figure;
  final double figureWidth;
  final bool figureAtStart;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 70,
        child: Stack(
          children: [
            Positioned(
              left: figureAtStart ? figureWidth + 10 : 0,
              bottom: 14,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: EventDesign.body,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: EventDesign.white,
                ),
              ),
            ),
            if (figure != null)
              Positioned(
                left: figureAtStart ? 4 : null,
                right: figureAtStart ? null : 18,
                bottom: 0,
                child: Image.asset(
                  figure!,
                  width: figureWidth,
                  height: 80,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
          ],
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class EventPanel extends StatelessWidget {
  const EventPanel({
    super.key,
    required this.child,
    this.light = false,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final bool light;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: light ? EventDesign.white : EventDesign.red,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: EventDesign.white, width: 2),
    ),
    child: child,
  );
}

class EventChoice extends StatelessWidget {
  const EventChoice({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.leading,
  });
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final color = selected ? EventDesign.red : EventDesign.white;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? EventDesign.white : EventDesign.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: EventDesign.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                  size: 25,
                ),
                const SizedBox(width: 16),
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: EventDesign.body,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: EventDesign.body,
                            fontSize: 11,
                            height: 1.3,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EventMessage extends StatelessWidget {
  const EventMessage({
    super.key,
    required this.message,
    this.action,
    this.loading = false,
  });
  final String message;
  final Widget? action;
  final bool loading;
  @override
  Widget build(BuildContext context) => Center(
    child: EventPanel(
      light: true,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: EventDesign.red),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}
