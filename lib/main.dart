import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/controller_main.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MainController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('USSD Launcher Demo'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Single Session'),
                Tab(text: 'Multi Session'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              SingleSessionTab(),
              MultiSessionTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleSessionTab extends StatefulWidget {
  const SingleSessionTab({Key? key}) : super(key: key);

  @override
  _SingleSessionTabState createState() => _SingleSessionTabState();
}

class _SingleSessionTabState extends State<SingleSessionTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<MainController>(context, listen: false).loadSimCards();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Selected SIM ID: ${controller.selectedSimId ?? "None"}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: controller.selectedSimId,
                hint: const Text('Select SIM'),
                items: controller.simCards.map((sim) {
                  return DropdownMenuItem<int>(
                    value: sim['subscriptionId'],
                    child: Text("${sim['displayName']} (${sim['carrierName']})"),
                  );
                }).toList(),
                onChanged: (value) => controller.setSelectedSimId(value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter USSD Code',
                  hintText: 'e.g. *880#',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.sendUssdRequest(_controller.text),
                child: const Text('Launch Single Session USSD'),
              ),
              const SizedBox(height: 16),
              const Text('USSD Response:'),
              Text(controller.ussdResponse),
            ],
          ),
        );
      },
    );
  }
}

class MultiSessionTab extends StatefulWidget {
  const MultiSessionTab({Key? key}) : super(key: key);

  @override
  _MultiSessionTabState createState() => _MultiSessionTabState();
}

class _MultiSessionTabState extends State<MultiSessionTab> {
  final TextEditingController _ussdController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<MainController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Selected SIM ID: ${controller.selectedSimId ?? "None"}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButton<int>(
                  value: controller.selectedSimId,
                  hint: const Text('Select SIM'),
                  items: controller.simCards.map((sim) {
                    return DropdownMenuItem<int>(
                      value: sim['subscriptionId'],
                      child: Text("${sim['displayName']} (${sim['carrierName']})"),
                    );
                  }).toList(),
                  onChanged: (value) => controller.setSelectedSimId(value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ussdController,
                  decoration: const InputDecoration(labelText: 'Enter USSD Code'),
                ),
                ..._optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: 'Option ${entry.key + 1}'),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _optionControllers.add(TextEditingController());
                        });
                      },
                      child: const Text('Add Option'),
                    ),
                    ElevatedButton(
                      onPressed: _optionControllers.isNotEmpty
                          ? () {
                              setState(() {
                                _optionControllers.last.dispose();
                                _optionControllers.removeLast();
                              });
                            }
                          : null,
                      child: const Text('Remove Option'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () {
                          controller.launchMultiSessionUssd(
                            _ussdController.text,
                            _optionControllers.map((c) => c.text).toList(),
                          );
                        },
                  child: const Text('Launch Multi-Session USSD'),
                ),
                const SizedBox(height: 16),
                const Text('USSD Response:'),
                Text(controller.dialogText),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _ussdController.dispose();
    super.dispose();
  }
}