import 'package:flutter/material.dart';
import 'dart:math' as math;

enum RoomShape { rectangle, lShape }

class RoomWidget extends StatefulWidget {
  final Function(Key) onDelete;
  final Function(Offset, double, double) onRoomMoved; // Updated to pass position, width, and height
  final double initialWidth;  // Added for initialization
  final double initialHeight; // Added for initialization

  const RoomWidget({
    super.key,
    required this.onDelete,
    required this.onRoomMoved,
    required this.initialWidth,
    required this.initialHeight,
  });

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  late double width;
  late double height;
  Offset position = const Offset(50, 100);
  Offset? dragStartOffset; // Store the initial offset when dragging starts
  bool isLocked = false;
  double rotationAngle = 0.0;
  RoomShape shape = RoomShape.rectangle;
  double lSectionWidth = 75;
  double lSectionHeight = 50;
  String roomName = 'Room';

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lSectionWidthController = TextEditingController();
  final TextEditingController _lSectionHeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize width and height with values from the parent widget
    width = widget.initialWidth;
    height = widget.initialHeight;
    _widthController.text = (width / 10).toString();
    _heightController.text = (height / 10).toString();
    _lSectionWidthController.text = (lSectionWidth / 10).toString();
    _lSectionHeightController.text = (lSectionHeight / 10).toString();
  }

  void _showResizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resize Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildValidatedInputField(
                controller: _widthController,
                labelText: 'Width (ft)',
                minValue: 1,
                maxValue: 100,
              ),
              _buildValidatedInputField(
                controller: _heightController,
                labelText: 'Height (ft)',
                minValue: 1,
                maxValue: 100,
              ),
              if (shape == RoomShape.lShape) ...[
                _buildValidatedInputField(
                  controller: _lSectionWidthController,
                  labelText: 'L-Section Width (ft)',
                  minValue: 1,
                  maxValue: 100,
                ),
                _buildValidatedInputField(
                  controller: _lSectionHeightController,
                  labelText: 'L-Section Height (ft)',
                  minValue: 1,
                  maxValue: 100,
                ),
              ],
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
                if (_validateInputs()) {
                  setState(() {
                    width = double.parse(_widthController.text) * 10;
                    height = double.parse(_heightController.text) * 10;
                    if (shape == RoomShape.lShape) {
                      lSectionWidth = double.parse(_lSectionWidthController.text) * 10;
                      lSectionHeight = double.parse(_lSectionHeightController.text) * 10;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildValidatedInputField({
    required TextEditingController controller,
    required String labelText,
    required double minValue,
    required double maxValue,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: _validateField(controller.text, minValue, maxValue),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {}); // Trigger re-build to update errorText if needed
      },
    );
  }

  String? _validateField(String value, double minValue, double maxValue) {
    final double? parsedValue = double.tryParse(value);
    if (parsedValue == null) {
      return 'Please enter a valid number';
    } else if (parsedValue < minValue) {
      return 'Value must be at least $minValue';
    } else if (parsedValue > maxValue) {
      return 'Value must be at most $maxValue';
    }
    return null;
  }

  bool _validateInputs() {
    return _validateField(_widthController.text, 1, 100) == null &&
           _validateField(_heightController.text, 1, 100) == null &&
           (shape != RoomShape.lShape ||
             (_validateField(_lSectionWidthController.text, 1, 100) == null &&
              _validateField(_lSectionHeightController.text, 1, 100) == null));
  }

  void _rotateBy90Degrees() {
    setState(() {
      rotationAngle = (rotationAngle + math.pi / 2) % (2 * math.pi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          if (!isLocked) {
            // Set dragStartOffset to the difference between the initial global position and the current widget position
            dragStartOffset = details.globalPosition - position;
          }
        },
        onPanUpdate: (details) {
          if (!isLocked) {
            setState(() {
              // Use dragStartOffset to calculate the new position accurately, avoiding jumps
              position = details.globalPosition - dragStartOffset!;
            });
          }
        },

        onPanEnd: (details) {
          if (!isLocked) {
            widget.onRoomMoved(position, width, height); // Pass position, width, and height
          }
          dragStartOffset = null;
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Change Room Shape'),
                    onTap: () {
                      setState(() {
                        shape = shape == RoomShape.rectangle
                            ? RoomShape.lShape
                            : RoomShape.rectangle;
                        if (shape == RoomShape.lShape) {
                          width = 120;
                          height = 100;
                          lSectionWidth = 60;
                          lSectionHeight = 40;
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.aspect_ratio),
                    title: const Text('Resize Room'),
                    onTap: () {
                      Navigator.pop(context);
                      _showResizeDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rotate_right),
                    title: const Text('Rotate Room'),
                    onTap: () {
                      Navigator.pop(context);
                      _rotateBy90Degrees();
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
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Room'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete(widget.key!);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Transform.rotate(
          angle: rotationAngle,
          child: _buildRoomShape(),
        ),
      ),
    );
  }

  Widget _buildRoomShape() {
    if (shape == RoomShape.rectangle) {
      return Container(
        width: width,
        height: height,
        color: Colors.blueAccent,
        child: _buildRoomContent(),
      );
    } else if (shape == RoomShape.lShape) {
      return ClipPath(
        clipper: LShapeClipper(width, height, lSectionWidth, lSectionHeight),
        child: Container(
          width: width,
          height: height,
          color: Colors.blueAccent,
          child: _buildRoomContent(),
        ),
      );
    }
    return Container();
  }

  Widget _buildRoomContent() {
    double fontSize = math.min(width, height) / 10;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Transform.rotate(
          angle: -rotationAngle,
          child: Text(
            '$roomName\n${(width / 10).toStringAsFixed(1)} ft x ${(height / 10).toStringAsFixed(1)} ft',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class LShapeClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final double lSectionWidth;
  final double lSectionHeight;

  LShapeClipper(this.width, this.height, this.lSectionWidth, this.lSectionHeight);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(width, 0);
    path.lineTo(width, height - lSectionHeight);
    path.lineTo(width - lSectionWidth, height - lSectionHeight);
    path.lineTo(width - lSectionWidth, height);
    path.lineTo(0, height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
