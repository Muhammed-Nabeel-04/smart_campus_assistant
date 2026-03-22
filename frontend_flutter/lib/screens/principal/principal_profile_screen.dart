// File: lib/screens/principal/principal_profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';
import '../../main.dart';

class PrincipalProfileScreen extends StatefulWidget {
  const PrincipalProfileScreen({super.key});

  @override
  State<PrincipalProfileScreen> createState() => _PrincipalProfileScreenState();
}

class _PrincipalProfileScreenState extends State<PrincipalProfileScreen> {
  // ── Principal role color ───────────────────────────────────
  static const Color _principalColor = Color(0xFF9C27B0);

  // ── Personal details (editable) ───────────────────────────
  String _name = '';
  String _email = '';
  String _phone = '';
  String _collegeName = '';
  String _collegeCode = '';
  bool _isEditingDetails = false;

  // ── Password accordion ────────────────────────────────────
  bool _passwordExpanded = false;
  bool _emailExpanded = false;

  // ── Controllers ───────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _collegeNameCtrl;
  late TextEditingController _collegeCodeCtrl;

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _emailPassCtrl = TextEditingController();

  final _passFormKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPass = false;
  bool _isChangingEmail = false;
  bool _isSavingDetails = false;

  @override
  void initState() {
    super.initState();
    _name = SessionManager.name ?? '';
    _email = SessionManager.email ?? '';
    _phone = '';
    _collegeName = '';
    _collegeCode = '';

    _nameCtrl = TextEditingController(text: _name);
    _emailCtrl = TextEditingController(text: _email);
    _phoneCtrl = TextEditingController(text: _phone);
    _collegeNameCtrl = TextEditingController(text: _collegeName);
    _collegeCodeCtrl = TextEditingController(text: _collegeCode);
    _newEmailCtrl.text = _email;

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Step 1 — Load from SharedPreferences instantly (no flicker)
    final meta = await SessionManager.loadPrincipalMeta();
    if (mounted) {
      setState(() {
        _phone = meta['phone'] ?? '';
        _collegeName = meta['college_name'] ?? '';
        _collegeCode = meta['college_code'] ?? '';
        _phoneCtrl.text = _phone;
        _collegeNameCtrl.text = _collegeName;
        _collegeCodeCtrl.text = _collegeCode;
      });
    }

    // Step 2 — Fetch from backend (only overwrite if backend has non-empty value)
    try {
      final profile = await ApiService.getPrincipalProfile();
      if (mounted) {
        setState(() {
          if ((profile['name'] ?? '').toString().isNotEmpty)
            _name = profile['name'];
          if ((profile['phone'] ?? '').toString().isNotEmpty)
            _phone = profile['phone'];
          if ((profile['college_name'] ?? '').toString().isNotEmpty)
            _collegeName = profile['college_name'];
          if ((profile['college_code'] ?? '').toString().isNotEmpty)
            _collegeCode = profile['college_code'];

          _nameCtrl.text = _name;
          _phoneCtrl.text = _phone;
          _collegeNameCtrl.text = _collegeName;
          _collegeCodeCtrl.text = _collegeCode;
        });

        // Step 3 — Cache whatever is valid back to SharedPreferences
        await SessionManager.updateProfile(
          name: _name,
          phone: _phone,
          collegeName: _collegeName,
          collegeCode: _collegeCode,
        );
      }
    } catch (_) {
      // Backend failed — SharedPreferences data already loaded, nothing lost
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeNameCtrl.dispose();
    _collegeCodeCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _newEmailCtrl.dispose();
    _emailPassCtrl.dispose();
    super.dispose();
  }

  // ── Save personal details ──────────────────────────────────
  Future<void> _saveDetails() async {
    setState(() => _isSavingDetails = true);
    try {
      // Save to backend
      await ApiService.updatePrincipalProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        collegeName: _collegeNameCtrl.text.trim(),
        collegeCode: _collegeCodeCtrl.text.trim(),
      );

      // Cache to SharedPreferences
      await SessionManager.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        collegeName: _collegeNameCtrl.text.trim(),
        collegeCode: _collegeCodeCtrl.text.trim(),
      );

      setState(() {
        _name = _nameCtrl.text.trim();
        _phone = _phoneCtrl.text.trim();
        _collegeName = _collegeNameCtrl.text.trim();
        _collegeCode = _collegeCodeCtrl.text.trim();
        _isEditingDetails = false;
      });
      _showSnack('Details updated successfully');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack('Failed to update details', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingDetails = false);
    }
  }

  // ── Change password ────────────────────────────────────────
  Future<void> _handleChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isChangingPass = true);
    try {
      await ApiService.changePrincipalPassword(
        currentPassword: _currentPassCtrl.text,
        newPassword: _newPassCtrl.text,
      );
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() => _passwordExpanded = false);
      _showSnack('Password updated successfully');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  // ── Change email ───────────────────────────────────────────
  Future<void> _handleChangeEmail() async {
    final email = _newEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Enter a valid email', isError: true);
      return;
    }
    if (_emailPassCtrl.text.isEmpty) {
      _showSnack('Enter your password to confirm', isError: true);
      return;
    }
    setState(() => _isChangingEmail = true);
    try {
      await ApiService.changePrincipalEmail(
        newEmail: email,
        password: _emailPassCtrl.text,
      );
      await SessionManager.updateProfile(email: email);
      _emailPassCtrl.clear();
      setState(() {
        _email = email;
        _emailExpanded = false;
      });
      _showSnack('Email updated successfully');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.logout();
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditingDetails)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Details',
              onPressed: () => setState(() => _isEditingDetails = true),
            ),
          if (_isEditingDetails)
            TextButton(
              onPressed: () => setState(() {
                _isEditingDetails = false;
                // Reset controllers
                _nameCtrl.text = _name;
                _phoneCtrl.text = _phone;
                _collegeNameCtrl.text = _collegeName;
                _collegeCodeCtrl.text = _collegeCode;
              }),
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Header ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_principalColor, _principalColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _principalColor.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _name.isNotEmpty
                          ? _name.substring(0, 1).toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _name.isNotEmpty ? _name : 'Principal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_collegeName.isNotEmpty)
                  Text(
                    _collegeName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Personal Details Card ────────────────────────────
          _SectionCard(
            title: 'Personal Details',
            icon: Icons.person_outline_rounded,
            cs: cs,
            child: _isEditingDetails
                ? _buildEditForm(cs)
                : _buildDetailsView(cs),
          ),

          const SizedBox(height: 12),

          // ── Security Card ────────────────────────────────────
          _SectionCard(
            title: 'Security',
            icon: Icons.shield_outlined,
            cs: cs,
            child: Column(
              children: [
                // Change Password accordion
                _AccordionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  isExpanded: _passwordExpanded,
                  cs: cs,
                  onTap: () => setState(() {
                    _passwordExpanded = !_passwordExpanded;
                    if (_passwordExpanded) _emailExpanded = false;
                  }),
                  child: Form(
                    key: _passFormKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _currentPassCtrl,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPassCtrl,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_open_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Min 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) => v != _newPassCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isChangingPass
                                ? null
                                : _handleChangePassword,
                            child: _isChangingPass
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Update Password'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Change Email accordion
                _AccordionTile(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  isExpanded: _emailExpanded,
                  cs: cs,
                  onTap: () => setState(() {
                    _emailExpanded = !_emailExpanded;
                    if (_emailExpanded) _passwordExpanded = false;
                  }),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'New Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChangingEmail
                              ? null
                              : _handleChangeEmail,
                          child: _isChangingEmail
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Update Email'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Appearance Card ──────────────────────────────────
          _SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            cs: cs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Theme',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {SmartCampusApp.currentTheme},
                    onSelectionChanged: (val) =>
                        setState(() => SmartCampusApp.setTheme(val.first)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Sign Out Card ────────────────────────────────────
          _SectionCard(
            title: 'Account',
            icon: Icons.manage_accounts_outlined,
            cs: cs,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Details View (read-only) ───────────────────────────────
  Widget _buildDetailsView(ColorScheme cs) {
    return Column(
      children: [
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Name',
          value: _name.isNotEmpty ? _name : '—',
          cs: cs,
        ),
        _DetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _email.isNotEmpty ? _email : '—',
          cs: cs,
        ),
        _DetailRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: _phone.isNotEmpty ? _phone : 'Not set',
          cs: cs,
        ),
        _DetailRow(
          icon: Icons.account_balance_outlined,
          label: 'College Name',
          value: _collegeName.isNotEmpty ? _collegeName : 'Not set',
          cs: cs,
        ),
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'College Code',
          value: _collegeCode.isNotEmpty ? _collegeCode : 'Not set',
          cs: cs,
          isLast: true,
        ),
      ],
    );
  }

  // ── Edit Form ──────────────────────────────────────────────
  Widget _buildEditForm(ColorScheme cs) {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _collegeNameCtrl,
          decoration: const InputDecoration(
            labelText: 'College Name',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _collegeCodeCtrl,
          decoration: const InputDecoration(
            labelText: 'College Code / ID',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSavingDetails ? null : _saveDetails,
            icon: const Icon(Icons.save_outlined),
            label: _isSavingDetails
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Details'),
          ),
        ),
      ],
    );
  }
}

// ── Reusable Section Card ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ColorScheme cs;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF9C27B0), size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ── Accordion Tile ─────────────────────────────────────────────
class _AccordionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;
  final ColorScheme cs;

  const _AccordionTile({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.child,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: cs.onSurface.withOpacity(0.6), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) child,
      ],
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurface.withOpacity(0.5), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: cs.onSurface.withOpacity(0.06)),
      ],
    );
  }
}
