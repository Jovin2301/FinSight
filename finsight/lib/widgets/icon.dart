import 'package:flutter/material.dart';

class IconDropdownMenu extends StatefulWidget {
  const IconDropdownMenu({super.key});

  @override
  State<IconDropdownMenu> createState() => _IconDropdownMenuState();
}

class _IconDropdownMenuState extends State<IconDropdownMenu> {
  // Track the selected value
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: selectedValue,
      label: const Text('Select Category'),
      onSelected: (String? value) {
        setState(() {
          selectedValue = value;
        });
      },
      // Generate the list items with text and icons
      dropdownMenuEntries: const [
        DropdownMenuEntry(
          value: 'home',
          label: 'Home',
          leadingIcon: Icon(Icons.home),
        ),
        DropdownMenuEntry(
          value: 'settings',
          label: 'Settings',
          leadingIcon: Icon(Icons.settings),
        ),
        DropdownMenuEntry(
          value: 'profile',
          label: 'Profile',
          leadingIcon: Icon(Icons.person),
        ),
      ],
    );
  }
}
