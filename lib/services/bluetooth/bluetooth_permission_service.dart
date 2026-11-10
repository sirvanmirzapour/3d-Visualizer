import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

enum BluetoothReadiness {
  unsupported,
  disabled,
  permissionDenied,
  permissionPermanentlyDenied,
  locationRequired,
  ready,
}

class BluetoothPermissionState {
  final bool supported;
  final bool enabled;
  final BtcPermissionStatus permissionStatus;
  final bool locationServiceRequired;
  final bool locationServiceEnabled;
  final BluetoothReadiness readiness;
  final String message;

  const BluetoothPermissionState({
    required this.supported,
    required this.enabled,
    required this.permissionStatus,
    required this.locationServiceRequired,
    required this.locationServiceEnabled,
    required this.readiness,
    required this.message,
  });

  bool get canScan => readiness == BluetoothReadiness.ready;

  factory BluetoothPermissionState.initial() => const BluetoothPermissionState(
        supported: false,
        enabled: false,
        permissionStatus: BtcPermissionStatus.denied,
        locationServiceRequired: false,
        locationServiceEnabled: true,
        readiness: BluetoothReadiness.disabled,
        message: 'Checking Bluetooth status...',
      );
}

class BluetoothPermissionService {
  BluetoothPermissionService([FlutterClassicBluetooth? bluetooth])
      : _bluetooth = bluetooth ?? FlutterClassicBluetooth();

  final FlutterClassicBluetooth _bluetooth;

  static const Set<BtcPermission> _scanPermissions = {
    BtcPermission.scan,
    BtcPermission.connect,
  };

  Future<BluetoothPermissionState> evaluate() async {
    try {
      final supported = await _bluetooth.isSupported();
      if (!supported) {
        return const BluetoothPermissionState(
          supported: false,
          enabled: false,
          permissionStatus: BtcPermissionStatus.notRequired,
          locationServiceRequired: false,
          locationServiceEnabled: true,
          readiness: BluetoothReadiness.unsupported,
          message: 'This device does not support Bluetooth.',
        );
      }

      final enabled = await _bluetooth.isEnabled();
      final permissionStatus =
          await _bluetooth.checkPermissions(permissions: _scanPermissions);
      final locationServiceRequired =
          await _bluetooth.isLocationServiceRequired();
      final locationServiceEnabled =
          await _bluetooth.isLocationServiceEnabled();

      return _buildState(
        supported: supported,
        enabled: enabled,
        permissionStatus: permissionStatus,
        locationServiceRequired: locationServiceRequired,
        locationServiceEnabled: locationServiceEnabled,
      );
    } catch (e) {
      return BluetoothPermissionState(
        supported: false,
        enabled: false,
        permissionStatus: BtcPermissionStatus.denied,
        locationServiceRequired: false,
        locationServiceEnabled: true,
        readiness: BluetoothReadiness.disabled,
        message: 'Unable to read Bluetooth status: $e',
      );
    }
  }

  Future<BluetoothPermissionState> requestPermissions() async {
    try {
      await _bluetooth.requestPermissions(permissions: _scanPermissions);
    } catch (_) {
      // State is re-evaluated below to reflect the actual outcome.
    }
    return evaluate();
  }

  Future<bool> enableBluetooth() async {
    try {
      return await _bluetooth.enableBluetooth();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await _bluetooth.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await _bluetooth.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Stream<BtcAdapterState> adapterState() => _bluetooth.adapterState;

  BluetoothPermissionState _buildState({
    required bool supported,
    required bool enabled,
    required BtcPermissionStatus permissionStatus,
    required bool locationServiceRequired,
    required bool locationServiceEnabled,
  }) {
    if (!enabled) {
      return BluetoothPermissionState(
        supported: supported,
        enabled: false,
        permissionStatus: permissionStatus,
        locationServiceRequired: locationServiceRequired,
        locationServiceEnabled: locationServiceEnabled,
        readiness: BluetoothReadiness.disabled,
        message: 'Bluetooth is turned off. Turn it on to scan for devices.',
      );
    }

    if (permissionStatus == BtcPermissionStatus.permanentlyDenied) {
      return BluetoothPermissionState(
        supported: supported,
        enabled: enabled,
        permissionStatus: permissionStatus,
        locationServiceRequired: locationServiceRequired,
        locationServiceEnabled: locationServiceEnabled,
        readiness: BluetoothReadiness.permissionPermanentlyDenied,
        message:
            'Bluetooth permission was permanently denied. Open app settings to grant access.',
      );
    }

    if (permissionStatus == BtcPermissionStatus.denied) {
      return BluetoothPermissionState(
        supported: supported,
        enabled: enabled,
        permissionStatus: permissionStatus,
        locationServiceRequired: locationServiceRequired,
        locationServiceEnabled: locationServiceEnabled,
        readiness: BluetoothReadiness.permissionDenied,
        message:
            'Bluetooth permission is required to scan and connect to devices.',
      );
    }

    if (locationServiceRequired && !locationServiceEnabled) {
      return BluetoothPermissionState(
        supported: supported,
        enabled: enabled,
        permissionStatus: permissionStatus,
        locationServiceRequired: locationServiceRequired,
        locationServiceEnabled: locationServiceEnabled,
        readiness: BluetoothReadiness.locationRequired,
        message:
            'Location services must be turned on for Bluetooth discovery on this Android version.',
      );
    }

    return BluetoothPermissionState(
      supported: supported,
      enabled: enabled,
      permissionStatus: permissionStatus,
      locationServiceRequired: locationServiceRequired,
      locationServiceEnabled: locationServiceEnabled,
      readiness: BluetoothReadiness.ready,
      message: 'Bluetooth is ready. Device discovery will be enabled in Step 3.',
    );
  }
}
