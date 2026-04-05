import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:easy_localization/easy_localization.dart';

class VehicleServiceHistoryScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleServiceHistoryScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit()..fetchMyOrders(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${vehicle.brand} ${vehicle.model} History'),
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrdersLoaded) {
              final history = state.orders
                  .where(
                    (o) => o.vehicleId == vehicle.id && o.status == 'completed',
                  )
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OrderCubit>().fetchMyOrders();
                },
                child: history.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text('No service history yet'.tr()),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final order = history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.check, color: Colors.green),
                              ),
                              title: Text(order.carModel),
                              subtitle: Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(order.createdAt),
                              ),
                              trailing: Text(
                                order.totalPrice != null
                                    ? '${order.totalPrice!.toStringAsFixed(2)} TMT'
                                    : '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
