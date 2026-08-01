import 'package:flutter/material.dart';

import '../screens/main_shell.dart';

class SideMenuButton extends StatelessWidget {
  const SideMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'القائمة',
      icon: const Icon(Icons.menu),
      onPressed: () =>
          context.findAncestorStateOfType<MainShellState>()?.openDrawer(),
    );
  }
}
