// new_house_setup.dart
import 'package:flutter/material.dart';
import 'room_widget.dart';  // Import RoomWidget from room_widget.dart

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({super.key});

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  String houseName = 'New House';
  List<RoomWidget> floorPlanElements = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(houseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String newHouseName = houseName;
                  return AlertDialog(
                    title: const Text('Name House'),
                    content: TextField(
                      decoration: const InputDecoration(
                        labelText: 'House Name',
                      ),
                      onChanged: (value) {
                        newHouseName = value;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            houseName = newHouseName;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Leave Setup'),
                  content: const Text('Are you sure you want to leave the setup? Any unsaved changes will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          ...floorPlanElements,
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      floorPlanElements.add(RoomWidget(
                        key: UniqueKey(),
                        onDelete: (key) {
                          setState(() {
                            floorPlanElements.removeWhere((element) => element.key == key);
                          });
                        },
                      ));
                    });
                  },
                  child: const Text('Add Room'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                'Scale: 1 sq unit = 1 ft',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
