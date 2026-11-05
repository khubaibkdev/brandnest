import 'package:flutter_riverpod/legacy.dart';

/// Which of the five destinations is showing. Hoisted out of `HomeShell`'s own
/// state (US-6) so a tapped push notification — or a shortcut action from
/// inside a tab, like the home top bar's search icon — can switch tabs from
/// outside the widget tree, not just the bottom nav bar.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
