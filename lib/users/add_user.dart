import 'package:flutter/material.dart';
import '../config.dart';
import 'add_user_logic.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String userType = 'User'; // Default user type
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? selectedHouseId;
  List<Map<String, dynamic>> houseOptions = [];

  late AddUserLogic logic;

  @override
  void initState() {
    super.initState();
    logic = AddUserLogic(
      context: context,
      updateHouseOptions: (newHouseOptions) {
        setState(() => houseOptions = newHouseOptions);
      },
      updateSelectedHouse: (newHouseId) {
        setState(() => selectedHouseId = newHouseId);
      },
    );
    logic.loadHouseOptions();
  }

  /// Validate and save user
  void _saveUser() {
    logic.validateAndSaveUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      userType: userType,
      selectedHouseId: selectedHouseId,
      onSuccess: () {
        setState(() {}); // Ensure UI updates after save
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: AppColors.colorScheme.primary,
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
            _buildUserTypeSelection(),
            const SizedBox(height: 20),
            _buildTextField(nameController, 'Name'),
            const SizedBox(height: 20),
            _buildTextField(emailController, 'Email (must be gmail.com)', TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildHouseDropdown(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveUser,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the user type selection radio buttons
  Widget _buildUserTypeSelection() {
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

  /// Builds individual radio button
  Widget _buildRadioButton(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: userType,
          onChanged: (String? newValue) {
            setState(() {
              userType = newValue!;
            });
          },
        ),
        Text(value),
      ],
    );
  }

  /// Builds a text field with a given label
  Widget _buildTextField(TextEditingController controller, String label, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: type,
    );
  }

  /// Builds the dropdown for selecting a house
  Widget _buildHouseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('House', style: TextStyle(fontSize: 18)),
        DropdownButton<int>(
          value: selectedHouseId,
          hint: const Text('Select House'),
          items: houseOptions.map<DropdownMenuItem<int>>((house) {
            return DropdownMenuItem<int>(
              value: house['id'],
              child: Text(house['name']!),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              selectedHouseId = newValue;
            });
          },
        ),
        if (houseOptions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'No houses available. Please create a house first.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
