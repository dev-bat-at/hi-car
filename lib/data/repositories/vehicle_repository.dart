import '../models/vehicle_model.dart';
import '../services/api_service.dart';

class VehicleRepository {
  VehicleRepository._();
  static final VehicleRepository instance = VehicleRepository._();

  /// Gets list of assigned vehicles.
  Future<List<VehicleModel>> getVehicles() async {
    final rawList = await ApiService.instance.getVehicles();
    return rawList.map((e) => VehicleModel.fromJson(e)).toList();
  }

  /// Selects a vehicle to operate.
  Future<void> selectVehicle(int vehicleId) async {
    await ApiService.instance.selectVehicle(vehicleId);
  }

  /// Automated selection logic as per api.md Rule 2.3
  /// Returns the selected vehicle if auto-selected, null otherwise.
  Future<VehicleModel?> autoSelectIfOnlyOne() async {
    final vehicles = await getVehicles();
    if (vehicles.length == 1) {
      final vehicle = vehicles.first;
      await selectVehicle(vehicle.id);
      return vehicle;
    }
    return null;
  }
}
