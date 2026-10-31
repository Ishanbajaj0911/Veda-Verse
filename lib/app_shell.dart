import 'package:flutter/material.dart';
import 'package:veda_verse/screens/app_home_screen.dart';
import 'package:veda_verse/screens/buddy_screen.dart';
import 'package:veda_verse/screens/dosha_screen.dart';
import 'package:veda_verse/screens/learn_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/screens/yoga_screen.dart';
import 'package:veda_verse/theme/vv.dart';

/// Tab indices used across the app.
class Tabs {
  static const home = 0, learn = 1, dosha = 2, yoga = 3, vaidya = 4, buddy = 5;
}

/// Bottom-nav shell: Home · Learn · Dosha · Yoga · Vaidya, plus the Ayu Buddy FAB.
class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = Tabs.home});

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int index = widget.initialIndex;

  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      AppHomeScreen(onGo: go),
      const LearnScreen(),
      const DoshaScreen(),
      const YogaScreen(),
      const VaidyaScreen(),
      const BuddyScreen(),
    ];
    return Scaffold(
      body: VvFrame(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: index, children: pages)),
            VvNavBar(active: index, onTap: go),
          ],
        ),
      ),
    );
  }
}

class VvNavBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onTap;
  const VvNavBar({super.key, required this.active, required this.onTap});

  static const _items = [
    (Icons.home_outlined, 'Home', Vv.deep),
    (Icons.menu_book_outlined, 'Learn', Vv.plum),
    (Icons.contrast_rounded, 'Dosha', Vv.brown),
    (Icons.self_improvement_rounded, 'Yoga', Vv.rust),
    (Icons.medical_services_outlined, 'Vaidya', Vv.green),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 84 + bottomInset,
          padding: EdgeInsets.fromLTRB(6, 0, 6, 12 + bottomInset),
          decoration: const BoxDecoration(
            color: Vv.surface,
            border: Border(top: BorderSide(color: Vv.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: VvTap(
                    onTap: () => onTap(i),
                    child: SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(_items[i].$1, size: 22, color: active == i ? _items[i].$3 : Vv.muted),
                          const SizedBox(height: 4),
                          Text(
                            _items[i].$2,
                            style: Vv.sans(12, weight: FontWeight.w700, color: active == i ? _items[i].$3 : Vv.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (active != Tabs.buddy)
          Positioned(
            right: 16,
            top: -76,
            child: VvTap(
              onTap: () => onTap(Tabs.buddy),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Vv.blue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Vv.bg, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x593A4F8C), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Vv.surface, size: 26),
              ),
            ),
          ),
      ],
    );
  }
}
