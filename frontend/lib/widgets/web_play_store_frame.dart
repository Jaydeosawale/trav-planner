import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keeps the web download banner in the layout, above the current route.
/// Native Android builds retain their existing layout.
class WebPlayStoreFrame extends StatefulWidget {
  const WebPlayStoreFrame({super.key, required this.child});
  final Widget child;

  @override
  State<WebPlayStoreFrame> createState() => _WebPlayStoreFrameState();
}

class _WebPlayStoreFrameState extends State<WebPlayStoreFrame> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;
    final theme = Theme.of(context);
    return Column(
      children: [
        Visibility(
          visible: !_dismissed,
          child: Material(
            color: const Color(0xFF101B26),
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (MediaQuery.sizeOf(context).width >= 520) ...[
                      Text(
                        'Trav for Android',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Semantics(
                      button: true,
                      label: 'Get Trav on Google Play',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.jaydeo.travplanner',
                          ),
                          mode: LaunchMode.externalApplication,
                          webOnlyWindowName: '_blank',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/images/google_play_badge.png',
                            width: 135,
                            height: 40,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Dismiss Android download banner',
                      color: const Color(0xFFF3F6F6),
                      onPressed: () => setState(() => _dismissed = true),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
