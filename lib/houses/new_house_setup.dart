import 'package:flutter/material.dart';
import '../config.dart';

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({super.key});

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  String houseName = 'New House';
  // Placeholder for storing user-designed floor plan elements
  List<Widget> floorPlanElements = [];

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
        backgroundColor: AppColors.colorScheme.primary,
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
          // Display floor plan elements
          ...floorPlanElements,
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add a new resizable, draggable room to the floor plan
                    setState(() {
                      floorPlanElements.add(RoomWidget(
                        key: UniqueKey(),
                        onDelete: () {
                          setState(() {
                            floorPlanElements.removeWhere((element) => element.key == widget.key);
                          });
                        },
                      ));
                    });
                  },
                  child: const Text('Add Room'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add a new resizable, draggable door to the floor plan
                    setState(() {
                      floorPlanElements.add(const DoorWidget());
                    });
                  },
                  child: const Text('Add Door'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add a new resizable, draggable wall to the floor plan
                    setState(() {
                      floorPlanElements.add(const WallWidget());
                    });
                  },
                  child: const Text('Add Wall'),
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

class RoomWidget extends StatefulWidget {
  final VoidCallback onDelete;

  const RoomWidget({super.key, required this.onDelete});

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  double width = 100;
  double height = 100;
  Offset position = const Offset(50, 100);
  bool isLocked = false;
  String roomName = 'Room';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleUpdate: !isLocked
            ? (details) {
                setState(() {
                  position = Offset(
                    position.dx + details.focalPointDelta.dx,
                    position.dy + details.focalPointDelta.dy,
                  );
                  width = (width * details.scale).clamp(50, 300);
                  height = (height * details.scale).clamp(50, 300);
                });
              }
            : null,
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(roomName == 'Room' ? 'Name Room' : 'Rename Room'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String newRoomName = roomName;
                          return AlertDialog(
                            title: Text(roomName == 'Room' ? 'Name Room' : 'Rename Room'),
                            content: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Room Name',
                              ),
                              onChanged: (value) {
                                newRoomName = value;
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
                                    roomName = newRoomName;
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
                  ListTile(
                    leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
                    title: Text(isLocked ? 'Unlock' : 'Lock in Place'),
                    onTap: () {
                      setState(() {
                        isLocked = !isLocked;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.aspect_ratio),
                    title: const Text('Resize Room'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          double newWidthFeet = width / 10;
                          double newHeightFeet = height / 10;
                          int newWidthInches = 0;
                          int newHeightInches = 0;
                          return AlertDialog(
                            title: const Text('Resize Room'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Width (ft)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    newWidthFeet = double.tryParse(value) ?? newWidthFeet;
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Width (in)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    newWidthInches = int.tryParse(value) ?? newWidthInches;
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Height (ft)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    newHeightFeet = double.tryParse(value) ?? newHeightFeet;
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Height (in)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    newHeightInches = int.tryParse(value) ?? newHeightInches;
                                  },
                                ),
                              ],
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
                                    width = (newWidthFeet * 10) + (newWidthInches / 12 * 10);
                                    height = (newHeightFeet * 10) + (newHeightInches / 12 * 10);
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
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Room'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Room'),
                            content: const Text('Are you sure you want to delete this room?'),
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
                                  setState(() {
                                    widget.onDelete();
                                  });
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.blueAccent,
          child: Center(
            child: Text(
              roomName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class DoorWidget extends StatefulWidget {
  const DoorWidget({super.key});

  @override
  _DoorWidgetState createState() => _DoorWidgetState();
}

class _DoorWidgetState extends State<DoorWidget> {
  double width = 50;
  double height = 10;
  Offset position = const Offset(150, 200);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            position = Offset(
              position.dx + details.focalPointDelta.dx,
              position.dy + details.focalPointDelta.dy,
            );
            width = (width * details.scale).clamp(25, 150);
          });
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.brown,
          child: Center(
            child: Text(
              '${(width / 10).toStringAsFixed(1)} ft',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class WallWidget extends StatefulWidget {
  const WallWidget({super.key});

  @override
  _WallWidgetState createState() => _WallWidgetState();
}

class _WallWidgetState extends State<WallWidget> {
  double width = 100;
  double height = 10;
  Offset position = const Offset(200, 300);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            position = Offset(
              position.dx + details.focalPointDelta.dx,
              position.dy + details.focalPointDelta.dy,
            );
            width = (width * details.scale).clamp(50, 300);
          });
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.black,
          child: Center(
            child: Text(
              '${(width / 10).toStringAsFixed(1)} ft',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}