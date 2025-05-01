import 'package:flutter/material.dart';
import '../config.dart';
import 'manage_users_logic.dart';
import 'package:provider/provider.dart';
import '../theme_color_notifier.dart';

class EditUserPage extends StatefulWidget {
  final String id;
  final String name;
  final String email;
  final String house;
  final String userType;

  const EditUserPage({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.house,
    required this.userType,
  });

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late String userType;
  late TextEditingController nameController;
  late TextEditingController emailController;
  String? selectedHouseId;
  bool isSaved = false;
  bool hasChanges = false;
  List<Map<String, String>> houseOptions = [];

  late ManageUsersLogic logic;

  @override
  void initState() {
    super.initState();
    logic = ManageUsersLogic(
      context: context,
      updateUsers: (_) {},
      updateSelectedIndex: (_) {},
    );

    userType = widget.userType;
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);

    _loadHouseOptions();
  }

  /// Load available houses
  Future<void> _loadHouseOptions() async {
    final houses = await logic.loadHouseOptions();
    setState(() {
      houseOptions = houses;
      final matchedHouse = houseOptions.firstWhere(
        (house) => house['name'] == widget.house,
        orElse: () => {'id': '', 'name': ''},
      );
      selectedHouseId = matchedHouse['id']!.isNotEmpty ? matchedHouse['id'] : null;
    });
  }

  /// Track changes to form fields
  void trackChanges() {
    setState(() {
      hasChanges = userType != widget.userType ||
          nameController.text != widget.name ||
          emailController.text != widget.email ||
          selectedHouseId != widget.house;
    });
  }

  /// Validate and save user changes
  void _saveUser() {
    logic.validateAndUpdateUser(
      id: widget.id,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      userType: userType,
      selectedHouseId: selectedHouseId,
      onSuccess: () {
        setState(() {
          isSaved = true;
          hasChanges = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!isSaved && hasChanges) {
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Unsaved Changes'),
                    content: const Text('Are you sure? Your current changes will be lost.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              ) ??
              false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit User'),
          backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRadioButtons(),
              const SizedBox(height: 20),
              _buildTextField(nameController, 'Name'),
              const SizedBox(height: 20),
              _buildTextField(emailController, 'Email (must be gmail.com)', TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildHouseDropdown(),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: hasChanges ? _saveUser : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User Type', style: TextStyle(fontSize: 18)),
        Row(
          children: [
            _buildRadioButton('Admin'),
            _buildRadioButton('User'),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioButton(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: userType,
          onChanged: (String? newValue) {
            setState(() {
              userType = newValue!;
              trackChanges();
            });
          },
        ),
        Text(value),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      onChanged: (value) => trackChanges(),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: type,
    );
  }

  Widget _buildHouseDropdown() {
    return DropdownButton<String>(
      value: selectedHouseId,
      hint: const Text('Select House'),
      items: houseOptions.map((house) {
        return DropdownMenuItem<String>(
          value: house['id'],
          child: Text(house['name']!),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedHouseId = newValue;
          trackChanges();
        });
      },
    );
  }
}
