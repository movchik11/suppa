import 'package:hive_flutter/hive_flutter.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supa/models/expense_model.dart';
import 'package:supa/models/document_model.dart';
import 'package:supa/models/review_model.dart';
import 'package:supa/cubits/gemini_chat_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String servicesBox = 'services';
  static const String ordersBox = 'orders';
  static const String vehiclesBox = 'vehicles';
  static const String profileBox = 'profile';
  static const String chatBox = 'chat_history';
  static const String expensesBox = 'expenses';
  static const String documentsBox = 'documents';
  static const String reviewsBox = 'reviews';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ServiceAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(VehicleAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OrderAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProfileAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(ChatMessageAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(VehicleDocumentAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(ReviewAdapter());

    // Open Boxes
    await Hive.openBox<Service>(servicesBox);
    await Hive.openBox<Order>(ordersBox);
    await Hive.openBox<Vehicle>(vehiclesBox);
    await Hive.openBox<Profile>(profileBox);
    await Hive.openBox<ChatMessage>(chatBox);
    await Hive.openBox<Expense>(expensesBox);
    await Hive.openBox<VehicleDocument>(documentsBox);
    await Hive.openBox<Review>(reviewsBox);
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
    await Hive.box<ChatMessage>(chatBox).clear();
    await Hive.box<Expense>(expensesBox).clear();
    await Hive.box<VehicleDocument>(documentsBox).clear();
    await Hive.box<Review>(reviewsBox).clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('user_role_')) {
        await prefs.remove(key);
      }
    }
  }
}
