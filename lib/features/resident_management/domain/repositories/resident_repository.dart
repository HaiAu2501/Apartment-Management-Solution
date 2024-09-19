import '../entities/resident.dart';

abstract class ResidentRepository {
  Future<List<ResidentEntity>> getResidents();
  Future<void> approveResident(String residentId);
}
