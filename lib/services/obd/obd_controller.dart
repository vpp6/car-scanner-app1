import '../../models/dtc.dart';
import 'obd_models.dart';

/// Common interface implemented by every diagnostic controller (ELM text
/// protocol over Bluetooth/CAN FD, UDS over DoIP, mocks).
abstract class ObdController {
  bool get connected;
  String get version;
  String get protocol;
  double get voltage;

  Future<void> open(ObdAdapter adapter);
  Future<void> close();

  Future<double> readVoltage();
  Future<double?> readPid(ObdPid pid);
  Future<List<DtcCode>> readDtc();
  Future<void> clearDtc();
  Future<String?> readVin();

  Stream<Map<ObdPid, double>> liveDataStream();
}
