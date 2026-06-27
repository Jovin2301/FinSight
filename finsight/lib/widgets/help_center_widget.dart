import 'package:flutter/material.dart';

const Color tealDark = Color(0xFF2D7D7B);
const Color tealLight = Color(0xFFE6F4F3);
const Color helpBgColor = Color(0xFFEBF0F0);

/// Generic app bar shared across all topic screens
class TopicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const TopicAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: helpBgColor,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: tealDark, size: 18),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }
}

/// Teal icon badge used in header cards
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const IconBadge({
    super.key,
    required this.icon,
    this.bgColor = tealLight,
    this.iconColor = tealDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 26),
    );
  }
}

/// White card container used throughout
class HelpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const HelpCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Expandable FAQ row
class FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const FaqItem({super.key, required this.question, required this.answer});

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return HelpCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(
            widget.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          trailing: AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: tealDark),
          ),
          onExpansionChanged: (v) => setState(() => _open = v),
          children: [
            Text(
              widget.answer,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered step tile
class StepTile extends StatelessWidget {
  final int step;
  final String title;
  final String body;

  const StepTile({
    super.key,
    required this.step,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return HelpCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tealDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Teal bullet point row
class BulletTile extends StatelessWidget {
  final String text;
  const BulletTile({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(color: tealDark, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
        ),
      ],
    );
  }
}

/// Orange warning banner
class WarningBanner extends StatelessWidget {
  final String text;
  const WarningBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0E0),
        border: Border.all(color: const Color(0xFFF9D0B8), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE05C2A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF7A3010), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Teal info banner
class InfoBanner extends StatelessWidget {
  final String text;
  const InfoBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tealLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: tealDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: tealDark, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Section header label
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}