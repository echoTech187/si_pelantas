import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/police_dio_client.dart';
import 'auth_controller.dart';

class PoliceLoginScreen extends ConsumerStatefulWidget {
  const PoliceLoginScreen({super.key});

  @override
  ConsumerState<PoliceLoginScreen> createState() => _PoliceLoginScreenState();
}

class _PoliceLoginScreenState extends ConsumerState<PoliceLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nrpCtrl =
      TextEditingController(text: '89040123'); // Default NRP Polantas
  final _passwordCtrl = TextEditingController(text: 'polri123');
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1322),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Korlantas Lalu Lintas Resmi
                  Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/korlantas_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'SI-PELANTAS POLRI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFFFF8A3D).withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'SATLANTAS POLRES MOJOKERTO',
                      style: TextStyle(
                        color: Color(0xFFFF8A3D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Portal Otentikasi Penindakan & Unit Kamsel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E30),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.badge_outlined,
                                color: Color(0xFFFF8A3D), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'AUTENTIKASI PRESISI ANGGOTA POLRI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Input NRP Only
                        TextFormField(
                          controller: _nrpCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'NRP Anggota Polri',
                            labelStyle: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12),
                            hintText: 'Masukkan 8 digit NRP (Contoh: 89040123)',
                            hintStyle: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 12),
                            prefixIcon: const Icon(Icons.numbers_outlined,
                                color: Color(0xFFFF8A3D), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF1A263D),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'NRP wajib diisi';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                              return 'NRP harus berupa angka nomor registrasi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Input Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Dinas',
                            labelStyle: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(0xFFFF8A3D), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A263D),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                          validator: (v) => (v == null || v.length < 4)
                              ? 'Kata sandi minimal 4 karakter'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Error Message
                        if (authState.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      ref
                                          .read(authStateProvider.notifier)
                                          .login(
                                            _nrpCtrl.text.trim(),
                                            _passwordCtrl.text,
                                          );
                                    }
                                  },
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'MASUK',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Demo NRP quick-fill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E30).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AKSES TUGAS SATLANTAS POLRES MOJOKERTO:',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _nrpCtrl.text == '89040123'
                                        ? const Color(0xFFFF8A3D)
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                  backgroundColor: _nrpCtrl.text == '89040123'
                                      ? const Color(0xFFFF8A3D)
                                          .withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _nrpCtrl.text = '89040123';
                                    _passwordCtrl.text = 'polri123';
                                  });
                                },
                                child: Column(
                                  children: const [
                                    Text('UNIT TURJAWALI (GAKKUM)',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                    Text('NRP: 89040123',
                                        style: TextStyle(
                                            color: Color(0xFFFF8A3D),
                                            fontSize: 9.5)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _nrpCtrl.text == '94080511'
                                        ? const Color(0xFFFF8A3D)
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                  backgroundColor: _nrpCtrl.text == '94080511'
                                      ? const Color(0xFFFF8A3D)
                                          .withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _nrpCtrl.text = '94080511';
                                    _passwordCtrl.text = 'polri123';
                                  });
                                },
                                child: Column(
                                  children: const [
                                    Text('UNIT KAMSEL (DIKYASA)',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                    Text('NRP: 94080511',
                                        style: TextStyle(
                                            color: Color(0xFFFF8A3D),
                                            fontSize: 9.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Pengaturan Server IP
                  Consumer(
                    builder: (context, ref, _) {
                      final serverUrl = ref.watch(policeServerBaseUrlProvider);
                      final displayUrl =
                          serverUrl.replaceAll('/api/v1/police', '');
                      return TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                        ),
                        icon: const Icon(Icons.dns_rounded,
                            size: 14, color: Color(0xFFFF8A3D)),
                        label: Text(
                          'Server: $displayUrl',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        onPressed: () =>
                            _showServerConfigDialog(context, ref, serverUrl),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServerConfigDialog(
      BuildContext context, WidgetRef ref, String currentUrl) {
    final ctrl = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFFFF8A3D), size: 22),
            SizedBox(width: 10),
            Text('Pengaturan Server API',
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
              'Alamat IP server backend laptop Anda:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0C1322),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                hintText: 'http://192.168.1.52:4000/api/v1/police',
                hintStyle:
                    const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Preset Cepat:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip(ctrl, '☁️ Vercel Cloud (Prod)',
                    'https://si-pelantas-open-api.vercel.app/api/v1/police'),
                _buildPresetChip(ctrl, 'Wi-Fi Laptop (Dev)',
                    'http://192.168.1.52:4000/api/v1/police'),
                _buildPresetChip(ctrl, 'USB (Reverse)',
                    'http://localhost:4000/api/v1/police'),
                _buildPresetChip(
                    ctrl, 'Emulator', 'http://10.0.2.2:4000/api/v1/police'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newUrl = ctrl.text.trim();
              if (newUrl.isNotEmpty) {
                ref
                    .read(policeServerBaseUrlProvider.notifier)
                    .setBaseUrl(newUrl);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
      TextEditingController ctrl, String label, String url) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 10.5, color: Colors.white)),
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      onPressed: () => ctrl.text = url,
    );
  }
}
