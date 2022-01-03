import 'package:asterfox/main.dart';
import 'package:asterfox/screen/drawer.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const HomeScreenAppBar(),
      body: Container(),
      drawer: const SideMenu(),
    );
  }
}


class HomeScreenAppBar extends StatelessWidget with PreferredSizeWidget {
  const HomeScreenAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Asterfox"),
      actions: [
        IconButton(onPressed: () => openSearch(context), icon: const Icon(Icons.search))
      ],
      leading: IconButton(onPressed: () => DrawerController(context).openDrawer(), icon: const Icon(Icons.menu)),
    );
  }
  openSearch(BuildContext context) {
    if (themeNotifier.value != "dark") {

      themeNotifier.value = "dark";
    } else {
      themeNotifier.value = "light";
    // showSearch(context: context, delegate: delegate);
    }
  }
}

class DrawerController {
  DrawerController(this.context);
  final BuildContext context;

  void openDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (!scaffoldState.isDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openDrawer();
    }
  }

  void openEndDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (scaffoldState.isEndDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openEndDrawer();
    }
  }
}
