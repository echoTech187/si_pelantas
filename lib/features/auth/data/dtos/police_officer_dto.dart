import '../../domain/entities/police_officer.dart';

class PoliceOfficerDto {
  final String id;
  final String nrp;
  final String username;
  final String fullName;
  final String rankTitle;
  final String roleRaw;
  final String division;
  final String sectorArea;
  final String phoneWa;
  final String? photoUrl;

  const PoliceOfficerDto({
    required this.id,
    required this.nrp,
    required this.username,
    required this.fullName,
    required this.rankTitle,
    required this.roleRaw,
    required this.division,
    required this.sectorArea,
    required this.phoneWa,
    this.photoUrl,
  });

  factory PoliceOfficerDto.fromJson(Map<String, dynamic> json) {
    return PoliceOfficerDto(
      id: json['id'] as String,
      nrp: json['nrp'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      rankTitle: json['rankTitle'] as String,
      roleRaw: json['role'] as String,
      division: json['division'] as String,
      sectorArea: json['sectorArea'] as String,
      phoneWa: json['phoneWa'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nrp': nrp,
        'username': username,
        'fullName': fullName,
        'rankTitle': rankTitle,
        'role': roleRaw,
        'division': division,
        'sectorArea': sectorArea,
        'phoneWa': phoneWa,
        'photoUrl': photoUrl,
      };

  PoliceOfficer toEntity() {
    return PoliceOfficer(
      id: id,
      nrp: nrp,
      username: username,
      fullName: fullName,
      rankTitle: rankTitle,
      role: roleRaw == 'UNIT_KAMSEL' ? PoliceRole.unitKamsel : PoliceRole.polantas,
      division: division,
      sectorArea: sectorArea,
      phoneWa: phoneWa,
      photoUrl: photoUrl,
    );
  }
}
