import 'package:flutter/material.dart';
import '../../domain/entities/resident.dart';
import '../../domain/usecases/get_residents_usecase.dart';
import '../../data/repositories/resident_repository_impl.dart';
import '../../data/datasources/resident_remote_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentProvider with ChangeNotifier {
  List<ResidentEntity> _residents = [];
  List<ResidentEntity> get residents => _residents;

  final GetResidentsUseCase getResidentsUseCase;
  final ResidentRepositoryImpl residentRepository;

  ResidentProvider()
      : residentRepository = ResidentRepositoryImpl(
          remoteDataSource: ResidentRemoteDataSourceImpl(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        getResidentsUseCase = GetResidentsUseCase(
          ResidentRepositoryImpl(
            remoteDataSource: ResidentRemoteDataSourceImpl(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        );

  Future<void> fetchResidents() async {
    _residents = await getResidentsUseCase();
    notifyListeners();
  }

  Future<void> approveResident(String residentId) async {
    await residentRepository.approveResident(residentId);
    await fetchResidents();
  }
}
