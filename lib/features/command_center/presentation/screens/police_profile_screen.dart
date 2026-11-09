import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/police_tactical_theme.dart';
import '../../../auth/domain/entities/police_officer.dart';
import '../../../auth/presentation/auth_controller.dart';

class PoliceProfileScreen extends ConsumerStatefulWidget {
  final PoliceOfficer officer;

  const PoliceProfileScreen({super.key, required this.officer});

  @override
  ConsumerState<PoliceProfileScreen> createState() =>
      _PoliceProfileScreenState();
}

class _PoliceProfileScreenState extends ConsumerState<PoliceProfileScreen> {
  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'PO';
    final cleaned = name
        .replaceAll(
            RegExp(
                r'\b(Bripka|Ipda|Aipda|Aiptu|Bripda|Briptu|Kompol|Akp|Iptu|S\.H\.|S\.Tr\.K\.|S\.Pd\.|M\.Pd\.|S\.Psi\.)\b',
                caseSensitive: false),
            '')
        .trim();
    final parts =
        (cleaned.isNotEmpty ? cleaned : name).trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showEditProfileDialog(BuildContext context, PoliceOfficer officer) {
    final nameCtrl = TextEditingController(text: officer.fullName);
    final phoneCtrl = TextEditingController(text: officer.phoneWa);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131D31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.badge_outlined,
                      color: Color(0xFFFF8A3D), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Ubah Data Diri Anggota Polri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Beserta Pangkat',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFFFF8A3D), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A263D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp Dinas / Pribadi',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.phone_android,
                      color: Color(0xFFFF8A3D), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A263D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          setModalState(() => isSaving = true);
                          final err = await ref
                              .read(authStateProvider.notifier)
                              .updateProfile(
                                fullName: nameCtrl.text,
                                phoneWa: phoneCtrl.text,
                              );
                          if (!mounted || !ctx.mounted) return;
                          setModalState(() => isSaving = false);
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: err == null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              content: Text(err ??
                                  'Data diri profil berhasil diperbarui!'),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131D31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFFFF8A3D), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Ganti Kata Sandi Dinas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oldPassCtrl,
                obscureText: obscureOld,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon:
                      const Icon(Icons.key, color: Color(0xFFFF8A3D), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF94A3B8),
                        size: 18),
                    onPressed: () =>
                        setModalState(() => obscureOld = !obscureOld),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A263D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru (Min. 6 Karakter)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFFFF8A3D), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF94A3B8),
                        size: 18),
                    onPressed: () =>
                        setModalState(() => obscureNew = !obscureNew),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A263D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFFFF8A3D), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A263D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (newPassCtrl.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFFEF4444),
                                content:
                                    Text('Kata sandi baru minimal 6 karakter.'),
                              ),
                            );
                            return;
                          }
                          if (newPassCtrl.text != confirmPassCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFFEF4444),
                                content:
                                    Text('Konfirmasi kata sandi tidak cocok.'),
                              ),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          setModalState(() => isSaving = true);
                          final err = await ref
                              .read(authStateProvider.notifier)
                              .changePassword(
                                currentPassword: oldPassCtrl.text,
                                newPassword: newPassCtrl.text,
                              );
                          if (!mounted || !ctx.mounted) return;
                          setModalState(() => isSaving = false);
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: err == null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              content: Text(
                                  err ?? 'Kata sandi berhasil diperbarui!'),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'SIMPAN KATA SANDI',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOfficer =
        ref.watch(authStateProvider).officer ?? widget.officer;
    final bool isPolantas = currentOfficer.role == PoliceRole.polantas;
    final initials = _getInitials(currentOfficer.fullName);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1322),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Avatar Initial Name & Verified Badge
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF1E40AF),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFF8A3D),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentOfficer.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'NRP: ${currentOfficer.nrp}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPolantas
                          ? PoliceTacticalColors.electricCyan
                          : PoliceTacticalColors.warningAmber)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPolantas
                        ? PoliceTacticalColors.electricCyan
                        : PoliceTacticalColors.warningAmber,
                    width: 1,
                  ),
                ),
                child: Text(
                  isPolantas
                      ? 'PETUGAS POLANTAS LAPANGAN'
                      : 'SATUAN UNIT KAMSEL POLRES',
                  style: TextStyle(
                    color: isPolantas
                        ? PoliceTacticalColors.electricCyan
                        : PoliceTacticalColors.warningAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: Ubah Profil & Ganti Kata Sandi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF162032),
                      ),
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFFFF8A3D)),
                      label: const Text(
                        'Ubah Profil',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () =>
                          _showEditProfileDialog(context, currentOfficer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF162032),
                      ),
                      icon: const Icon(Icons.lock_outline,
                          size: 16, color: Color(0xFFFF8A3D)),
                      label: const Text(
                        'Ganti Sandi',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showChangePasswordDialog(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Detail Card - Identitas Personal & Akun Resmi
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF162032),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      title: 'Nomor Registrasi Pokok (NRP)',
                      value: currentOfficer.nrp,
                    ),
                    const Divider(color: Color(0xFF223046), height: 1),
                    _buildInfoTile(
                      icon: Icons.phone_android,
                      title: 'No. WhatsApp Dinas / Pribadi',
                      value: currentOfficer.phoneWa.isNotEmpty
                          ? currentOfficer.phoneWa
                          : '-',
                    ),
                    const Divider(color: Color(0xFF223046), height: 1),
                    _buildInfoTile(
                      icon: Icons.shield_outlined,
                      title: 'Kesatuan / Fungsi',
                      value: isPolantas
                          ? 'Satlantas (Unit Turjawali / Gakkum)'
                          : 'Satlantas (Unit Kamsel)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App Version
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162032).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'SI-PELANTAS MOBILE POLRI v1.0.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Build Resmi Satlantas Polres Mojokerto 2026',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFFEF4444),
                    side:
                        const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'KELUAR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
