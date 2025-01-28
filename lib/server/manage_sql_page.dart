import 'package:flutter/material.dart';
import 'database_service.dart'; // Import the database service

class ManageSQLPage extends StatefulWidget {
  const ManageSQLPage({super.key});

  @override
  _ManageSQLPageState createState() => _ManageSQLPageState();
}

class _ManageSQLPageState extends State<ManageSQLPage> {
  // Controllers for input fields
  final TextEditingController _tableNameController = TextEditingController();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldValueController = TextEditingController();
  final TextEditingController _deleteConditionController = TextEditingController();

  // To display fetched data
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;

  // Fetch data from the specified table
  Future<void> _fetchTableData() async {
    setState(() {
      _isLoading = true;
      _tableData = [];
    });

    final tableName = _tableNameController.text.trim();
    if (tableName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a table name')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('[INFO] Fetching data from table: $tableName');
      await DatabaseService.fetchData(tableName);
      // For simplicity, simulate fetching data into _tableData
      // Replace with actual logic from fetchData()
      _tableData = [
        {'id': 1, 'name': 'John', 'age': 30},
        {'id': 2, 'name': 'Jane', 'age': 25},
      ];
      print('[SUCCESS] Data fetched successfully');
    } catch (e) {
      print('[ERROR] Failed to fetch table data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Insert data into the specified table
  Future<void> _insertTableData() async {
    final tableName = _tableNameController.text.trim();
    final fieldName = _fieldNameController.text.trim();
    final fieldValue = _fieldValueController.text.trim();

    if (tableName.isEmpty || fieldName.isEmpty || fieldValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      print('[INFO] Inserting data into table: $tableName');
      await DatabaseService.insertData(tableName, {fieldName: fieldValue});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inserted successfully')),
      );
      print('[SUCCESS] Data inserted successfully');
    } catch (e) {
      print('[ERROR] Failed to insert data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to insert data: $e')),
      );
    }
  }

  Future<void> _deleteTableData() async {
  final tableName = _tableNameController.text.trim();
  final deleteCondition = _deleteConditionController.text.trim();

  if (tableName.isEmpty || deleteCondition.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in the table name and condition')),
    );
    return;
  }

  try {
    print('[INFO] Deleting data from table: $tableName with condition: $deleteCondition');

    // Call the database service to delete the data
    await DatabaseService.deleteData(tableName, deleteCondition);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data deleted successfully')),
    );
    print('[SUCCESS] Data deleted successfully');
  } catch (e) {
    print('[ERROR] Failed to delete data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete data: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL Table Manager'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Table Name', style: TextStyle(fontSize: 18)),
              TextField(
                controller: _tableNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter table name',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _fetchTableData,
                child: const Text('Fetch Table Data'),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_tableData.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _tableData.first.keys
                        .map((key) => DataColumn(label: Text(key)))
                        .toList(),
                    rows: _tableData
                        .map(
                          (row) => DataRow(
                            cells: row.values
                                .map((value) => DataCell(Text(value.toString())))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 20),
              const Text('Insert Data', style: TextStyle(fontSize: 18)),
              TextField(
                controller: _fieldNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Field Name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fieldValueController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Field Value',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _insertTableData,
                child: const Text('Insert Data'),
              ),

              const SizedBox(height: 20),
              const Text('Delete Data', style: TextStyle(fontSize: 18)),
              TextField(
                controller: _deleteConditionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Delete Condition (e.g., id=1)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteTableData,
                child: const Text('Delete Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
