import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AddMemberScreen extends StatefulWidget {
  final FamilyMember? existingMember;
  const AddMemberScreen({super.key, this.existingMember});
  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'Male';
  String _relation = 'Parent';
  bool _isLoading = false;
  bool get _isEdit => widget.existingMember != null;

  final _relations = ['Parent', 'Child', 'Partner', 'Sibling', 'Friend', 'Grandparent', 'Uncle/Aunt', 'Cousin'];
  final _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final m = widget.existingMember!;
      _nameCtrl.text = m.fullName;
      _dobCtrl.text = m.dateOfBirth ?? '';
      _notesCtrl.text = m.notes ?? '';
      _gender = m.gender ?? 'Male';
      _relation = m.relation ?? 'Parent';
      
      if (!_genders.contains(_gender)) {
        _genders.add(_gender);
      }
      if (!_relations.contains(_relation)) {
        _relations.add(_relation);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime(1980),
      firstDate: DateTime(1850), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: NestTheme.deepAmber, onPrimary: Colors.white)), child: child!),
    );
    if (date != null) {
      _dobCtrl.text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser!;
      if (_isEdit) {
        await DatabaseService().updateFamilyMember(widget.existingMember!.id, {
          'fullName': _nameCtrl.text.trim(),
          'dateOfBirth': _dobCtrl.text,
          'gender': _gender,
          'relation': _relation,
          'notes': _notesCtrl.text.trim(),
        });
      } else {
        await DatabaseService().addFamilyMember(FamilyMember(
          id: '', userId: user.$id,
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text,
          gender: _gender,
          relation: _relation,
          notes: _notesCtrl.text.trim(),
          isApproved: true,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Person' : 'Add Family Member'), backgroundColor: NestTheme.cream),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Avatar
          Center(child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: NestTheme.parchment,
                border: Border.all(color: NestTheme.amber.withOpacity(0.3), width: 3)),
            child: Icon(Icons.person_rounded, size: 48, color: NestTheme.deepAmber),
          )),
          const SizedBox(height: 28),

          // Name
          Text('Full Name', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Enter full name', prefixIcon: Icon(Icons.person_outline, size: 20))),
          const SizedBox(height: 20),

          // DOB
          Text('Date of Birth', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(onTap: _pickDate, child: AbsorbPointer(child: TextFormField(controller: _dobCtrl,
              decoration: const InputDecoration(hintText: 'mm/dd/yyyy', prefixIcon: Icon(Icons.calendar_today_outlined, size: 20))))),
          const SizedBox(height: 20),

          // Gender
          Text('Gender', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: NestTheme.inputRadius,
                border: Border.all(color: NestTheme.mist.withOpacity(0.5))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _gender, isExpanded: true,
              items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _gender = v!),
            )),
          ),
          const SizedBox(height: 20),

          // Relation
          Text('Relationship', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: NestTheme.inputRadius,
                border: Border.all(color: NestTheme.mist.withOpacity(0.5))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _relation, isExpanded: true,
              items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _relation = v!),
            )),
          ),
          const SizedBox(height: 20),

          // Notes
          Text('Notes (Optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(controller: _notesCtrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any notes about this person...')),
          const SizedBox(height: 32),

          // Buttons
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Cancel'))),
            const SizedBox(width: 14),
            Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_isEdit ? 'Update' : 'Save'))),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
