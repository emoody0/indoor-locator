import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import 'package:g14_indoor_locator/server/database_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String userType = 'User'; // Default user type
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? selectedHouseId; // Store selected house ID as int
  bool isSaved = false; // Tracks if the user clicked the Save button
  List<Map<String, dynamic>> houseOptions = []; // Stores house ID and name

  @override
  void initState() {
    super.initState();
    _loadHouseOptions(); // Load house options from MariaDB
  }

  Future<void> _loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses(); // Fetch houses from MariaDB
      setState(() {
        houseOptions = houses.map((house) => {
          'id': house['id'], // Store house ID as int
          'name': house['name'].toString(), // Store house name
        }).toList();

        // Default to the first available house if none is selected
        if (selectedHouseId == null && houseOptions.isNotEmpty) {
          selectedHouseId = houseOptions.first['id'];
        }
      });

      print("[DEBUG] Loaded house options: $houseOptions");
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

  Future<void> _validateAndSave() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    print("[DEBUG] Selected House ID before inserting: $selectedHouseId");

    try {
      // Ensure house ID is valid
      if (selectedHouseId == null) {
        print("[ERROR] House ID is NULL before inserting user.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid house selection.')),
        );
        return;
      }

      // Insert user into MariaDB
      await DatabaseService.insertUser({
        'name': name,
        'email': email,
        'userType': userType,
        'house_id': selectedHouseId, // Pass house_id as an int
      });

      print("[SUCCESS] User added successfully with House ID: $selectedHouseId");

      setState(() {
        isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully!')),
      );

      Navigator.pop(context); // Go back after saving
    } catch (e) {
      print("[ERROR] Failed to add user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Type', style: TextStyle(fontSize: 18)),
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
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email (must be gmail.com)', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            const Text('House', style: TextStyle(fontSize: 18)),
            DropdownButton<int>(
              value: selectedHouseId,
              hint: const Text('Select House'),
              items: houseOptions.map<DropdownMenuItem<int>>((house) {
                return DropdownMenuItem<int>(
                  value: house['id'], // Store house ID as int
                  child: Text(house['name']!), // Show house name
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedHouseId = newValue; // Store selected house ID
                  print("[DEBUG] Selected House ID: $selectedHouseId");
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
    );
  }
}
