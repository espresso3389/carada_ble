import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

enum _ScanResult {
  skip,
  found,
  stopScan,
}

Future<BluetoothDevice> _scan(_ScanResult Function(ScanResult) onDevice, {Duration timeout}) async {
  StreamSubscription<ScanResult> sub;
  try {
    await FlutterBlue.instance.stopScan(); // In case a scan is already running
    final comp = Completer<BluetoothDevice>();
    sub = FlutterBlue.instance.scan(timeout: timeout).listen((scanResult) {
      final code = onDevice(scanResult);
      if (code == _ScanResult.skip) {
        return;
      } else if (code == _ScanResult.found) {
        comp.complete(scanResult.device);
      } else {
        comp.complete(null);
      }
    },
    onError: (error) => comp.completeError(error));
    return await comp.future;
  } finally {
    await FlutterBlue.instance.stopScan();
    sub?.cancel();
  }
}

class CaradaData {
  final double weight;
  CaradaData({this.weight});

  static CaradaData fromBytes(List<int> data) {
    return CaradaData(
      weight: (data[6] * 256 + data[7]) / 10
    );
  }
}

class CaradaClient {
  static final CARADA_DATA = Guid('0000fff4-0000-1000-8000-00805f9b34fb');

  BluetoothDevice _device;
  BluetoothCharacteristic _dataChar;
  StreamSubscription<List<int>> _dataSub;
  PublishSubject<CaradaData> _pub;

  CaradaClient._();

  Future<void> _init(BluetoothDevice device) async {
    _device = device;
    await device.connect();
    final services = await device.discoverServices();
    _dataChar = _findCharacteristic(services: services, uuidChar: CARADA_DATA);
    _pub = PublishSubject<CaradaData>();
  }

  static Future<CaradaClient> discoverDevice({Duration timeout}) async {
    final device = await _scan((result) => result.device.name == 'TGF901-BT' ? _ScanResult.found : _ScanResult.skip);
    if (device == null) {
      return null;
    }
    final client = CaradaClient._();
    await client._init(device);
    return client;
  }

  Future<void> disconnect() async {
    stop();
    await _device?.disconnect();
    _device = null;
  }

  Stream<CaradaData> get stream => _pub.stream;

  Future<void> start() async {
    _dataChar.setNotifyValue(true);
    _dataSub = _dataChar.value.listen((data) {
      if (data.length == 11) {
        _pub.add(CaradaData.fromBytes(data));
      }
    });
  }

  void stop() {
    _dataSub?.cancel();
    _dataSub = null;
  }

  static BluetoothCharacteristic _findCharacteristic({@required List<BluetoothService> services, @required Guid uuidChar, Guid uuidService}) {
    if (uuidService != null) {
       return services.firstWhere((s) => s.uuid == uuidService, orElse: () => null)?.characteristics?.firstWhere((c) => c.uuid == uuidChar, orElse: () => null);
    }
    for (var s in services) {
      final char = s.characteristics.firstWhere((c) => c.uuid == uuidChar, orElse: () => null);
      if (char != null)
        return char;
    }
    return null;
  }
}