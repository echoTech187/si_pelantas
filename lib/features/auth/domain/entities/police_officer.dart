enum PoliceRole {
  polantas,    // Petugas Lantas Lapangan (Input Tilang Siswa)
  unitKamsel,  // Petugas Unit Kamsel (Radar Sekolah, Koordinasi WA/Telp BK, Input Evaluasi Penyuluhan)
}

class PoliceOfficer {
  final String id;
  final String nrp;
  final String username;
  final String fullName;
  final String rankTitle;
  final PoliceRole role;
  final String division;
  final String sectorArea;
  final String phoneWa;
  final String? photoUrl;

  const PoliceOfficer({
    required this.id,
    required this.nrp,
    required this.username,
    required this.fullName,
    required this.rankTitle,
    required this.role,
    required this.division,
    required this.sectorArea,
    required this.phoneWa,
    this.photoUrl,
  });

  PoliceOfficer copyWith({
    String? fullName,
    String? phoneWa,
    String? photoUrl,
  }) {
    return PoliceOfficer(
      id: id,
      nrp: nrp,
      username: username,
      fullName: fullName ?? this.fullName,
      rankTitle: rankTitle,
      role: role,
      division: division,
      sectorArea: sectorArea,
      phoneWa: phoneWa ?? this.phoneWa,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
