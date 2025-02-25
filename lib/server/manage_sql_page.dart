import 'package:flutter/material.dart';
import 'database_service.dart';

class ManageSQLPage extends StatefulWidget {
  const ManageSQLPage({super.key});

  @override
  _ManageSQLPageState createState() => _ManageSQLPageState();
}

class _ManageSQLPageState extends State<ManageSQLPage> {
  final TextEditingController _tableNameController = TextEditingController();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldValueController = TextEditingController();
  final TextEditingController _deleteConditionController = TextEditingController();

  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;

  /// Fetch and update table data
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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await DatabaseService.fetchData(tableName);
      setState(() {
        _tableData = data;
      });
    } catch (e) {
      print('[ERROR] Failed to fetch table data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Insert data into the specified table
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
      await DatabaseService.insertData(tableName, {fieldName: fieldValue});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inserted successfully')),
      );
      _fetchTableData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to insert data: $e')),
      );
    }
  }

  /// Delete data from the specified table
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
      await DatabaseService.deleteData(tableName, deleteCondition);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data deleted successfully')),
      );
      _fetchTableData();
    } catch (e) {
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
              _buildTextField(_tableNameController, 'Table Name'),
              _buildButton('Fetch Table Data', _fetchTableData),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (_tableData.isNotEmpty) _buildDataTable(),

              _buildTextField(_fieldNameController, 'Field Name'),
              _buildTextField(_fieldValueController, 'Field Value'),
              _buildButton('Insert Data', _insertTableData),

              _buildTextField(_deleteConditionController, 'Delete Condition (e.g., id=1)'),
              _buildButton('Delete Data', _deleteTableData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        TextField(
          controller: controller,
          decoration: InputDecoration(border: OutlineInputBorder(), labelText: label),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _tableData.first.keys.map((key) => DataColumn(label: Text(key))).toList(),
        rows: _tableData.map(
          (row) => DataRow(
            cells: row.values.map((value) => DataCell(Text(value.toString()))).toList(),
          ),
        ).toList(),
      ),
    );
  }
}
