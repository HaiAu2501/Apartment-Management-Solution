import '../repositories/resident_repository.dart';
import '../entities/resident.dart';

class GetResidentsUseCase {
  final ResidentRepository repository;

  GetResidentsUseCase(this.repository);

  Future<List<ResidentEntity>> call() {
    return repository.getResidents();
  }
}
