import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import 'package:g14_indoor_locator/server/database_service.dart';

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
    _loadHouseOptions(); // Load house options from MariaDB
  }

  Future<void> _loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses(); // Fetch houses from MariaDB
      setState(() {
        houseOptions = houses.map((house) => house['name'].toString()).toList();
      });
    } catch (e) {
      print("[ERROR] Failed to load house options: $e");
    }
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

  Future<bool> _canPop() async {
    if (!isSaved) {
      return await showUnsavedChangesDialog();
    }
    return true; // Allow navigation if saved
  }

  void _validateAndSave() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || selectedHouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!isValidName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name should only contain alphabetic characters.')),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email must be a valid Gmail account.')),
      );
      return;
    }

    try {
      // Fetch the house ID from MariaDB
      int? houseId = await DatabaseService.getHouseIdByName(selectedHouse!);

      if (houseId == null) {
        print("[ERROR] House ID not found for house: $selectedHouse");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid house selection.')),
        );
        return;
      }

      // Insert into MariaDB
      await DatabaseService.insertUser({
        'name': name,
        'email': email,
        'userType': userType,
        'house': houseId, // Using the house ID instead of house name
      });

      setState(() {
        isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print("[ERROR] Failed to insert user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        if (!await _canPop()) {
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add User'),
          backgroundColor: AppColors.colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _canPop()) {
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
