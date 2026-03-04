import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/review_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class ReviewDialog extends StatefulWidget {
  final String orderId;
  final String? serviceId;

  const ReviewDialog({super.key, required this.orderId, this.serviceId});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReviewCubit(),
      child: BlocConsumer<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('reviewSubmitted'.tr())));
            Navigator.pop(context, true);
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return AlertDialog(
            title: Text('rateService'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'howWasYourExperience'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: state is ReviewLoading
                    ? null
                    : () {
                        context.read<ReviewCubit>().submitReview(
                          orderId: widget.orderId,
                          serviceId: widget.serviceId,
                          rating: _rating,
                          comment: _commentController.text,
                        );
                      },
                child: state is ReviewLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('submit'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }
}
