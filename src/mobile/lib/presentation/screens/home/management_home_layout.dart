import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';

class ManagementHomeLayout extends StatelessWidget {
  const ManagementHomeLayout({
    super.key,
    required this.icon,
    required this.child,
  });
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final user = ApiClientProvider.session.currentUser!;
    final name = user.name?.trim();
    return ColoredBox(
      color: const Color(0xFFF6F7F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE1EBF8),
                    child: Icon(icon, color: AppColors.uctBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == null || name.isEmpty
                              ? '¡Hola!'
                              : '¡Hola, $name!',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.subtitle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
