import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Edit profile: contact number and address.
/// The username is locked once it exists (accounts that never got a username
/// can choose one a single time).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _usernameLocked = true;

  static final _usernameRule = RegExp(r'^[A-Za-z0-9_]{3,20}$');
  static final _phoneChars = RegExp(r'^[0-9+\-\s()]+$');

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      final row = await _db
          .from('profiles')
          .select('username, phone, address')
          .eq('id', user.id)
          .maybeSingle();

      final fromProfile = (row?['username'] as String?)?.trim() ?? '';
      final fromMeta = (user.userMetadata?['username'] as String?)?.trim() ?? '';
      final username = fromProfile.isNotEmpty ? fromProfile : fromMeta;

      _username.text = username;
      _usernameLocked = username.isNotEmpty;
      _phone.text = (row?['phone'] as String?) ?? '';
      _address.text = (row?['address'] as String?) ?? '';
    } catch (_) {
      _snack('Could not load your profile. Did you run supabase_profile.sql?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _db.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final phone = _phone.text.trim();
      final address = _address.text.trim();

      final data = <String, dynamic>{
        'id': user.id,
        'phone': phone.isEmpty ? null : phone,
        'address': address.isEmpty ? null : address,
      };

      // Only accounts without a username can choose one (once).
      String? newUsername;
      if (!_usernameLocked && _username.text.trim().isNotEmpty) {
        newUsername = _username.text.trim();
        final available = await _db
            .rpc('username_available', params: {'name': newUsername});
        if (available != true) {
          _snack('That username is already taken. Try another one.');
          return;
        }
        data['username'] = newUsername;
      }

      await _db.from('profiles').upsert(data);

      if (newUsername != null) {
        await _db.auth.updateUser(
          UserAttributes(data: {'username': newUsername}),
        );
        if (mounted) setState(() => _usernameLocked = true);
      }

      _snack('Profile saved');
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      _snack('Could not save: ${e.message}');
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(
    String label,
    IconData icon, {
    String? helper,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username (locked)
                      TextFormField(
                        controller: _username,
                        enabled: !_usernameLocked,
                        autocorrect: false,
                        decoration: _dec(
                          'Username',
                          Icons.alternate_email,
                          helper: _usernameLocked
                              ? "Your username can't be changed."
                              : "Choose carefully. You can't change it later.",
                          suffix: _usernameLocked
                              ? const Icon(Icons.lock_outline)
                              : null,
                        ),
                        validator: (v) {
                          if (_usernameLocked) return null;
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null; // optional
                          if (!_usernameRule.hasMatch(value)) {
                            return '3-20 letters, numbers or underscore only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Contact number
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _dec(
                          'Contact number',
                          Icons.phone_outlined,
                          helper: 'We use this for your delivery.',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null;
                          final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (!_phoneChars.hasMatch(value) ||
                              digits.length < 10 ||
                              digits.length > 13) {
                            return 'Enter a valid contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Address
                      TextFormField(
                        controller: _address,
                        minLines: 3,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        decoration: _dec(
                          'Address',
                          Icons.location_on_outlined,
                          helper: 'House no., street, barangay, city',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isNotEmpty && value.length < 8) {
                            return 'Please enter your full address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                )
                              : const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}