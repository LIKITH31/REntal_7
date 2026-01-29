
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MockPaymentGatewayDialog extends StatefulWidget {
  final double amount;
  final int paymentMethodIndex; // 0: Card, 1: UPI, 2: Scan, 3: Netbanking, 4: Wallets
  final VoidCallback onSuccess;

  const MockPaymentGatewayDialog({
    super.key, 
    required this.amount, 
    required this.paymentMethodIndex,
    required this.onSuccess
  });

  @override
  State<MockPaymentGatewayDialog> createState() => _MockPaymentGatewayDialogState();
}

class _MockPaymentGatewayDialogState extends State<MockPaymentGatewayDialog> {
  // 0: Selection (though we pass index, we can allow switching), 1: Processing, 2: Success
  // Actually, we are passed an index, but a real gateway lets you switch.
  // Let's stick to the passed index for the primary view, but style it like an active payment session.
  int _state = 0; 
  int _currentMethod = 0; 

  // Razorpay-like Theme Colors
  final Color themeColor = const Color(0xFF3395FF); // Razorpay Blue
  final Color darkHeader = const Color(0xFF092646); // Razorpay Dark

  // Controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedBank;
  final List<String> _banks = ['HDFC Bank', 'SBI', 'ICICI Bank', 'Axis Bank', 'Kotak Bank'];

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.paymentMethodIndex;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _upiController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _fillTestDetails() {
    if (_currentMethod == 0) { // Card
      _cardNumberController.text = '4242 4242 4242 4242';
      _expiryController.text = '12/28';
      _cvvController.text = '123';
    } else if (_currentMethod == 1) { // UPI
      _upiController.text = 'success@upi';
    }
    setState(() {});
  }

  Future<void> _processPayment() async {
    // Basic Validation
    if (_currentMethod == 0) {
       if (_cardNumberController.text.length < 10) return _snack('Invalid Card Number');
    } else if (_currentMethod == 1) {
       if (_upiController.text.length < 3) return _snack('Invalid UPI ID');
    } else if (_currentMethod == 2) {
       // QR Code scan - no input validation needed
    } else if (_currentMethod == 3) {
      if (_selectedBank == null) return _snack('Select a Bank');
    }

    setState(() => _state = 1); // Loading
    
    // Simulate finding bank / connecting
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // For Card/Netbanking, we usually show OTP. For UPI, we show "Approve on Phone".
    // Let's unify it into a "Verifying" step for simplicity or a specific OTP step.
    // Razorpay often shows a popup within a popup for OTP.
    // We will switch state to '2' (OTP/Wait)
    
    setState(() => _state = 2);
  }
  
  Future<void> _verifyOtpOrApproval() async {
     // Validate OTP if applicable
     if (_currentMethod != 1 && _currentMethod != 2) {
        if (_otpController.text.length < 4) return _snack('Enter valid OTP');
     }

     setState(() => _state = 3); // Final Processing
     await Future.delayed(const Duration(seconds: 2));
     if (!mounted) return;
     
     setState(() => _state = 4); // Success Tick
     await Future.delayed(const Duration(seconds: 1));
     if (!mounted) return;
     
     Navigator.pop(context);
     widget.onSuccess();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m), 
      backgroundColor: Colors.redAccent, 
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 20, right: 20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4), // Razorpay is slightly sharper
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              
              if (_state == 0)
                Expanded(child: SingleChildScrollView(child: _buildInputForm())),
              if (_state == 1)
                const Expanded(child: Center(child: CircularProgressIndicator())),
              if (_state == 2)
                 Expanded(child: SingleChildScrollView(child: _buildOtpOrWaitScreen())),
              if (_state == 3)
                const Expanded(child: Center(child: CircularProgressIndicator())),
              if (_state == 4)
                Expanded(child: _buildSuccessScreen()),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: darkHeader,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4)
            ),
            child: const Text('TEST MODE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          const Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text('RazorTech Gateway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Trusted by RentalApp', style: TextStyle(color: Colors.white54, fontSize: 11)),
             ],
          ),
          const Spacer(),
          Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                Text('₹${widget.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('English', style: TextStyle(color: Colors.white54, fontSize: 11)),
             ],
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.grey[50], 
      child: Row(
        children: [
           // Can allow switching methods here if we wanted
           const Icon(Icons.lock, size: 12, color: Colors.grey),
           const SizedBox(width: 4),
           const Text('Secured by RazorTech', style: TextStyle(fontSize: 10, color: Colors.grey)),
           const Spacer(),
           if (_state == 0)
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12)),
             )
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    // Razorpay style: Method selection on left (desktop) or just form (mobile).
    // Simulating the "Selected Method" view.
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method Title with Change option
          Row(
            children: [
               _getMethodIcon(_currentMethod),
               const SizedBox(width: 12),
               Text(
                 _getMethodName(_currentMethod), 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
               ),
            ],
          ),
          const Divider(height: 32),
          
          if (_currentMethod == 0) ...[
             // Card
             _buildLabel('Card Number'),
             TextField(
               controller: _cardNumberController,
               decoration: _inputDeco('0000 0000 0000 0000', icon: Icons.credit_card),
               keyboardType: TextInputType.number,
               inputFormatters: [
                 LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
                 _CardNumberFormatter(),
               ],
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildLabel('Expiry'),
                     TextField(
                       controller: _expiryController, 
                       decoration: _inputDeco('MM/YY'),
                       keyboardType: TextInputType.number,
                       inputFormatters: [
                         LengthLimitingTextInputFormatter(5),
                         _ExpiryDateFormatter(),
                       ],
                     ),
                   ],
                 )),
                 const SizedBox(width: 16),
                 Expanded(child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildLabel('CVV'),
                     TextField(controller: _cvvController, obscureText: true, decoration: _inputDeco('123')),
                   ],
                 )),
               ],
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                 Checkbox(value: true, onChanged: (_){}, activeColor: themeColor),
                 const Text('Save card securely for future payments', style: TextStyle(fontSize: 12)),
               ],
             ),

          ] else if (_currentMethod == 1) ...[
             // UPI
             _buildLabel('Enter UPI ID'),
             TextField(
               controller: _upiController,
               decoration: _inputDeco('example@okhdfcbank'),
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
               child: const Row(
                 children: [
                   Icon(Icons.info_outline, size: 16, color: Colors.blue),
                   SizedBox(width: 8),
                   Expanded(child: Text('A collect request will be sent to your UPI app.', style: TextStyle(fontSize: 11, color: Colors.blue))),
                 ],
               ),
             ),

          ] else if (_currentMethod == 2) ...[
             // QR Code
             Center(
               child: Column(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       border: Border.all(color: Colors.grey[200]!),
                       borderRadius: BorderRadius.circular(8),
                       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
                     ),
                     child: Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=upi://pay',
                        height: 160, width: 160,
                        errorBuilder: (_,__,___) => const Icon(Icons.qr_code_2, size: 160),
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Text('Scan with any UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             
          ] else if (_currentMethod == 3) ...[
             // Netbanking
             _buildLabel('Select Bank'),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!),
                 borderRadius: BorderRadius.circular(4)
               ),
               child: DropdownButtonHideUnderline(
                 child: DropdownButton<String>(
                   isExpanded: true,
                   value: _selectedBank,
                   hint: const Text('Choose a Bank...'),
                   items: _banks.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                   onChanged: (v) => setState(() => _selectedBank = v),
                 ),
               ),
             ),
          ] else ...[
             const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Redirecting to external wallet...'))),
          ],
          
          const SizedBox(height: 24),
          
          // Test Data Helper
          GestureDetector(
            onTap: _fillTestDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: const Text('Use Test Data', style: TextStyle(fontSize: 10, color: Colors.black54)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
              ),
              child: Text(
                'Pay ₹${widget.amount.toStringAsFixed(2)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOtpOrWaitScreen() {
    final bool isUpi = _currentMethod == 1 || _currentMethod == 2;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
           Icon(isUpi ? Icons.mobile_friendly : Icons.lock_clock, size: 64, color: themeColor),
           const SizedBox(height: 16),
           Text(
             isUpi ? 'Complete Payment on App' : 'Authentication Required', 
             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
           ),
           const SizedBox(height: 8),
           Text(
             isUpi ? 'Scan/Approve request on your UPI app.' : 'Enter the OTP sent to your mobile.',
             textAlign: TextAlign.center,
             style: const TextStyle(color: Colors.grey)
           ),
           
           if (!isUpi) ...[
             const SizedBox(height: 24),
             TextField(
               controller: _otpController,
               decoration: _inputDeco('Enter OTP', icon: Icons.vpn_key),
               keyboardType: TextInputType.number,
               maxLength: 6,
             ),
           ],
           
           const SizedBox(height: 32),
           
           SizedBox(
             width: double.infinity,
             height: 48,
             child: ElevatedButton(
               onPressed: _verifyOtpOrApproval,
               style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
               child: Text(isUpi ? 'I have Paid' : 'Verify OTP', style: const TextStyle(color: Colors.white)),
             ),
           ),
           
           if (isUpi) 
             Padding(
               padding: const EdgeInsets.only(top: 12),
               child: TextButton(
                 onPressed: _verifyOtpOrApproval, // Simulates success
                 child: const Text('Simulate Success (Test Mode)', style: TextStyle(color: Colors.grey)),
               ),
             )
        ],
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
             padding: const EdgeInsets.all(16),
             decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
             child: const Icon(Icons.check, color: Colors.white, size: 40)
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text('Payment Successful', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Merchant Reference: #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- Helpers ---

  InputDecoration _inputDeco(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: themeColor, width: 1.5)),
      filled: true,
      fillColor: Colors.grey[50],
      isDense: true,
      counterText: "",
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
    );
  }
  
  String _getMethodName(int index) {
    switch (index) {
      case 0: return 'Card Payment';
      case 1: return 'UPI Payment';
      case 2: return 'Scan QR Code';
      case 3: return 'Netbanking';
      default: return 'Wallet';
    }
  }
  
  Widget _getMethodIcon(int index) {
     IconData icon;
     Color color = themeColor;
     switch (index) {
      case 0: icon = Icons.credit_card; break;
      case 1: icon = Icons.mobile_friendly; break;
      case 2: icon = Icons.qr_code_2; break;
      case 3: icon = Icons.account_balance; break;
      default: icon = Icons.account_balance_wallet;
    }
    return Icon(icon, color: color, size: 28);
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var text = newValue.text;
    var digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    var buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != digits.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    // Limit to 5 characters (XX/XX)
    if (string.length > 5) {
        string = string.substring(0, 5);
    }
    
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != digits.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
