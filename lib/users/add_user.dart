import 'package:flutter/material.dart';
import 'config.dart'; // Import config file

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String userType = 'User'; // Default to 'User'
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedHouse; // Selected house
  bool isSaved = false; // Tracks if the user clicked the Save button
  final List<String> houseOptions = ['House 1', 'House 2', 'House 3']; // Example house options

  // Validate the email address to ensure it's a Gmail account
  bool isValidEmail(String email) {
    return email.endsWith('@gmail.com');
  }

  // Show a dialog when trying to navigate back without saving
  Future<bool> showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                  'Are you sure? Your current changes will be lost.'),
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

  // Handle back navigation with unsaved changes check
  Future<bool> _onWillPop() async {
    if (!isSaved) {
      return await showUnsavedChangesDialog();
    }
    return true; // Allow navigation if saved
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle unsaved changes on back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add User'),
          backgroundColor: AppColors.colorScheme.primary, // Use color from config
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Check if there are unsaved changes before popping the page
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Padding(
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
                      });
                    },
                  ),
                  const Text('User'),
                ],
              ),
              const SizedBox(height: 20),

              // Name input
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Email input
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (must be gmail.com)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // House dropdown
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
                  });
                },
              ),
              const SizedBox(height: 30),

              // Save button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedHouse == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields.'),
                        ),
                      );
                    } else if (!isValidEmail(emailController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email must be a valid Gmail account.'),
                        ),
                      );
                    } else {
                      // Perform save action
                      setState(() {
                        isSaved = true; // Mark as saved
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User saved successfully!'),
                        ),
                      );
                    }
                  },
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
