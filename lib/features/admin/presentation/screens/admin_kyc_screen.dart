import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/items_provider.dart'; 
import '../../../../core/models/kyc_model.dart';

class AdminKycScreen extends ConsumerWidget {
  const AdminKycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycStream = ref.watch(firestoreServiceProvider).getPendingKyc();

    return Scaffold(
      appBar: AppBar(title: const Text('Pending KYC Requests')),
      body: StreamBuilder<List<KycModel>>(
        stream: kycStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final kycs = snapshot.data ?? [];

          if (kycs.isEmpty) {
            return const Center(child: Text('No pending KYC requests.'));
          }

          return ListView.builder(
            itemCount: kycs.length,
            itemBuilder: (context, index) {
              final kyc = kycs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID: ${kyc.userId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Doc Type: ${kyc.documentType}'),
                      // In real app, display image here
                      const SizedBox(height: 8),
                      Text('Submitted: ${kyc.submittedAt}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _reject(context, ref, kyc.userId),
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approve(context, ref, kyc.userId),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(firestoreServiceProvider).approveKyc(userId);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String userId) async {
    // Show dialog for reason
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(controller: reasonController, decoration: const InputDecoration(hintText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(firestoreServiceProvider).rejectKyc(userId, reasonController.text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
