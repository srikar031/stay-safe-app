import 'package:flutter/material.dart';

class AddContactDialog extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? relationship;
  final Function(String name, String phone, String relationship) onAdd;

  const AddContactDialog({
    super.key,
    this.name,
    this.phone,
    this.relationship,
    required this.onAdd,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _relationship = 'Family';

  final List<String> _relationships = ['Family', 'Friend', 'Work', 'Neighbor', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
    if (widget.relationship != null && _relationships.contains(widget.relationship)) {
      _relationship = widget.relationship!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.name == null ? 'Add to Circle' : 'Edit Contact', 
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF02579C))),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(_nameController, 'Name', Icons.person_outline, TextInputType.name),
              const SizedBox(height: 16),
              _buildField(_phoneController, 'Phone Number', Icons.phone_outlined, TextInputType.phone),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF02579C)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _relationships.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _relationship = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF02579C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(_nameController.text, _phoneController.text, _relationship);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF02579C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
