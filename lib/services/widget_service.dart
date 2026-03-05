import 'package:home_widget/home_widget.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/models/order_model.dart';

class WidgetService {
  static const String androidWidgetName = 'ReminderWidgetProvider';

  static Future<void> updateWidgetData({
    required String carModel,
    required String serviceInfo,
    required String status,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('car_model', carModel);
      await HomeWidget.saveWidgetData<String>('service_info', serviceInfo);
      await HomeWidget.saveWidgetData<String>('status', status);

      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  static Future<void> updateFromVehicles(
    List<Vehicle> vehicles,
    List<Order> orders,
  ) async {
    if (vehicles.isEmpty) return;

    final primaryVehicle = vehicles.first;
    final latestOrder = orders.isNotEmpty ? orders.first : null;

    String serviceInfo =
        'Next Service: ${((primaryVehicle.year ?? 2024) + 1) * 10000} km';
    String status = 'Healthy';

    if (latestOrder != null) {
      if (latestOrder.status == 'in_progress') {
        status = 'In Service';
        serviceInfo = latestOrder.carModel;
      } else if (latestOrder.status == 'pending') {
        status = 'Booked';
      }
    }

    await updateWidgetData(
      carModel: '${primaryVehicle.brand} ${primaryVehicle.model}',
      serviceInfo: serviceInfo,
      status: status,
    );
  }
}
