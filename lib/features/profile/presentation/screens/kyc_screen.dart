import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/kyc_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDocType = 'Aadhaar Card';
  final TextEditingController _docNumberController = TextEditingController();
  bool _isSubmitting = false;
  KycModel? _currentKyc;

  XFile? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final status = await ref
        .read(firestoreServiceProvider)
        .getKycStatus(user.uid)
        .first;
    if (mounted) {
      setState(() {
        _currentKyc = status;
        if (status != null) {
          // Convert documentType back to display format
          switch (status.documentType) {
            case 'aadhaar':
              _selectedDocType = 'Aadhaar Card';
              break;
            case 'driving_license':
              _selectedDocType = 'Driving License';
              break;
            case 'passport':
              _selectedDocType = 'Passport';
              break;
            case 'voter_id':
              _selectedDocType = 'Voter ID';
              break;
            default:
              _selectedDocType = 'Aadhaar Card';
          }
          // Set document number if available (it will be masked in display)
          if (status.documentNumber != null) {
            _docNumberController.text = status.documentNumber!;
          }
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    // In a real app, we would upload the file here and get a URL.
    // For now, we simulate a URL.
    if (_docNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter document number')),
      );
      return;
    }

    // Check if file is selected
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // In a real app, upload _selectedFile bytes to storage
      final mockUrl = 'https://example.com/docs/${_selectedFile!.name}';

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final now = DateTime.now();
      final kyc = KycModel(
        userId: user.uid,
        status: 'pending',
        documentType: _selectedDocType.toLowerCase().replaceAll(' ', '_'),
        documentNumber: _docNumberController.text,
        documentUrl: mockUrl,
        submittedAt: now,
        completionStep: 3, // All steps completed
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(firestoreServiceProvider).submitKyc(kyc);

      await _fetchStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC Submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  _currentKyc?.status ?? 'pending',
                ).withOpacity(0.1),
                border: Border.all(
                  color: _getStatusColor(_currentKyc?.status ?? 'pending'),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(_currentKyc?.status ?? 'not_submitted'),
                    size: 40,
                    color: _getStatusColor(
                      _currentKyc?.status ?? 'not_submitted',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${_getStatusDisplayText(_currentKyc?.status ?? "not_submitted")}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(
                        _currentKyc?.status ?? 'not_submitted',
                      ),
                    ),
                  ),
                  if (_currentKyc?.rejectionReason != null &&
                      _currentKyc!.rejectionReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Note: ${_currentKyc!.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_currentKyc?.status == 'approved')
              const Center(
                child: Text(
                  'Your account is verified. You can now list items!',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              const Text(
                'Submit Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDocType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'Aadhaar Card',
                                'Driving License',
                                'Passport',
                                'Voter ID',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDocType = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _docNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Document Number',
                        border: OutlineInputBorder(),
                        hintText: 'Enter ID number',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // File Upload
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(
                            color: Colors.grey,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedFile != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 40,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _selectedFile = null),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to upload document image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF781C2E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            _isSubmitting || _currentKyc?.status == 'pending'
                            ? null
                            : _submitKyc,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _currentKyc?.status == 'pending'
                                    ? 'Under Review'
                                    : 'SUBMIT FOR VERIFICATION',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.error;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'approved':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'UNDER REVIEW';
      default:
        return 'NOT SUBMITTED';
    }
  }
}
