import 'package:flutter/material.dart';

class SemsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? titleAction;
  final String? title;

  const SemsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.title,
    this.titleAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  titleAction ?? const SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
