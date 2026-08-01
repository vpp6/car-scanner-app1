import '../models/coding.dart';
import '../models/device.dart';
import '../models/dtc.dart';
import '../models/vehicle.dart';

class MockData {
  MockData._();

  static const device = DeviceInfo(
    name: 'فاحص برو X1',
    model: 'FP-X1',
    serial: 'FPX100000123',
    firmware: 'v3.2.1',
    batteryLevel: 87,
    batteryCapacityMah: 18600,
    charging: false,
    canFdSupported: true,
    doipSupported: true,
    oscilloscope4ch: true,
    softwareVersion: 'v2.4.0',
    connectionMethod: ConnectionMethod.bluetooth,
  );

  static const vehicle = Vehicle(
    vin: 'LFV3A23K8B3078992',
    make: 'تويوتا',
    model: 'كورولا',
    year: 2021,
    engine: '2.0L Dynamic Force',
    fuel: 'بنزين',
    odometer: '54,230 كم',
    plate: 'أ ب ج 1234',
  );

  static const supportedMakes = [
    VehicleMake('تويوتا', ['كورولا', 'كامري', 'لاند كروزر', 'هايلكس']),
    VehicleMake('نيسان', ['صني', 'التيما', 'باترول', 'باثفايندر']),
    VehicleMake('هوندا', ['سيفيك', 'أكورد', 'CR-V']),
    VehicleMake('هيونداي', ['إلنترا', 'سوناتا', 'توسان']),
    VehicleMake('كيا', ['سيراتو', 'سبورتاج', 'سورينتو']),
    VehicleMake('مرسيدس', ['C-Class', 'E-Class', 'GLE']),
    VehicleMake('بي إم دبليو', ['الفئة الثالثة', 'الفئة الخامسة', 'X5']),
    VehicleMake('أودي', ['A3', 'A4', 'Q5']),
    VehicleMake('فولكس فاجن', ['غولف', 'باسات', 'تواريغ']),
    VehicleMake('جيمس', ['جي إم سي سييرا', 'شيفروليه تاهو']),
    VehicleMake('فورد', ['فوكس', 'مونديو', 'إكسبلورر']),
    VehicleMake('ميتسوبيشي', ['لانسر', 'أوتلاندر', 'باجيرو']),
    VehicleMake('سوزوكي', ['سويفت', 'فيتارا']),
    VehicleMake('مازدا', ['مازدا 3', 'مازدا 6', 'CX-5']),
    VehicleMake('رينو', ['لوجان', 'ميجان', 'داستر']),
    VehicleMake('بيجو', ['508', '3008']),
    VehicleMake('شيري', ['تيغو 7', 'أريزو 5']),
    VehicleMake('جاك', ['S3', 'T60']),
    VehicleMake('إم جي', ['ZS', 'HS']),
    VehicleMake('جيتور', ['T1', 'X70']),
    VehicleMake('كرايسلر', ['300C', '200', 'باسيفيكا', 'فوييجر']),
  ];

  static const vehicleSystems = [
    VehicleSystem(id: 'ecu', name: 'وحدة التحكم بالمحرك', icon: 'motor', supported: true),
    VehicleSystem(id: 'abs', name: 'المكابح ABS', icon: 'brake', supported: true),
    VehicleSystem(id: 'airbag', name: 'الوسائد الهوائية SRS', icon: 'shield', supported: true),
    VehicleSystem(id: 'tcm', name: 'ناقل الحركة', icon: 'gearbox', supported: true),
    VehicleSystem(id: 'bcm', name: 'جسم السيارة BCM', icon: 'car', supported: true),
    VehicleSystem(id: 'eps', name: 'التوجيه الكهربائي', icon: 'steering', supported: true),
    VehicleSystem(id: 'esp', name: 'ثبات المركبة ESP', icon: 'stability', supported: true),
    VehicleSystem(id: 'tpms', name: 'مراقبة ضغط الإطارات', icon: 'tire', supported: true),
    VehicleSystem(id: 'em', name: 'البنزين الكهربائية', icon: 'battery', supported: true),
    VehicleSystem(id: 'imm', name: 'نظام التشغيل الإلكتروني', icon: 'key', supported: true),
  ];

  static const scanReports = [
    ScanReport(system: 'المحرك ECU', icon: 'motor', codes: 2, status: ScanStatus.codes),
    ScanReport(system: 'المكابح ABS', icon: 'brake', codes: 0, status: ScanStatus.ok),
    ScanReport(system: 'الوسائد الهوائية', icon: 'shield', codes: 0, status: ScanStatus.ok),
    ScanReport(system: 'ناقل الحركة', icon: 'gearbox', codes: 1, status: ScanStatus.warning),
    ScanReport(system: 'جسم السيارة BCM', icon: 'car', codes: 0, status: ScanStatus.ok),
    ScanReport(system: 'التوجيه الكهربائي', icon: 'steering', codes: 0, status: ScanStatus.ok),
    ScanReport(system: 'ثبات المركبة ESP', icon: 'stability', codes: 0, status: ScanStatus.ok),
    ScanReport(system: 'ضغط الإطارات', icon: 'tire', codes: 1, status: ScanStatus.codes),
    ScanReport(system: 'البنزين الكهربائية', icon: 'battery', codes: 0, status: ScanStatus.noModule),
    ScanReport(system: 'التشغيل الإلكتروني', icon: 'key', codes: 0, status: ScanStatus.ok),
  ];

  static const dtcBySystem = {
    'وحدة التحكم بالمحرك': [
      DtcCode(
        code: 'P0171',
        description: 'الخليط فقير جداً - البنك 1',
        system: 'وحدة التحكم بالمحرك',
        severity: DtcSeverity.medium,
        frozen: true,
        occurrences: 3,
      ),
      DtcCode(
        code: 'P0420',
        description: 'كفاءة المحول الحفاز أقل من الحد الأدنى - البنك 1',
        system: 'وحدة التحكم بالمحرك',
        severity: DtcSeverity.medium,
        frozen: true,
      ),
    ],
    'ناقل الحركة': [
      DtcCode(
        code: 'P0700',
        description: 'عطل في نظام التحكم بناقل الحركة',
        system: 'ناقل الحركة',
        severity: DtcSeverity.high,
        frozen: false,
      ),
    ],
    'مراقبة ضغط الإطارات': [
      DtcCode(
        code: 'C2215',
        description: 'انخفاض ضغط الإطار الأيمن الأمامي',
        system: 'مراقبة ضغط الإطارات',
        severity: DtcSeverity.medium,
        frozen: false,
      ),
    ],
  };

  static const codingModules = [
    CodingModule(
      name: 'تحديث وحدات المحرك ECU',
      description: 'تحسين استهلاك الوقود واستجابة دواسة البنزين.',
      version: 'v2.8.4',
      size: '42 MB',
      offline: false,
    ),
    CodingModule(
      name: 'تفعيل مراقبة النقطة العمياء',
      description: 'تنشيط النظام من مصنع المركبة.',
      version: 'v1.2.0',
      size: '8 MB',
      offline: false,
    ),
    CodingModule(
      name: 'تحديث وحدة الوسائط',
      description: 'إصلاح مشاكل الاتصال وواجهة الوسائط.',
      version: 'v5.1.2',
      size: '96 MB',
      offline: false,
    ),
    CodingModule(
      name: 'معايرة مستشعرات المساعد الأمامي',
      description: 'إعادة معايرة الكاميرا بعد تغيير الزجاج الأمامي.',
      version: 'v1.0.1',
      size: '12 MB',
      offline: true,
    ),
  ];
}
