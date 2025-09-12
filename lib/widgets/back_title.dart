import 'package:flutter/material.dart';

class BackTitle extends StatelessWidget {
  final String title;
  const BackTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.chevron_left,
            size: 25,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis
            ),
          ),
        ),
      ],
    );
  }
}
