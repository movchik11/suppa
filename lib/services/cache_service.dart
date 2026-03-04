import 'package:hive_flutter/hive_flutter.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String servicesBox = 'services';
  static const String ordersBox = 'orders';
  static const String vehiclesBox = 'vehicles';
  static const String profileBox = 'profile';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ServiceAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(VehicleAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OrderAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProfileAdapter());

    // Open Boxes
    await Hive.openBox<Service>(servicesBox);
    await Hive.openBox<Order>(ordersBox);
    await Hive.openBox<Vehicle>(vehiclesBox);
    await Hive.openBox<Profile>(profileBox);
  }

  // Generic methods
  static Future<void> cacheData<T>(String boxName, List<T> data) async {
    final box = Hive.box<T>(boxName);
    await box.clear();
    await box.addAll(data);
  }

  static List<T> getCachedData<T>(String boxName) {
    return Hive.box<T>(boxName).values.toList();
  }

  static Future<void> clearCache<T>(String boxName) async {
    await Hive.box<T>(boxName).clear();
  }

  static Future<void> cacheProfile(Profile profile) async {
    final box = Hive.box<Profile>(profileBox);
    await box.put('current_profile', profile);
  }

  static Profile? getCachedProfile() {
    return Hive.box<Profile>(profileBox).get('current_profile');
  }

  static Future<void> clearAll() async {
    await Hive.box<Service>(servicesBox).clear();
    await Hive.box<Order>(ordersBox).clear();
    await Hive.box<Vehicle>(vehiclesBox).clear();
    await Hive.box<Profile>(profileBox).clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('user_role_')) {
        await prefs.remove(key);
      }
    }
  }
}
