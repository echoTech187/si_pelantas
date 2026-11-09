import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/police_tactical_theme.dart';
import '../../../auth/domain/entities/police_officer.dart';
import 'polri_home_shell.dart';

class PoliceHomeDashboardView extends ConsumerWidget {
  final PoliceOfficer officer;
  final VoidCallback onNavigateToInput;

  const PoliceHomeDashboardView({
    super.key,
    required this.officer,
    required this.onNavigateToInput,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'PO';
    final cleaned = name
        .replaceAll(RegExp(r'\b(Bripka|Ipda|Aipda|Aiptu|Bripda|Briptu|Kompol|Akp|Iptu|S\.H\.|S\.Tr\.K\.|S\.Pd\.|M\.Pd\.|S\.Psi\.)\b', caseSensitive: false), '')
        .trim();
    final parts = (cleaned.isNotEmpty ? cleaned : name).trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPolantas = officer.role == PoliceRole.polantas;
    final String greeting = _getGreeting();
    final String initials = _getInitials(officer.fullName);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO BANNER WITH FLAT VECTOR ILLUSTRATION BACKGROUND
          Stack(
            children: [
              // Background Image with Rounded Bottom Corner
              Container(
                height: 270,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/hero_bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Gradient Overlay for smooth contrast
              Container(
                height: 270,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      const Color(0xFF0C1322).withValues(alpha: 0.2),
                      const Color(0xFF0C1322),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Header Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status badge & Toggle/Role indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'SISTEM AKTIF ONLINE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPolantas
                                      ? PoliceTacticalColors.electricCyan.withValues(alpha: 0.2)
                                      : PoliceTacticalColors.warningAmber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isPolantas
                                        ? PoliceTacticalColors.electricCyan
                                        : PoliceTacticalColors.warningAmber,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isPolantas ? 'POLANTAS' : 'UNIT KAMSEL',
                                  style: TextStyle(
                                    color: isPolantas
                                        ? PoliceTacticalColors.electricCyan
                                        : PoliceTacticalColors.warningAmber,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Top Right Initial-Name / Photo Profile Avatar
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
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Greeting & Name
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        officer.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // FLOATING HERO CARD (Matching reference image style)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16233B).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPolantas ? Icons.shield_outlined : Icons.radar_outlined,
                                color: const Color(0xFFFF8A3D),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isPolantas ? 'Kesatuan Penugasan' : 'Pusat Radar Pengawasan',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8A3D).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPolantas ? 'Fungsi Lantas' : 'Fungsi Kamsel',
                                          style: const TextStyle(
                                            color: Color(0xFFFF8A3D),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    officer.sectorArea.isNotEmpty
                                        ? officer.sectorArea
                                        : (isPolantas ? 'Satlantas Polres Mojokerto' : 'Unit Kamsel Satlantas Polres Mojokerto'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. QUICK ACTION / STATS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ringkasan Lapangan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isPolantas)
                      GestureDetector(
                        onTap: onNavigateToInput,
                        child: Row(
                          children: const [
                            Text(
                              'Input Tilang',
                              style: TextStyle(
                                color: Color(0xFFFF8A3D),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFFF8A3D)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Sekolah Terhubung',
                        value: '42 Sekolah',
                        subtitle: '18 Kecamatan',
                        icon: Icons.school_outlined,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Disposisi Terkirim',
                        value: '100% Realtime',
                        subtitle: 'Langsung ke Guru BK',
                        icon: Icons.send_outlined,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Primary Quick Action Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_task, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Penindakan Pelanggaran Siswa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Input data tilang siswa & otomatis kirim notifikasi ke sekolah asal',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onNavigateToInput,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8A3D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Common Violations Feed
                const Text(
                  'Fokus Prioritas Pelanggaran Pelajar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                _buildViolationTile(
                  title: 'Tanpa Helm SNI',
                  pasal: 'Pasal 291 Ayat (1) UU LLAJ',
                  icon: Icons.sports_motorsports_outlined,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 8),
                _buildViolationTile(
                  title: 'Knalpot Brong / Tidak Standar',
                  pasal: 'Pasal 285 Ayat (1) UU LLAJ',
                  icon: Icons.volume_up_outlined,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 8),
                _buildViolationTile(
                  title: 'Belum Cukup Umur / Tanpa SIM C',
                  pasal: 'Pasal 281 UU LLAJ',
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF8B5CF6),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141E30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationTile({
    required String title,
    required String pasal,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141E30).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  pasal,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi,';
    if (hour >= 11 && hour < 15) return 'Selamat Siang,';
    if (hour >= 15 && hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }
}

