import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web-only download link kept in the layout above the current route.
class WebPlayStoreFrame extends StatelessWidget {
  const WebPlayStoreFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Column(
      children: [
        Material(
          color: const Color(0xFF101B26),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (MediaQuery.sizeOf(context).width >= 520) ...[
                    const Text(
                      'Trav for Android',
                      style: TextStyle(color: Color(0xFFF3F6F6), fontSize: 14),
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
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
