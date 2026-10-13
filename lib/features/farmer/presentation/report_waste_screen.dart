import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportWasteScreen extends StatefulWidget {
  const ReportWasteScreen({super.key});

  @override
  State<ReportWasteScreen> createState() => _ReportWasteScreenState();
}

class _ReportWasteScreenState extends State<ReportWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();

  String? _wasteType;
  String? _unit;
  bool _loading = false;

  double? _latitude;
  double? _longitude;

  final List<String> _wasteTypes = [
    'Straw', 'Husk', 'Bagasse', 'Cotton Waste', 'Corn Residue', 'Sugarcane Waste', 'Other',
  ];
  final List<String> _units = ['kg', 'ton', 'quintal'];

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _show('Location permission denied', error: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      _mapController.move(LatLng(_latitude!, _longitude!), 15);
    } catch (e) {
      _show('Failed to get location: $e', error: true);
    }
  }

  Future<void> _submitWaste() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      _show('Please pin location on map', error: true);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _show('Please login again', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final quantity = double.parse(_quantityController.text.trim());

      await Supabase.instance.client.from('waste_listings').insert({
        'farmer_id': user.id,
        'waste_type': _wasteType,
        'crop_type': _cropController.text.trim(),
        'quantity': quantity,
        'available_quantity': quantity,
        'unit': _unit,
        'price_per_unit': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim().isEmpty
            ? _addressController.text.trim()
            : '${_descriptionController.text.trim()} | Address: ${_addressController.text.trim()}',
        'status': 'available',
        'latitude': _latitude,
        'longitude': _longitude,
      });

      if (!mounted) return;
      _show('Waste listed with pinned location!');
      Navigator.pop(context);
    } catch (e) {
      _show('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(_latitude ?? 28.6139, _longitude ?? 77.2090);

    return Scaffold(
      appBar: AppBar(title: const Text('List Agricultural Waste')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _wasteType,
                  decoration: const InputDecoration(
                    labelText: 'Waste Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.recycling),
                  ),
                  items: _wasteTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _loading ? null : (v) => setState(() => _wasteType = v),
                  validator: (v) => v == null ? 'Select waste type' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cropController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grass),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter crop type' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: _units
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: _loading ? null : (v) => setState(() => _unit = v),
                        validator: (v) => v == null ? 'Select' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price per Unit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Address (manual)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Farm / warehouse / company address',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Pin Location on Map (tap to place pin)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 240,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 13,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _latitude = point.latitude;
                            _longitude = point.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.agriwaste.platform',
                        ),
                        if (_latitude != null && _longitude != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_latitude!, _longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _latitude == null
                      ? 'No pin selected'
                      : 'Pinned: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submitWaste,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(_loading ? 'Listing...' : 'List Waste'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}