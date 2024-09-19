import '../../domain/entities/resident.dart';
import '../../domain/repositories/resident_repository.dart';
import '../datasources/resident_remote_data_source.dart';

class ResidentRepositoryImpl implements ResidentRepository {
  final ResidentRemoteDataSource remoteDataSource;

  ResidentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ResidentEntity>> getResidents() {
    return remoteDataSource.getResidents();
  }

  @override
  Future<void> approveResident(String residentId) {
    return remoteDataSource.approveResident(residentId);
  }
}
