import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import '../database_helper.dart';

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
  List<String> houseOptions = []; // Dynamic house options

  @override
  void initState() {
    super.initState();
    _loadHouseOptions(); // Load house options from the database
  }

  Future<void> _loadHouseOptions() async {
    final db = DatabaseHelper();
    final options = await db.getDistinctHouseNames(); // Fetch distinct house names
    setState(() {
      houseOptions = options; // Update the options
    });
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
    if (!isSaved) {
      return await showUnsavedChangesDialog();
    }
    return true; // Allow navigation if saved
  }

  void _validateAndSave() async {
    final name = nameController.text;
    final email = emailController.text;

    if (name.isEmpty || email.isEmpty || selectedHouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
    } else if (!isValidName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name should only contain alphabetic characters.')),
      );
    } else if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email must be a valid Gmail account.')),
      );
    } else {
      final db = DatabaseHelper();
      await db.insertUser({
        'name': name,
        'email': email,
        'userType': userType,
        'house': selectedHouse,
        'organization': 'DefaultOrg', // Adjust as necessary
      });

      setState(() {
        isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User saved successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add User'),
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
        body: SingleChildScrollView(
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

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  errorText: isValidName(nameController.text) || nameController.text.isEmpty
                      ? null
                      : 'Name should only contain alphabetic characters',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email (must be gmail.com)',
                  border: const OutlineInputBorder(),
                  errorText: isValidEmail(emailController.text) || emailController.text.isEmpty
                      ? null
                      : 'Email must be a valid Gmail account (e.g., user@gmail.com)',
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
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
                  });
                },
              ),
              if (selectedHouse == null && houseOptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No houses available. Please create a house first.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _validateAndSave,
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
