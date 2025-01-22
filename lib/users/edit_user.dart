import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import '../database_helper.dart'; // Import DatabaseHelper for user data handling

class EditUserPage extends StatefulWidget {
  final int id; // User ID
  final String name;
  final String email;
  final String house;
  final String userType; // Admin or User

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
  String? selectedHouse;
  bool isSaved = false; // Tracks if the user clicked the Save button
  bool hasChanges = false; // Tracks if any changes were made

  final DatabaseHelper dbHelper = DatabaseHelper(); // Database helper instance
  final List<String> houseOptions = ['House 1', 'House 2', 'House 3']; // Example house options

  @override
  void initState() {
    super.initState();
    userType = widget.userType;
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    selectedHouse = widget.house;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return emailRegex.hasMatch(email);
  }

  bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return name.isNotEmpty && nameRegex.hasMatch(name);
  }

  Future<bool> showUnsavedChangesDialog() async {
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
                    Navigator.of(context).pop(false); // Dismiss and stay on the page
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Confirm and go back
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dismissed
  }

  Future<bool> _onWillPop() async {
    if (!isSaved && hasChanges) {
      return await showUnsavedChangesDialog();
    }
    return true; // Allow navigation if saved or no changes
  }

  void trackChanges() {
    setState(() {
      hasChanges = userType != widget.userType ||
          nameController.text != widget.name ||
          emailController.text != widget.email ||
          selectedHouse != widget.house;
    });
  }

  Future<void> _validateAndSave() async {
    final name = nameController.text;
    final email = emailController.text;

    if (name.isEmpty || email.isEmpty || selectedHouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
    } else if (!isValidName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name should only contain alphabetic characters.'),
        ),
      );
    } else if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email must be a valid Gmail account (e.g., user@gmail.com).'),
        ),
      );
    } else {
      // Save to database
      await dbHelper.updateUser(widget.id, {
        'name': name,
        'email': email,
        'userType': userType,
        'house': selectedHouse,
      });

      setState(() {
        isSaved = true; // Mark as saved
        hasChanges = false; // Reset change tracking
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully!'),
        ),
      );

      Navigator.pop(context); // Go back after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit User'),
          backgroundColor: AppColors.colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SingleChildScrollView( // Add scroll view to prevent overflow
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Type',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Admin',
                    groupValue: userType,
                    onChanged: (String? value) {
                      setState(() {
                        userType = value!;
                        trackChanges();
                      });
                    },
                  ),
                  const Text('Admin'),
                  Radio<String>(
                    value: 'User',
                    groupValue: userType,
                    onChanged: (String? value) {
                      setState(() {
                        userType = value!;
                        trackChanges();
                      });
                    },
                  ),
                  const Text('User'),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                onChanged: (value) => trackChanges(),
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  errorText: isValidName(nameController.text) || nameController.text.isEmpty
                      ? null
                      : 'Name should only contain alphabetic characters',
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                onChanged: (value) => trackChanges(),
                decoration: InputDecoration(
                  labelText: 'Email (must be gmail.com)',
                  border: const OutlineInputBorder(),
                  errorText: isValidEmail(emailController.text) || emailController.text.isEmpty
                      ? null
                      : 'Email must be a valid Gmail account (e.g., user@gmail.com)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              const Text(
                'House',
                style: TextStyle(fontSize: 18),
              ),
              DropdownButton<String>(
                value: selectedHouse,
                hint: const Text('Select House'),
                items: houseOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedHouse = newValue;
                    trackChanges();
                  });
                },
              ),
              if (selectedHouse == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select a house',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: hasChanges ? _validateAndSave : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
