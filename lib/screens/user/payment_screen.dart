import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supa/cubits/payment_cubit.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/utils/haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final String? serviceName;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.orderId,
    this.serviceName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  String _selectedMethod = 'card';
  bool _isCardFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _shimmerController;

  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Card display values (masked)
  String _displayCardNumber = '**** **** **** ****';
  String _displayHolder = 'YOUR NAME';
  String _displayExpiry = 'MM/YY';

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _cardNumberController.addListener(_updateCardDisplay);
    _cardHolderController.addListener(_updateCardDisplay);
    _expiryController.addListener(_updateCardDisplay);
    _cvvController.addListener(_updateCvvDisplay);
  }

  void _updateCardDisplay() {
    setState(() {
      final raw = _cardNumberController.text.replaceAll(' ', '');
      if (raw.isEmpty) {
        _displayCardNumber = '**** **** **** ****';
      } else {
        final padded = raw.padRight(16, '*');
        _displayCardNumber =
            '${padded.substring(0, 4)} ${padded.substring(4, 8)} ${padded.substring(8, 12)} ${padded.substring(12, 16)}';
      }
      _displayHolder = _cardHolderController.text.isEmpty
          ? 'YOUR NAME'
          : _cardHolderController.text.toUpperCase();
      _displayExpiry = _expiryController.text.isEmpty
          ? 'MM/YY'
          : _expiryController.text;
    });
  }

  void _updateCvvDisplay() {
    if (!_isCardFlipped && _cvvController.text.isNotEmpty) {
      setState(() => _isCardFlipped = true);
      _flipController.forward();
    } else if (_isCardFlipped && _cvvController.text.isEmpty) {
      setState(() => _isCardFlipped = false);
      _flipController.reverse();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shimmerController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSuccess) {
              AppHaptics.success();
              _showSuccessScreen(context, state.transactionId);
            } else if (state is PaymentFailure) {
              AppHaptics.error();
              _showErrorSnackbar(context, state.error);
            }
          },
          builder: (context, state) {
            final isProcessing = state is PaymentProcessing;
            return Stack(
              children: [
                _buildBackground(),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBar(context),
                          const SizedBox(height: 8),
                          _buildAmountSection(),
                          const SizedBox(height: 28),
                          _buildPaymentMethodTabs(),
                          const SizedBox(height: 24),
                          if (_selectedMethod == 'card') ...[
                            _buildAnimatedCard(),
                            const SizedBox(height: 24),
                            _buildCardForm(),
                          ] else
                            _buildOneClickPayment(),
                          const SizedBox(height: 24),
                          _buildSecurityBadge(),
                          const SizedBox(height: 24),
                          _buildPayButton(context, state, isProcessing),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Deep base
          Container(color: const Color(0xFF0A0E21)),
          // Top glow
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom accent
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D2FF).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'checkout'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      children: [
        Text(
          widget.serviceName ?? 'totalAmount'.tr(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'TMT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.amount.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ],
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildPaymentMethodTabs() {
    final methods = [
      {'id': 'card', 'icon': Icons.credit_card_rounded, 'label': 'Card'},
      {'id': 'apple', 'icon': Icons.apple_rounded, 'label': 'Apple Pay'},
      {'id': 'google', 'icon': Icons.g_mobiledata_rounded, 'label': 'G Pay'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: methods.map((m) {
          final isSelected = _selectedMethod == m['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                AppHaptics.selection();
                setState(() => _selectedMethod = m['id'] as String);
              },
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15);
  }

  Widget _buildAnimatedCard() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isBack = _flipAnimation.value > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(math.pi * _flipAnimation.value),
          child: isBack ? _buildCardBack() : _buildCardFront(),
        );
      },
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _buildCardFront() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3AFF), Color(0xFF7B61FF), Color(0xFF00D2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3AFF).withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chip shimmer overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CardShimmerPainter(_shimmerController.value),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.contactless_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DEBIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _displayCardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                    fontFamily: 'Courier',
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARDHOLDER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayHolder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayExpiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3AFF).withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 45,
              color: Colors.black.withValues(alpha: 0.5),
              margin: const EdgeInsets.only(bottom: 20),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    'CVV',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 36,
                  margin: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _cvvController.text.isEmpty
                          ? '•••'
                          : '•' * _cvvController.text.length,
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        blur: 12,
        opacity: 0.06,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildFormField(
                controller: _cardNumberController,
                label: 'cardNumber'.tr(),
                hint: '0000 0000 0000 0000',
                icon: Icons.credit_card_rounded,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                  LengthLimitingTextInputFormatter(19),
                ],
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.replaceAll(' ', '').length < 16)
                    ? 'Enter valid card number'
                    : null,
              ),
              const SizedBox(height: 4),
              _buildFormField(
                controller: _cardHolderController,
                label: 'cardHolder'.tr(),
                hint: 'NAME SURNAME',
                icon: Icons.person_rounded,
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter cardholder name' : null,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      controller: _expiryController,
                      label: 'expiry'.tr(),
                      hint: 'MM/YY',
                      icon: Icons.calendar_today_rounded,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryDateFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.length < 5) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField(
                      controller: _cvvController,
                      label: 'CVС',
                      hint: '•••',
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.length < 3) ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.15),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildOneClickPayment() {
    final isApple = _selectedMethod == 'apple';
    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      blur: 12,
      opacity: 0.06,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isApple
                      ? [Colors.white, Colors.grey.shade200]
                      : [const Color(0xFF4285F4), const Color(0xFF34A853)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isApple ? Colors.white : const Color(0xFF4285F4))
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isApple ? Icons.apple_rounded : Icons.g_mobiledata_rounded,
                size: 40,
                color: isApple ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isApple ? 'Pay with Apple Pay' : 'Pay with Google Pay',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to authorize with Face ID or fingerprint',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'SSL Encrypted • PCI DSS Certified',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(
    BuildContext context,
    PaymentState state,
    bool isProcessing,
  ) {
    return GestureDetector(
      onTap: isProcessing
          ? null
          : () {
              if (_selectedMethod == 'card') {
                if (!_formKey.currentState!.validate()) return;
              }
              AppHaptics.medium();
              context.read<PaymentCubit>().processPayment(
                amount: widget.amount,
                orderId: widget.orderId,
                method: _selectedMethod,
              );
            },
      child: AnimatedContainer(
        duration: 300.ms,
        height: 60,
        decoration: BoxDecoration(
          gradient: isProcessing
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isProcessing ? Colors.white.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isProcessing
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.amount.toStringAsFixed(2)} TMT — ${'payNow'.tr()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2);
  }

  void _showErrorSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessScreen(BuildContext context, String txnId) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            _PaymentSuccessScreen(txnId: txnId, amount: widget.amount),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─── Card Number Formatter ───────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// ─── Expiry Date Formatter ──────────────────────────────────────
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}

// ─── Card Shimmer Painter ────────────────────────────────────────
class _CardShimmerPainter extends CustomPainter {
  final double progress;
  _CardShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerX = -size.width + (size.width * 2.5) * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.35, 0.5, 0.65],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(shimmerX, 0, size.width * 0.8, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_CardShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Success Screen ──────────────────────────────────────────────
class _PaymentSuccessScreen extends StatefulWidget {
  final String txnId;
  final double amount;
  const _PaymentSuccessScreen({required this.txnId, required this.amount});

  @override
  State<_PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<_PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          // Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(_particleController.value),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Success Icon
                        Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            )
                            .animate()
                            .scale(
                              begin: const Offset(0, 0),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(),
                        const SizedBox(height: 28),
                        Text(
                          'paymentSuccessful'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                        const SizedBox(height: 10),
                        Text(
                          'orderConfirmed'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ).animate(delay: 400.ms).fadeIn(),
                        const SizedBox(height: 36),
                        // Receipt Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              _receiptRow(
                                'amountPaid'.tr(),
                                '${widget.amount.toStringAsFixed(2)} TMT',
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _receiptRow('status'.tr(), 'confirmed'.tr()),
                              const Divider(color: Colors.white12, height: 24),
                              _receiptRow(
                                'transactionId'.tr(),
                                widget.txnId,
                                isCode: true,
                              ),
                            ],
                          ),
                        ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () {
                            AppHaptics.light();
                            Navigator.of(context)
                              ..pop()
                              ..pop();
                          },
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'backToHome'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: 650.ms).fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isCode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isCode ? const Color(0xFF6C63FF) : Colors.white,
            fontSize: isCode ? 12 : 14,
            fontWeight: FontWeight.w600,
            fontFamily: isCode ? 'Courier' : null,
          ),
        ),
      ],
    );
  }
}

// ─── Particle Painter ────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final List<_Particle> _particles = List.generate(40, (i) {
    final rng = math.Random(i * 7 + 13);
    return _Particle(
      x: rng.nextDouble(),
      yStart: 1.1 + rng.nextDouble() * 0.2,
      speed: 0.25 + rng.nextDouble() * 0.35,
      size: 3 + rng.nextDouble() * 5,
      color: [
        const Color(0xFF6C63FF),
        const Color(0xFF3B82F6),
        const Color(0xFF22C55E),
        const Color(0xFFF59E0B),
        Colors.pinkAccent,
      ][rng.nextInt(5)].withValues(alpha: 0.6 + rng.nextDouble() * 0.4),
      phase: rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase / (2 * math.pi)) % 1.0;
      final y = (p.yStart - t * 1.5) * size.height;
      if (y < -20) continue;
      final x = p.x * size.width + math.sin(t * math.pi * 3 + p.phase) * 30;
      paint.color = p.color.withValues(alpha: p.color.a * (1 - t * 0.6));
      canvas.drawCircle(Offset(x, y), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, yStart, speed, size, phase;
  final Color color;
  const _Particle({
    required this.x,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.color,
    required this.phase,
  });
}
