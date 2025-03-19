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
  String? selectedHouseId; // Store selected house ID
  bool isSaved = false;
  List<Map<String, dynamic>> houseOptions = []; // Stores house ID and name

  @override
  void initState() {
    super.initState();
    _loadHouseOptions();
  }

  Future<void> _loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses();
      setState(() {
        houseOptions = houses.map((house) => {
          'id': house['id'].toString(), // Store house ID as String
          'name': house['name'].toString() // Store house name
        }).toList();

        if (selectedHouseId == null && houseOptions.isNotEmpty) {
          selectedHouseId = houseOptions.first['id']; // Default to first available house
        }
      });
    } catch (e) {
      print("[ERROR] Failed to load house options: $e");
    }
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

    // Ensure house ID is an integer
    int? houseId = int.tryParse(selectedHouseId!);
    if (houseId == null) {
      print("[ERROR] Invalid house ID: $selectedHouseId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid house selection.')),
      );
      return;
    }

    try {
      await DatabaseService.insertUser({
        'name': name,
        'email': email,
        'userType': userType,
        'house_id': houseId, // Store correct house ID
      });

      setState(() {
        isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully!')),
      );

      Navigator.pop(context);
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
          onPressed: () => Navigator.pop(context),
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
                    setState(() => userType = value!);
                  },
                ),
                const Text('Admin'),
                Radio<String>(
                  value: 'User',
                  groupValue: userType,
                  onChanged: (String? value) {
                    setState(() => userType = value!);
                  },
                ),
                const Text('User'),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email (must be gmail.com)', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            const Text('House', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: selectedHouseId,
              hint: const Text('Select House'),
              items: houseOptions.map<DropdownMenuItem<String>>((house) {
                return DropdownMenuItem<String>(
                  value: house['id'],
                  child: Text(house['name']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedHouseId = newValue; // Store selected house ID
                });
              },
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
