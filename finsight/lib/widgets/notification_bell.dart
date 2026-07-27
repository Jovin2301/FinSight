import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final bool boxed;

  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: boxed
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: onTap,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 1,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
