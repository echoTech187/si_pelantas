import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/police_dio_client.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'polri_home_shell.dart';
import 'unit_kamsel_radar_screen.dart';

const List<Map<String, dynamic>> _kFallbackViolations = [];
// Provider untuk mengambil Master Pasal Pelanggaran langsung dari Database PostgreSQL via REST API
final violationMasterTypesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(policeDioClientProvider);
    final res = await dio.get('/violation-types');
    final List<dynamic> list = res.data['data'] as List<dynamic>;
    if (list.isNotEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    return _kFallbackViolations;
  } catch (_) {
    return _kFallbackViolations;
  }
});

class PolantasFieldViolationScreen extends ConsumerStatefulWidget {
  const PolantasFieldViolationScreen({super.key});

  @override
  ConsumerState<PolantasFieldViolationScreen> createState() =>
      _PolantasFieldViolationScreenState();
}

class _PolantasFieldViolationScreenState
    extends ConsumerState<PolantasFieldViolationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  final Set<String> _selectedViolationCodes = {'TIDAK_PAKAI_HELM_SNI'};
  final _studentNameCtrl = TextEditingController();
  final _studentClassCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _searchSchoolCtrl = TextEditingController();
  bool _isSubmitting = false;

  IconData _getViolationIcon(String code) {
    switch (code) {
      case 'TIDAK_PAKAI_HELM_SNI':
        return Icons.sports_motorsports_outlined;
      case 'BELUM_CUKUP_UMUR_TANPA_SIM':
        return Icons.badge_outlined;
      case 'KNALPOT_BRONG_TIDAK_STANDAR':
        return Icons.volume_up_outlined;
      case 'BERBONCENGAN_LEBIH_DARI_SATU':
        return Icons.group_outlined;
      case 'MELANGGAR_RAMBU_APIL':
        return Icons.traffic_outlined;
      case 'TIDAK_MEMBAWA_STNK_KELENGKAPAN':
        return Icons.description_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getViolationColor(String code) {
    switch (code) {
      case 'TIDAK_PAKAI_HELM_SNI':
        return const Color(0xFFFF8A3D);
      case 'BELUM_CUKUP_UMUR_TANPA_SIM':
        return const Color(0xFFEF4444);
      case 'KNALPOT_BRONG_TIDAK_STANDAR':
        return const Color(0xFFF59E0B);
      case 'BERBONCENGAN_LEBIH_DARI_SATU':
        return const Color(0xFFA855F7);
      case 'MELANGGAR_RAMBU_APIL':
        return const Color(0xFFEC4899);
      case 'TIDAK_MEMBAWA_STNK_KELENGKAPAN':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  void _showSchoolSearchModal(List<Map<String, dynamic>> schools) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _searchSchoolCtrl.text.toLowerCase();
            final filtered = schools.where((s) {
              final name = (s['schoolName'] ?? '').toString().toLowerCase();
              final district =
                  (s['districtName'] ?? '').toString().toLowerCase();
              final npsn = (s['npsn'] ?? '').toString();
              return name.contains(query) ||
                  district.contains(query) ||
                  npsn.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFF121B2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school,
                              color: Color(0xFFFF8A3D), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Asal Sekolah Siswa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '42 SMA/SMK/MAN Kabupaten Mojokerto',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      controller: _searchSchoolCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1A263D),
                        hintText: 'Ketik nama sekolah, kecamatan, atau NPSN...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF94A3B8), size: 20),
                        suffixIcon: _searchSchoolCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54, size: 18),
                                onPressed: () {
                                  _searchSchoolCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF8A3D), width: 1.2),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Sekolah tidak ditemukan',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final school = filtered[idx];
                              final isSelected =
                                  school['schoolId'] == _selectedSchoolId;
                              final level = school['educationLevel'] ?? 'SMA';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isSelected
                                      ? const Color(0xFFFF8A3D)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFF16233B),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF8A3D)
                                        : Colors.white.withValues(alpha: 0.06),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      level,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    school['schoolName'] ?? '',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFFF8A3D)
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${school['districtName']} • NPSN: ${school['npsn']}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: Color(0xFFFF8A3D), size: 20)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedSchoolId = school['schoolId'];
                                      _selectedSchoolName =
                                          school['schoolName'];
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitViolation() async {
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Silakan pilih Asal Sekolah Siswa terlebih dahulu.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedViolationCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content:
              Text('Pilih minimal 1 (satu) pasal pelanggaran lalu lintas.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(policeDioClientProvider);
      final payload = {
        'schoolId': _selectedSchoolId,
        'studentName': _studentNameCtrl.text.trim(),
        'studentClassName': _studentClassCtrl.text.trim(),
        'vehiclePlateNumber': _plateCtrl.text.trim().toUpperCase(),
        'violationCodes': _selectedViolationCodes.toList(),
        'incidentLocation': 'Wilayah Hukum Polres Mojokerto',
      };

      final res = await dio.post('/violations', data: payload);
      final data = res.data['data'] as Map<String, dynamic>;
      final String? waSimUrl = data['whatsapp_simulation_url'] as String?;

      if (mounted) {
        _studentNameCtrl.clear();
        _studentClassCtrl.clear();
        _plateCtrl.clear();
        setState(() {
          _selectedSchoolId = null;
          _selectedSchoolName = null;
          _selectedViolationCodes.clear();
          _selectedViolationCodes.add('TIDAK_PAKAI_HELM_SNI');
        });

        ref.invalidate(policeSchoolsRadarProvider);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF131D31),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                SizedBox(width: 10),
                Text('Tilang Berhasil Dicatat',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data pelanggaran telah tersimpan di Satlantas Polres Mojokerto dan langsung terdisposisi ke Guru BK sekolah bersangkutan.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.mark_email_read,
                          color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Notifikasi Instan telah dikirimkan ke Guru BK terkait.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (waSimUrl != null)
                TextButton.icon(
                  icon: const Icon(Icons.chat,
                      color: Color(0xFF10B981), size: 18),
                  label: const Text(
                    'Whatsapp',
                    style: TextStyle(
                        color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(waSimUrl);
                    bool launched = false;
                    try {
                      if (await canLaunchUrl(uri)) {
                        launched = await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {
                      launched = false;
                    }
                    if (!launched) {
                      try {
                        final phoneParam = uri.path.replaceAll('/', '');
                        final clean =
                            phoneParam.replaceAll(RegExp(r'[^0-9]'), '');
                        final telNum = clean.startsWith('62')
                            ? '0${clean.substring(2)}'
                            : clean;
                        final telUri = Uri.parse('tel:$telNum');
                        if (await canLaunchUrl(telUri)) {
                          await launchUrl(telUri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(telUri);
                        }
                      } catch (_) {}
                    }
                  },
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A3D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('SELESAI',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'Gagal mencatat penindakan: $errorMsg',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(policeSchoolsRadarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1322),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FLOATING HERO HEADER (Sesuai Gaya Tema Referensi Gambar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16233B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_document,
                          color: Color(0xFFFF8A3D),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Formulir Penindakan Pelajar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Entri Cepat Lapangan Satlantas Polres Mojokerto',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clickable Top-Right Profile Avatar
                      GestureDetector(
                        onTap: () {
                          ref.read(polriNavIndexProvider.notifier).state = 2;
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFF8A3D),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                final officer =
                                    ref.watch(authStateProvider).officer;
                                final name = officer?.fullName ?? 'PO';
                                final parts = name.trim().split(RegExp(r'\s+'));
                                final initials = parts.length >= 2
                                    ? '${parts[0][0]}${parts[1][0]}'
                                        .toUpperCase()
                                    : name
                                        .substring(0, name.length >= 2 ? 2 : 1)
                                        .toUpperCase();
                                return Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. CARD: ASAL SEKOLAH SISWA
                _buildCardContainer(
                  title: 'Asal Sekolah Siswa',
                  subtitle: 'Pilih dari 42 sekolah terdaftar di Mojokerto',
                  icon: Icons.school_outlined,
                  child: schoolsAsync.when(
                    loading: () => Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                          color: Color(0xFFFF8A3D), strokeWidth: 2),
                    ),
                    error: (e, _) => Text('Gagal: $e',
                        style: const TextStyle(color: Colors.redAccent)),
                    data: (schools) {
                      return InkWell(
                        onTap: () => _showSchoolSearchModal(schools),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A263D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedSchoolId != null
                                  ? const Color(0xFFFF8A3D)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.apartment_outlined,
                                color: _selectedSchoolId != null
                                    ? const Color(0xFFFF8A3D)
                                    : const Color(0xFF64748B),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedSchoolName ??
                                      'Klik untuk memilih asal sekolah...',
                                  style: TextStyle(
                                    color: _selectedSchoolName != null
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: _selectedSchoolName != null
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFFFF8A3D)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 3. CARD: IDENTITAS PELAJAR
                _buildCardContainer(
                  title: 'Identitas Pelajar',
                  subtitle: 'Nama lengkap dan jenjang kelas siswa',
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _studentNameCtrl,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1A263D),
                          hintText: 'Nama Lengkap Siswa (Contoh: Budi Santoso)',
                          hintStyle: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12),
                          prefixIcon: const Icon(Icons.badge_outlined,
                              color: Color(0xFF94A3B8), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF8A3D), width: 1.2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Nama siswa wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _studentClassCtrl,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1A263D),
                          hintText:
                              'Kelas / Jurusan (Contoh: X TKJ 1 / XII IPS)',
                          hintStyle: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12),
                          prefixIcon: const Icon(Icons.class_outlined,
                              color: Color(0xFF94A3B8), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF8A3D), width: 1.2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Kelas wajib diisi'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. CARD: KENDARAAN (NOMOR PLAT REGISTRASI BEBAS / LENGKAP)
                _buildCardContainer(
                  title: 'Kendaraan Bermotor',
                  subtitle: 'Nomor plat registrasi kendaraan',
                  icon: Icons.two_wheeler_outlined,
                  child: TextFormField(
                    controller: _plateCtrl,
                    autofocus: false,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Color(0xFFFF8A3D),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A263D),
                      hintText: 'Contoh: S 4521 NB / W 1234 AB',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(Icons.pin_outlined,
                          color: Color(0xFFFF8A3D), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFFFF8A3D), width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _plateCtrl.value = _plateCtrl.value.copyWith(
                          text: value.toUpperCase(),
                          selection:
                              TextSelection.collapsed(offset: value.length),
                        );
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nomor plat kendaraan wajib diisi';
                      }
                      if (v.trim().length < 3) {
                        return 'Format plat nomor terlalu pendek';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 5. CARD: PASAL PELANGGARAN LALU LINTAS (DIAMBIL DINAMIS DARI DATABASE)
                _buildCardContainer(
                  title: 'Pasal Pelanggaran Lalu Lintas',
                  subtitle:
                      '${_selectedViolationCodes.length} pasal dipilih • Sinkronisasi Database Polres',
                  icon: Icons.gavel_outlined,
                  child: ref.watch(violationMasterTypesProvider).when(
                        loading: () => Container(
                          height: 80,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                              color: Color(0xFFFF8A3D), strokeWidth: 2),
                        ),
                        error: (e, _) => Text('Gagal memuat pasal: $e',
                            style: const TextStyle(color: Colors.redAccent)),
                        data: (violationsList) {
                          return Column(
                            children: violationsList.map((v) {
                              final String code = (v['code'] ?? '').toString();
                              final String title =
                                  (v['title'] ?? '').toString();
                              final String article =
                                  (v['uu_llaj_article'] ?? v['article'] ?? '')
                                      .toString();
                              final dynamic rawFine =
                                  v['max_fine_idr'] ?? v['fine'];
                              final String fine = rawFine is num
                                  ? 'Rp ${rawFine.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                                  : (rawFine?.toString() ?? 'Rp 250.000');
                              final IconData icon = _getViolationIcon(code);
                              final Color accentColor =
                                  _getViolationColor(code);
                              final bool isChecked =
                                  _selectedViolationCodes.contains(code);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isChecked) {
                                        _selectedViolationCodes.remove(code);
                                      } else {
                                        _selectedViolationCodes.add(code);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? accentColor.withValues(alpha: 0.12)
                                          : const Color(0xFF1A263D),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isChecked
                                            ? accentColor
                                            : Colors.white
                                                .withValues(alpha: 0.05),
                                        width: isChecked ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(
                                                alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon,
                                              color: accentColor, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  color: isChecked
                                                      ? Colors.white
                                                      : const Color(0xFFCBD5E1),
                                                  fontSize: 13,
                                                  fontWeight: isChecked
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$article • Denda: $fine',
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isChecked
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isChecked
                                              ? accentColor
                                              : const Color(0xFF64748B),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                ),

                const SizedBox(height: 24),

                // 6. ACTION BUTTON: SIMPAN TILANG
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      shadowColor:
                          const Color(0xFFFF8A3D).withValues(alpha: 0.4),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'MENYIMPAN...' : 'SIMPAN TILANG',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitViolation,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141E30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF8A3D), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
