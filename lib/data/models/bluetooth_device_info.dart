/// Indica se [nome] é de um headset BrainLink. Os aparelhos anunciam
/// `BrainLink_Lite` e `BrainLink_pro`; a comparação ignora maiúsculas,
/// espaços, `_` e `-`.
bool ehNomeBrainLink(String nome) =>
    nome.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '').contains('brainlink');

/// Dispositivo encontrado pela descoberta Bluetooth Clássico do Android.
class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.isBonded,
  });

  final String name;
  final String address;
  final bool isBonded;

  factory BluetoothDeviceInfo.fromMap(Map<Object?, Object?> map) {
    return BluetoothDeviceInfo(
      name: map['name'] as String? ?? 'Dispositivo Bluetooth',
      address: map['address'] as String? ?? '',
      isBonded: map['bonded'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDeviceInfo && other.address == address;

  @override
  int get hashCode => address.hashCode;
}
