import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/address_controller.dart';
import '../data/address.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final Address? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _recipient =
      TextEditingController(text: widget.existing?.recipientName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _province = TextEditingController(text: widget.existing?.province);
  late final _postal =
      TextEditingController(text: widget.existing?.postalCode);
  late bool _isDefault = widget.existing?.isDefault ?? false;
  var _saving = false;

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    _line1.dispose();
    _city.dispose();
    _province.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressListProvider.notifier).save(
            id: widget.existing?.id,
            recipientName: _recipient.text.trim(),
            phone: _phone.text.trim(),
            line1: _line1.text.trim(),
            city: _city.text.trim(),
            province: _province.text.trim(),
            postalCode: _postal.text.trim(),
            isDefault: _isDefault,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Tambah alamat' : 'Edit alamat'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _recipient,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Nama penerima'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: _required,
              decoration: const InputDecoration(labelText: 'No. HP'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line1,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Alamat lengkap'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Kota/Kabupaten'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _province,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Provinsi'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postal,
              keyboardType: TextInputType.number,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Kode pos'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jadikan alamat utama'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
