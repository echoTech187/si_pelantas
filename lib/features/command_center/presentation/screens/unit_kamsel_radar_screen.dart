import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/police_dio_client.dart';

const List<Map<String, dynamic>> _kFallbackMojokertoSchools = [];

final policeSchoolsRadarProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(policeDioClientProvider);
    final res = await dio.get('/schools');
    final List<dynamic> list = res.data['data'] as List<dynamic>;
    if (list.isNotEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    return _kFallbackMojokertoSchools;
  } catch (_) {
    return _kFallbackMojokertoSchools;
  }
});

class UnitKamselRadarScreen extends ConsumerStatefulWidget {
  const UnitKamselRadarScreen({super.key});

  @override
  ConsumerState<UnitKamselRadarScreen> createState() =>
      _UnitKamselRadarScreenState();
}

class _UnitKamselRadarScreenState extends ConsumerState<UnitKamselRadarScreen> {
  String _searchFilter = '';
  String _statusFilter = 'ALL';
  Timer? _pollingTimer;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Auto-refresh polling setiap 5 detik agar data radar selalu up-to-date
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(policeSchoolsRadarProvider);
      }
    });

    // 2. Real-time update instan begitu menerima push notifikasi FCM
    _fcmSubscription = FirebaseMessaging.onMessage.listen((_) {
      if (mounted) {
        ref.invalidate(policeSchoolsRadarProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  void _openWhatsAppCoordination(
      BuildContext context, Map<String, dynamic> school) async {
    final String rawPhone =
        (school['bkPhoneWa'] ?? school['phone'] ?? '').toString();
    final String cleanDigits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final String schoolName = school['schoolName'] ?? 'Sekolah';
    final int count = school['activeViolationCount'] ?? 0;
    final String officerRank = 'Unit Kamsel Satlantas Polres Mojokerto';

    if (cleanDigits.length < 5) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
          content: Text('Nomor kontak Guru BK $schoolName belum terdaftar.'),
        ),
      );
      return;
    }

    // Format nomor untuk WhatsApp (awalan 62) dan Telepon Biasa (awalan 0)
    final String waPhone = cleanDigits.startsWith('0')
        ? '62${cleanDigits.substring(1)}'
        : (cleanDigits.startsWith('62') ? cleanDigits : '62$cleanDigits');

    final String telPhone = cleanDigits.startsWith('62')
        ? '0${cleanDigits.substring(2)}'
        : (cleanDigits.startsWith('0') ? cleanDigits : '0$cleanDigits');

    final text = 'Selamat Pagi/Siang Bapak/Ibu Guru BK $schoolName,\n\n'
        'Kami dari $officerRank menginformasikan hasil radar pemantauan keselamatan pelajar: terdapat $count akumulasi tilang aktif siswa binaan.\n\n'
        'Mohon koordinasi penjadwalan bimbingan penyuluhan dan pembinaan tertib berlalu lintas di sekolah.\n\n'
        'Terima kasih.\n*Satlantas Polres Mojokerto - Presisi*';

    final Uri waNativeUri =
        Uri.parse('https://wa.me/$waPhone?text=${Uri.encodeComponent(text)}');
    final Uri telUri = Uri.parse('tel:$telPhone');

    bool waOpened = false;

    // 1. Coba hubungkan via WhatsApp
    try {
      if (await canLaunchUrl(waNativeUri)) {
        waOpened =
            await launchUrl(waNativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      waOpened = false;
    }

    // 2. Jika tidak bisa terhubung dengan WhatsApp -> buka panggilan telepon biasa
    if (!waOpened) {
      try {
        bool telOpened = false;
        if (await canLaunchUrl(telUri)) {
          telOpened =
              await launchUrl(telUri, mode: LaunchMode.externalApplication);
        } else {
          telOpened = await launchUrl(telUri);
        }

        if (context.mounted && telOpened) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              duration: const Duration(seconds: 3),
              content: Text(
                  'WhatsApp tidak terhubung. Mengalihkan ke panggilan telepon biasa ke $telPhone ($schoolName)...'),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
            content: Text('Gagal membuka panggilan telepon ke $telPhone: $e'),
          ),
        );
      }
    }
  }

  void _showCounselingDialog(
      BuildContext context, Map<String, dynamic> school) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0A0F1D),
        child: _CounselingFullscreenDialog(
          school: school,
          onSuccess: () {
            ref.invalidate(policeSchoolsRadarProvider);
          },
        ),
      ),
    );
  }

  String _formatIndonesianDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute WIB';
    } catch (_) {
      return rawDate;
    }
  }

  void _showSchoolViolationsDetailModal(
      BuildContext context, Map<String, dynamic> school) {
    final schoolId = school['schoolId'] ?? '';
    final schoolName = school['schoolName'] ?? 'Sekolah';
    final districtName = school['districtName'] ?? 'Mojokerto';
    final int count = school['activeViolationCount'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (sheetContext, scrollController) {
            return FutureBuilder(
              future: ref
                  .read(policeDioClientProvider)
                  .get('/schools/$schoolId/violations'),
              builder: (ctx, snapshot) {
                return Column(
                  children: [
                    // Handle drag bar
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kecamatan $districtName • Daftar Pelanggaran Siswa',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A3D)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFFF8A3D), width: 1),
                            ),
                            child: Text(
                              '$count Pelanggar',
                              style: const TextStyle(
                                color: Color(0xFFFF8A3D),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    // Body / List
                    Expanded(
                      child: () {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFF8A3D)),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Gagal memuat rincian: ${snapshot.error}',
                                style: const TextStyle(
                                    color: Color(0xFFEF4444), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data?.data;
                        final List<dynamic> list =
                            (data is Map && data['data'] is List)
                                ? (data['data'] as List<dynamic>)
                                : [];

                        if (list.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Belum ada data tilang pelajar yang tercatat untuk sekolah ini.',
                                style: TextStyle(
                                    color: Color(0xFF64748B), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (itemCtx, index) {
                            final v = list[index] as Map<String, dynamic>;
                            final String studentName =
                                v['studentName'] ?? 'Siswa';
                            final String studentClass =
                                v['studentClass'] ?? '-';
                            final String vehiclePlate =
                                (v['vehiclePlateNumber'] ??
                                        v['vehiclePlate'] ??
                                        '-')
                                    .toString();
                            final String vehicleBrandType = (v['vehicleType'] ??
                                    v['vehicle_brand_type'] ??
                                    v['vehicleBrandType'] ??
                                    '')
                                .toString();
                            final String violationSummary =
                                v['violationSummary'] ??
                                    'Pelanggaran Lalu Lintas';
                            final String incidentAt = v['incidentAt'] ?? '';
                            final String notes =
                                (v['officerNotes'] ?? '').toString();
                            final String officerName = (v['polantasOfficer'] ??
                                    v['polantasOfficerName'] ??
                                    'Petugas Polantas')
                                .toString();
                            final String formattedDate =
                                _formatIndonesianDate(incidentAt);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF162032),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.gavel_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Kelas: $studentClass',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 13, color: Color(0xFFFF8A3D)),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Color(0xFFFF8A3D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Detail Kendaraan: Plat Nomor & Keterangan Motor
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C1322),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFF8A3D)
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF8A3D)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            vehiclePlate,
                                            style: const TextStyle(
                                              color: Color(0xFFFF8A3D),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (vehicleBrandType.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.two_wheeler_outlined,
                                              size: 14,
                                              color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              vehicleBrandType,
                                              style: const TextStyle(
                                                color: Color(0xFFE2E8F0),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Jenis Pelanggaran
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PASAL / JENIS PELANGGARAN:',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          violationSummary,
                                          style: const TextStyle(
                                            color: Color(0xFFF1F5F9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.person_pin_outlined,
                                                size: 13,
                                                color: Color(0xFF38BDF8)),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                'Petugas Penindak: $officerName',
                                                style: const TextStyle(
                                                  color: Color(0xFF38BDF8),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Catatan: $notes',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSchoolInspectionHistoryModal(
      BuildContext context, Map<String, dynamic> school) {
    final schoolId = school['schoolId'] ?? '';
    final schoolName = school['schoolName'] ?? 'Sekolah';
    final districtName = school['districtName'] ?? 'Mojokerto';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (sheetContext, scrollController) {
            return FutureBuilder(
              future: ref
                  .read(policeDioClientProvider)
                  .get('/inspections/school/$schoolId'),
              builder: (ctx, snapshot) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Arsip Sidak & Ulasan Guru BK • $districtName',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF1E293B)),
                    Expanded(
                      child: () {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF38BDF8)),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Gagal memuat riwayat sidak:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFEF4444)),
                            ),
                          );
                        }

                        final data = (snapshot.data?.data
                            as Map<String, dynamic>?)?['data'];
                        final schoolInfo =
                            data?['school'] as Map<String, dynamic>? ?? {};
                        final inspections =
                            (data?['inspections'] as List<dynamic>?)
                                    ?.cast<Map<String, dynamic>>() ??
                                [];
                        final totalInspections =
                            schoolInfo['totalInspectionsCount'] ??
                                inspections.length;
                        final rawRating = schoolInfo['averageFeedbackRating'];
                        final double avgRating = rawRating is num
                            ? rawRating.toDouble()
                            : (double.tryParse(rawRating?.toString() ?? '0') ??
                                0.0);

                        if (inspections.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_edu_rounded,
                                      size: 52, color: Color(0xFF475569)),
                                  SizedBox(height: 12),
                                  Text(
                                    'Belum Ada Catatan Sidak',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Sekolah ini belum pernah dicatat pelaksanaan sidak atau penyuluhan oleh Unit Kamsel.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          children: [
                            // Summary Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '$totalInspections Kali',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Total Kunjungan Sidak',
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: Color(0xFFFBBF24),
                                              size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            avgRating > 0
                                                ? '${avgRating.toStringAsFixed(1)} / 5.0'
                                                : 'Belum Ada',
                                            style: const TextStyle(
                                                color: Color(0xFFFBBF24),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Rata-rata Rating Guru BK',
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...inspections.map((item) {
                              final seq = item['inspectionSequence'] ?? 1;
                              final date = _formatIndonesianDate(
                                  item['visitDate']?.toString());
                              final rawName =
                                  item['officerName'] ?? 'Unit Kamsel';
                              final officerRank =
                                  item['officerRank'] ?? 'Petugas';
                              final officerName = (officerRank.isNotEmpty &&
                                      rawName.toLowerCase().startsWith(
                                          officerRank.toLowerCase()))
                                  ? rawName
                                  : '$officerRank $rawName'.trim();
                              final officerNrp = item['officerNrp'] ?? '-';
                              final topic = item['counselingTopic'] ??
                                  'Penyuluhan Tertib Berlalu Lintas';
                              final directive =
                                  item['kamselDirectiveSummary'] ?? '-';
                              final evaluation =
                                  item['schoolEvaluationResult'] ?? '-';
                              final commitment =
                                  item['schoolFollowUpCommitment'] ?? '-';
                              final attendees =
                                  item['studentAttendeeCount'] ?? 0;
                              final violationCount =
                                  item['violationCountAtVisit'] ?? 0;
                              final feedbackId = item['feedbackId'];
                              final feedbackRating = item['feedbackRating'];
                              final feedbackNotes = item['feedbackNotes'];
                              final bkTeacherName =
                                  item['bkTeacherName'] ?? 'Guru BK';
                              final List violationsSnapshot =
                                  (item['violationsSnapshot'] as List?) ?? [];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141E30),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: feedbackId != null
                                        ? const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.3)
                                        : const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sidak Ke-$seq',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.badge_outlined,
                                            color: Color(0xFFFF8A3D), size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Petugas: ${officerRank.isNotEmpty && officerName.toLowerCase().startsWith(officerRank.toLowerCase()) ? officerName : "$officerRank $officerName".trim()} (NRP: $officerNrp)',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildInspectionDetailRow(
                                        'Materi/Topik:', topic),
                                    _buildInspectionDetailRow(
                                        'Arahan Kamsel:', directive),
                                    _buildInspectionDetailRow(
                                        'Evaluasi Sekolah:', evaluation),
                                    _buildInspectionDetailRow(
                                        'Komitmen Tindak Lanjut:', commitment),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Hadir: $attendees Siswa',
                                            style: const TextStyle(
                                                color: Color(0xFFE2E8F0),
                                                fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Pelanggar Saat Sidak: $violationCount',
                                            style: const TextStyle(
                                                color: Color(0xFFEF4444),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Snapshot Pelanggaran
                                    if (violationsSnapshot.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Snapshot Pelanggar Saat Sidak (${violationsSnapshot.length} Siswa):',
                                        style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 6),
                                      ...violationsSnapshot.take(5).map((v) {
                                        final name =
                                            v['studentName'] ?? 'Siswa';
                                        final sClass = v['studentClass'] ?? '-';
                                        final plate =
                                            v['vehiclePlateNumber'] ?? '-';
                                        final reason = v['violationSummary'] ??
                                            'Pelanggaran Lalu Lintas';
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '• $name ($sClass) • $plate • $reason',
                                            style: const TextStyle(
                                                color: Color(0xFFCBD5E1),
                                                fontSize: 10.5),
                                          ),
                                        );
                                      }),
                                    ],

                                    const SizedBox(height: 12),

                                    // Feedback BK Box
                                    if (feedbackId != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Penilaian Guru BK: $bkTeacherName',
                                                  style: const TextStyle(
                                                      color: Color(0xFF10B981),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      i < (feedbackRating ?? 5)
                                                          ? Icons.star_rounded
                                                          : Icons
                                                              .star_outline_rounded,
                                                      size: 15,
                                                      color: const Color(
                                                          0xFFFBBF24),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (feedbackNotes != null &&
                                                feedbackNotes
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '"$feedbackNotes"',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Menunggu ulasan/feedback dari Guru BK sekolah',
                                          style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      }(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInspectionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showKamselLeaderboardModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (sheetContext, scrollController) {
            return FutureBuilder(
              future:
                  ref.read(policeDioClientProvider).get('/kamsel/leaderboard'),
              builder: (ctx, snapshot) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFBBF24), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leaderboard Performa Kamsel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Peringkat Akumulasi Kepuasan Guru BK se-Mojokerto',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF1E293B)),
                    Expanded(
                      child: () {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFBBF24)),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Gagal memuat leaderboard:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFEF4444)),
                            ),
                          );
                        }

                        final data = (snapshot.data?.data
                            as Map<String, dynamic>?)?['data'];
                        final leaderboard =
                            (data?['leaderboard'] as List<dynamic>?)
                                    ?.cast<Map<String, dynamic>>() ??
                                [];
                        final recentFeedbacks =
                            (data?['recentFeedbacks'] as List<dynamic>?)
                                    ?.cast<Map<String, dynamic>>() ??
                                [];

                        if (leaderboard.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Belum ada data personel Kamsel atau penilaian.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        }

                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          children: [
                            const Text(
                              'PERINGKAT PERSONEL KAMSEL',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...leaderboard.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final item = entry.value;
                              final rawName =
                                  item['officerName'] ?? 'Personel Kamsel';
                              final rankTitle = (item['rankTitle'] ?? 'Petugas')
                                  .toString()
                                  .trim();
                              final officerName = (rankTitle.isNotEmpty &&
                                      rawName
                                          .toLowerCase()
                                          .startsWith(rankTitle.toLowerCase()))
                                  ? rawName
                                  : '$rankTitle $rawName'.trim();
                              final badgeNumber = item['badgeNumber'] ?? '-';
                              final totalInspections =
                                  item['totalInspections'] ?? 0;
                              final totalFeedbacks =
                                  item['totalFeedbacks'] ?? 0;
                              final double avgRating = item['averageRating']
                                      is num
                                  ? (item['averageRating'] as num).toDouble()
                                  : (double.tryParse(
                                          item['averageRating']?.toString() ??
                                              '0') ??
                                      0.0);
                              final double avgClarity =
                                  item['avgClarity'] is num
                                      ? (item['avgClarity'] as num).toDouble()
                                      : (double.tryParse(
                                              item['avgClarity']?.toString() ??
                                                  '0') ??
                                          0.0);
                              final double avgHelpfulness =
                                  item['avgHelpfulness'] is num
                                      ? (item['avgHelpfulness'] as num)
                                          .toDouble()
                                      : (double.tryParse(item['avgHelpfulness']
                                                  ?.toString() ??
                                              '0') ??
                                          0.0);
                              final double avgAttitude =
                                  item['avgAttitude'] is num
                                      ? (item['avgAttitude'] as num).toDouble()
                                      : (double.tryParse(
                                              item['avgAttitude']?.toString() ??
                                                  '0') ??
                                          0.0);

                              Color medalColor = const Color(0xFF64748B);
                              if (rank == 1) {
                                medalColor = const Color(0xFFFBBF24); // Gold
                              } else if (rank == 2) {
                                medalColor = const Color(0xFFE2E8F0); // Silver
                              } else if (rank == 3) {
                                medalColor = const Color(0xFFF97316); // Bronze
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141E30),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: rank == 1
                                        ? const Color(0xFFFBBF24)
                                            .withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: rank == 1 ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color:
                                            medalColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: medalColor, width: 1.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#$rank',
                                          style: TextStyle(
                                            color: medalColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            officerName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'NRP: $badgeNumber • $totalInspections Sekolah Dibina • $totalFeedbacks Ulasan',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _buildMiniPill(
                                                  'Materi: ${avgClarity > 0 ? avgClarity : '-'}⭐'),
                                              const SizedBox(width: 4),
                                              _buildMiniPill(
                                                  'Solusi: ${avgHelpfulness > 0 ? avgHelpfulness : '-'}⭐'),
                                              const SizedBox(width: 4),
                                              _buildMiniPill(
                                                  'Sikap: ${avgAttitude > 0 ? avgAttitude : '-'}⭐'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFFBBF24),
                                                size: 16),
                                            const SizedBox(width: 2),
                                            Text(
                                              avgRating > 0
                                                  ? '$avgRating'
                                                  : '-',
                                              style: const TextStyle(
                                                color: Color(0xFFFBBF24),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text(
                                          'Rating BK',
                                          style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 9.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (recentFeedbacks.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text(
                                'TESTIMONI & APRESIASI GURU BK TERBARU',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...recentFeedbacks.map((fb) {
                                final sName = fb['schoolName'] ?? 'Sekolah';
                                final teacher =
                                    fb['bkTeacherName'] ?? 'Guru BK';
                                final rawOfficer =
                                    fb['kamselOfficerName'] ?? 'Petugas Kamsel';
                                final officerRank =
                                    fb['kamselOfficerRank'] ?? '';
                                final officer =
                                    rawOfficer.startsWith(officerRank)
                                        ? rawOfficer
                                        : '$officerRank $rawOfficer';
                                final stars = fb['ratingStars'] ?? 5;
                                final notes = fb['feedbackNotes'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141E30),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.06)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$sName • $teacher',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              stars,
                                              (_) => const Icon(
                                                  Icons.star_rounded,
                                                  size: 13,
                                                  color: Color(0xFFFBBF24)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '"$notes"',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Untuk: $officer',
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        );
                      }(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMiniPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(policeSchoolsRadarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1322),
      body: SafeArea(
        child: Column(
          children: [
            // FLOATING HERO HEADER CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.radar,
                              color: Color(0xFFFF8A3D), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Radar Pemantauan 42 Sekolah',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Unit Kamsel Satlantas Polres Mojokerto',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFFFF8A3D), size: 22),
                          onPressed: () =>
                              ref.invalidate(policeSchoolsRadarProvider),
                          tooltip: 'Perbarui Radar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Siaga Pembinaan',
                                    style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('>= 5 Pelanggar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Wajib Kunjungan',
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('>= 7 Pelanggar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFFBBF24),
                          side: BorderSide(
                              color: const Color(0xFFFBBF24)
                                  .withValues(alpha: 0.4),
                              width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFFFBBF24), size: 18),
                        label: const Text(
                          'LEADERBOARD PERFORMA KAMSEL & ULASAN BK',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.3),
                        ),
                        onPressed: () => _showKamselLeaderboardModal(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SEARCH & FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari nama sekolah / kecamatan...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF141E30),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
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
                      onChanged: (v) =>
                          setState(() => _searchFilter = v.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: const Color(0xFF16233B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141E30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.tune,
                          color: Color(0xFFFF8A3D), size: 20),
                    ),
                    onSelected: (val) => setState(() => _statusFilter = val),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                          value: 'ALL',
                          child: Text('Semua Status',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12))),
                      const PopupMenuItem(
                          value: 'CRITICAL',
                          child: Text('Wajib Kunjungan (>= 7)',
                              style: TextStyle(
                                  color: Color(0xFFEF4444), fontSize: 12))),
                      const PopupMenuItem(
                          value: 'WARNING',
                          child: Text('Siaga (>= 5)',
                              style: TextStyle(
                                  color: Color(0xFFF59E0B), fontSize: 12))),
                      const PopupMenuItem(
                          value: 'SAFE',
                          child: Text('Aman (< 5)',
                              style: TextStyle(
                                  color: Color(0xFF10B981), fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // SCHOOL LIST
            Expanded(
              child: schoolsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8A3D)),
                ),
                error: (e, _) => Center(
                  child: Text('Gagal memuat radar: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                ),
                data: (schools) {
                  final filtered = schools.where((s) {
                    final name =
                        (s['schoolName'] ?? '').toString().toLowerCase();
                    final district =
                        (s['districtName'] ?? '').toString().toLowerCase();
                    final matchSearch = name.contains(_searchFilter) ||
                        district.contains(_searchFilter);

                    final count = s['activeViolationCount'] ?? 0;
                    if (!matchSearch) return false;
                    if (_statusFilter == 'CRITICAL') return count >= 7;
                    if (_statusFilter == 'WARNING') {
                      return count >= 5 && count < 7;
                    }
                    if (_statusFilter == 'SAFE') return count < 5;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada sekolah dengan filter ini.',
                          style: TextStyle(color: Color(0xFF64748B))),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final s = filtered[idx];
                      final count = s['activeViolationCount'] ?? 0;
                      final bool isCritical = count >= 7;
                      final bool isWarning = count >= 5 && count < 7;

                      Color statusColor = const Color(0xFF10B981);
                      String statusText = 'STATUS: AMAN';
                      if (isCritical) {
                        statusColor = const Color(0xFFEF4444);
                        statusText = 'WAJIB KUNJUNGAN PENYULUHAN (>= 7)';
                      } else if (isWarning) {
                        statusColor = const Color(0xFFF59E0B);
                        statusText = 'SIAGA PEMBINAAN (>= 5)';
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showSchoolViolationsDetailModal(context, s),
                          borderRadius: BorderRadius.circular(20),
                          splashColor:
                              const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                          highlightColor: Colors.white.withValues(alpha: 0.05),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141E30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCritical
                                    ? statusColor.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isCritical ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isCritical
                                            ? Icons.warning_amber_rounded
                                            : (isWarning
                                                ? Icons.info_outline
                                                : Icons.check_circle_outline),
                                        color: statusColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['schoolName'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${s['districtName']} • Guru BK: ${s['bkTeacherName']}',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: const Color(0xFF38BDF8)
                                                      .withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              'Sidak: ${s['totalInspectionsCount'] ?? 0} kali',
                                              style: const TextStyle(
                                                color: Color(0xFF38BDF8),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$count',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            'PELANGGAR',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Lihat Detail Siswa',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded,
                                              color: Color(0xFF94A3B8),
                                              size: 10),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF38BDF8),
                                          side: BorderSide(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.4)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.chat_outlined,
                                            size: 16),
                                        label: const Text('Koordinasi BK',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                        onPressed: () =>
                                            _openWhatsAppCoordination(
                                                context, s),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFFBBF24),
                                        side: BorderSide(
                                            color: const Color(0xFFFBBF24)
                                                .withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                      ),
                                      icon: const Icon(
                                          Icons.history_edu_rounded,
                                          size: 15),
                                      label: Text(
                                        'Riwayat (${s['totalInspectionsCount'] ?? 0})',
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () =>
                                          _showSchoolInspectionHistoryModal(
                                              context, s),
                                    ),
                                  ],
                                ),
                                if (isCritical || isWarning) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF8A3D),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      icon:
                                          const Icon(Icons.add_task, size: 16),
                                      label: const Text(
                                          'Catat Kunjungan & Beri Arahan',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800)),
                                      onPressed: () =>
                                          _showCounselingDialog(context, s),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounselingFullscreenDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> school;
  final VoidCallback onSuccess;

  const _CounselingFullscreenDialog({
    required this.school,
    required this.onSuccess,
  });

  @override
  ConsumerState<_CounselingFullscreenDialog> createState() =>
      _CounselingFullscreenDialogState();
}

class _CounselingFullscreenDialogState
    extends ConsumerState<_CounselingFullscreenDialog> {
  late final TextEditingController _materialsCtrl;
  late final TextEditingController _attendeeCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSubmitting = false;

  final List<String> _topicPresets = const [
    'Edukasi Helm SNI & Larangan Knalpot Brong',
    'Sosialisasi Keselamatan Pelajar (UU LLAJ No. 22/2009)',
    'Penyuluhan Tertib Rambu & Etika LLAJ',
    'Pembinaan Larangan Balap Liar & Modifikasi Liar',
  ];

  @override
  void initState() {
    super.initState();
    _materialsCtrl = TextEditingController(
        text: 'Edukasi Helm SNI & Larangan Knalpot Brong');
    _attendeeCtrl = TextEditingController(text: '150');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _materialsCtrl.dispose();
    _attendeeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final material = _materialsCtrl.text.trim();
    if (material.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Materi penyuluhan Kamsel wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(policeDioClientProvider);
      await dio.post('/kamsel/visits', data: {
        'schoolId': widget.school['schoolId'],
        'counselingTopics': material,
        'studentAttendeeCount': int.tryParse(_attendeeCtrl.text) ?? 100,
        'counselingNotes': _notesCtrl.text.trim(),
      });

      widget.onSuccess();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text(
                'Berita acara kunjungan berhasil disimpan! Siklus pelanggaran sekolah di-reset ke 0.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMsg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Gagal mencatat kunjungan kamsel: $errorMsg'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = widget.school['schoolName'] ?? 'Sekolah';
    final districtName = widget.school['districtName'] ?? 'Mojokerto';
    final activeCount = widget.school['activeViolationCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131D31),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Berita Acara Kunjungan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              schoolName,
              style: const TextStyle(
                color: Color(0xFFFF8A3D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E293B), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target School Summary Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school,
                          color: Color(0xFFFF8A3D), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kecamatan $districtName',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '$activeCount Pelanggar Aktif Terdeteksi',
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Materi Penyuluhan Label & Field
              const Text(
                'Materi Penyuluhan Kamsel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _materialsCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.menu_book_outlined,
                      color: Color(0xFFFF8A3D), size: 20),
                  hintText: 'Contoh: Edukasi Helm SNI & Larangan Knalpot Brong',
                  hintStyle:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF8A3D)),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Preset Topic Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _topicPresets.map((preset) {
                  final isSelected = _materialsCtrl.text == preset;
                  return ChoiceChip(
                    label: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor:
                        const Color(0xFFFF8A3D).withValues(alpha: 0.35),
                    backgroundColor: const Color(0xFF131D31),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFFF8A3D)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _materialsCtrl.text = preset;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Jumlah Siswa Hadir Label & Field
              const Text(
                'Jumlah Siswa Hadir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _attendeeCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.groups_outlined,
                      color: Color(0xFF38BDF8), size: 20),
                  suffixText: 'Siswa',
                  suffixStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Catatan Khusus Bimbingan Label & Field
              const Text(
                'Catatan Khusus Bimbingan & Tindak Lanjut',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.edit_note_outlined,
                        color: Color(0xFF10B981), size: 22),
                  ),
                  hintText:
                      'Tuliskan respon siswa, rekomendasi untuk pihak sekolah/BK, atau catatan penanganan khusus...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dampak Aksi Presisi (Info Callout)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.verified_user_outlined,
                        color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Menyimpan berita acara ini akan otomatis me-reset akumulasi siklus tilang aktif sekolah menjadi 0 (Kondisi Aman/Hijau) dan mengirimkan laporan digital langsung ke pihak Guru BK sekolah.',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF131D31),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A3D),
                  disabledBackgroundColor:
                      const Color(0xFFFF8A3D).withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'SIMPAN & RESET SIKLUS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
