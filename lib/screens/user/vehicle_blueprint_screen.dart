import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/utils/haptics.dart';
import 'package:supa/screens/user/create_order_screen.dart';

class VehicleBlueprintScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleBlueprintScreen({super.key, required this.vehicle});

  @override
  State<VehicleBlueprintScreen> createState() => _VehicleBlueprintScreenState();
}

class _VehicleBlueprintScreenState extends State<VehicleBlueprintScreen> {
  // Mock data for vehicle health parts
  final List<_CarPartStatus> _parts = [
    _CarPartStatus(
      id: 'engine',
      name: 'Engine',
      description: 'Check oil level and filters.',
      status: PartStatus.warning,
      offset: const Offset(
        0.5,
        0.25,
      ), // Relative position on the car image (x, y)
    ),
    _CarPartStatus(
      id: 'brakes_front',
      name: 'Front Brakes',
      description: 'Brake pads are at 40%.',
      status: PartStatus.good,
      offset: const Offset(0.5, 0.45),
    ),
    _CarPartStatus(
      id: 'brakes_rear',
      name: 'Rear Brakes',
      description: 'Rear brake pads need replacement soon.',
      status: PartStatus.critical,
      offset: const Offset(0.5, 0.75),
    ),
    _CarPartStatus(
      id: 'battery',
      name: 'Battery',
      description: 'Battery health is optimal.',
      status: PartStatus.good,
      offset: const Offset(0.65, 0.28),
    ),
  ];

  void _showPartDetails(_CarPartStatus part) {
    AppHaptics.medium();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBottomSheet(part),
    );
  }

  Widget _buildBottomSheet(_CarPartStatus part) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: part.color.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(part.icon, color: part.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        part.statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: part.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              part.description,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withAlpha(200),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  AppHaptics.selection();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateOrderScreen(
                        preFillDescription:
                            'Check ${part.name.toLowerCase()}: ${part.description}',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: part.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Book Service',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Diagnostics',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withAlpha(isDark ? 50 : 20),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.vehicle.brand} ${widget.vehicle.model}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        widget.vehicle.licensePlate ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withAlpha(100)),
                    ),
                    child: const Text(
                      'System OK',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 2.5D Blueprint Area
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vector Car Silhouette representation
                  // In a real app this would be an SVG or 3D asset.
                  // For now, we build a stylized geometric representation.
                  _buildCarSilhouette(isDark),

                  // Hotspots overlay
                  ..._parts.map((part) => _buildHotspot(part)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarSilhouette(bool isDark) {
    return Container(
      width: 180,
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: const BorderRadius.all(Radius.elliptical(90, 200)),
        border: Border.all(
          color: isDark
              ? Colors.blueAccent.withAlpha(80)
              : Colors.blueAccent.withAlpha(40),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withAlpha(isDark ? 40 : 20),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Windshield
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black26,
                  width: 1,
                ),
              ),
            ),
          ),
          // Rear Window
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black26,
                  width: 1,
                ),
              ),
            ),
          ),
          // Roof grid pattern (tech feel)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _GridPainter(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspot(_CarPartStatus part) {
    // Convert relative offset (0.0 - 1.0) to absolute positioning within the stack
    // Assuming the car envelope is 180x400

    // We position relative to the center of the Stack
    return Align(
      alignment: Alignment(
        (part.offset.dx * 2) - 1, // Transform 0..1 to -1..1
        (part.offset.dy * 2) - 1,
      ),
      child: GestureDetector(
        onTap: () => _showPartDetails(part),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar aura
              Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: part.color.withAlpha(50),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.5, 1.5),
                    duration: 1500.ms,
                    curve: Curves.easeOut,
                  )
                  .fade(
                    begin: 1.0,
                    end: 0.0,
                    duration: 1500.ms,
                    curve: Curves.easeOut,
                  ),

              // Inner core
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: part.color,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: part.color.withAlpha(100),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data models for the blueprint
enum PartStatus { good, warning, critical }

class _CarPartStatus {
  final String id;
  final String name;
  final String description;
  final PartStatus status;
  final Offset offset;

  _CarPartStatus({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.offset,
  });

  Color get color {
    switch (status) {
      case PartStatus.good:
        return Colors.greenAccent;
      case PartStatus.warning:
        return Colors.orangeAccent;
      case PartStatus.critical:
        return Colors.redAccent;
    }
  }

  IconData get icon {
    switch (id) {
      case 'engine':
        return Icons.car_repair;
      case 'brakes_front':
      case 'brakes_rear':
        return Icons.radio_button_checked;
      case 'battery':
        return Icons.battery_charging_full;
      default:
        return Icons.settings;
    }
  }

  String get statusText {
    switch (status) {
      case PartStatus.good:
        return 'Optimal Condition';
      case PartStatus.warning:
        return 'Needs Attention Soon';
      case PartStatus.critical:
        return 'Action Required';
    }
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 20;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
