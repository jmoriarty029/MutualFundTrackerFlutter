import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('funds');
  runApp(MyApp());
}

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mutual Fund Tracker',
            theme: ThemeData(
              brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
              colorSchemeSeed: Colors.blueAccent,
              useMaterial3: true,
            ),
            home: HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Box fundBox = Hive.box('funds');

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Fund Tracker'),
        actions: [
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => theme.toggleTheme(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFundDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: fundBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No funds added yet."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final fund = box.getAt(index);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(fund['name']),
                  subtitle: Text("NAV: ${fund['nav']} | Units: ${fund['units']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => box.deleteAt(index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFundDialog(BuildContext context) {
    final nameController = TextEditingController();
    final navController = TextEditingController();
    final unitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Fund"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Fund Name')),
            TextField(controller: navController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'NAV')),
            TextField(controller: unitsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Units')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final nav = double.tryParse(navController.text.trim()) ?? 0;
              final units = double.tryParse(unitsController.text.trim()) ?? 0;

              if (name.isNotEmpty && nav > 0 && units > 0) {
                Hive.box('funds').add({'name': name, 'nav': nav, 'units': units});
              }

              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
