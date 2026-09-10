import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lista_inteligente/services/firestore_service.dart';

class ManageMembersDialog extends StatelessWidget {
  final String listId;

  const ManageMembersDialog({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('listas').doc(listId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String shareCode = data['shareCode'] ?? 'N/A';
          final String donoId = data['donoId'] ?? '';
          final bool isOwner = donoId == currentUid;

          final Map membrosInfo = data['membrosInfo'] ?? {};
          final Map pendingRequests = data['solicitacoesPendentes'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Participantes da Lista',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Código de Entrada (PIN):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shareCode,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Código copiado para a área de transferência!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pendingRequests.isNotEmpty && isOwner) ...[
                    const Text('Solicitações Pendentes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 8),
                    ...pendingRequests.entries.map((entry) {
                      final uid = entry.key;
                      final req = entry.value;
                      return ListTile(
                        dense: true,
                        title: Text(req['nome'] ?? 'Convidado'),
                        subtitle: Text(req['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => firestoreService.acceptMember(listId, uid, req),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => firestoreService.rejectMember(listId, uid),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                  ],
                  const Text('Membros Atuais', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...membrosInfo.entries.map((entry) {
                    final uid = entry.key;
                    final info = entry.value;
                    final bool isMemberOwner = info['papel'] == 'dono';

                    return ListTile(
                      dense: true,
                      title: Text(info['nome'] ?? 'Membro'),
                      subtitle: Text(info['email'] ?? ''),
                      trailing: isMemberOwner
                          ? const Chip(label: Text('Dono', style: TextStyle(fontSize: 10)))
                          : isOwner
                              ? IconButton(
                                  icon: const Icon(Icons.person_remove, color: Colors.red, size: 18),
                                  onPressed: () => firestoreService.removeMember(listId, uid),
                                )
                              : null,
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}