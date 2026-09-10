import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna apenas as listas criadas pelo próprio usuário (Dono)
  Stream<QuerySnapshot> getMyLists() {
    final user = FirebaseAuth.instance.currentUser;
    final String userUid = user?.uid ?? '';

    return _db
        .collection('listas')
        .where('donoId', isEqualTo: userUid)
        .snapshots();
  }

  /// Retorna as listas das quais o usuário é membro (incluindo compartilhadas)
  Stream<QuerySnapshot> getSharedLists() {
    final user = FirebaseAuth.instance.currentUser;
    final String userUid = user?.uid ?? '';
    final String userEmail = user?.email?.toLowerCase() ?? '';

    return _db
        .collection('listas')
        .where('membros', arrayContainsAny: [userUid, userEmail])
        .snapshots();
  }

  /// Criar uma nova lista com código de compartilhamento único
  Future<DocumentReference> createList(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    final String userUid = user?.uid ?? '';
    final String userEmail = user?.email?.toLowerCase() ?? 'teste@exemplo.com';
    final String userName = user?.displayName ?? userEmail.split('@').first;

    final String shareCode = DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(36)
        .substring(2, 8)
        .toUpperCase();

    return await _db.collection('listas').add({
      'nome': name,
      'donoId': userUid,
      'donoEmail': userEmail,
      'shareCode': shareCode,
      'membros': [userUid, userEmail],
      'membrosInfo': {
        userUid.isNotEmpty ? userUid : userEmail: {
          'nome': userName,
          'email': userEmail,
          'papel': 'dono',
        }
      },
      'solicitacoesPendentes': {},
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Solicitar entrada em uma lista utilizando o código PIN
  Future<String> joinListByCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Usuário não autenticado.';

    final cleanCode = code.trim().toUpperCase();
    final query = await _db
        .collection('listas')
        .where('shareCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return 'Código inválido ou lista não encontrada.';

    final doc = query.docs.first;
    final data = doc.data();
    final List membros = data['membros'] ?? [];
    final Map solicitacoes = data['solicitacoesPendentes'] ?? {};

    if (membros.contains(user.uid) || membros.contains(user.email)) {
      return 'Você já faz parte desta lista!';
    }

    if (solicitacoes.containsKey(user.uid)) {
      return 'Sua solicitação ainda está aguardando aprovação do dono.';
    }

    final String userName = user.displayName ?? user.email?.split('@').first ?? 'Convidado';
    await doc.reference.update({
      'solicitacoesPendentes.${user.uid}': {
        'nome': userName,
        'email': user.email,
        'solicitadoEm': FieldValue.serverTimestamp(),
      }
    });

    return 'Solicitação enviada! Aguarde a aprovação do dono.';
  }

  /// Excluir uma lista inteira e todos os seus itens da subcoleção de forma atômica
  Future<void> deleteList(String listId) async {
    final WriteBatch batch = _db.batch();
    final DocumentReference listRef = _db.collection('listas').doc(listId);

    // 1. Busca todos os itens da subcoleção para adicionar ao lote de exclusão
    final QuerySnapshot itemsSnapshot = await listRef.collection('itens').get();
    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Adiciona o documento principal da lista ao lote
    batch.delete(listRef);

    // 3. Executa todas as exclusões em uma única transação
    await batch.commit();
  }

  /// Alternar compra de item gravando o nome de quem comprou
  Future<void> toggleItemPurchased(String listId, String itemId, bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    final String buyerName = user?.displayName ?? user?.email?.split('@').first ?? 'Alguém';

    await _db
        .collection('listas')
        .doc(listId)
        .collection('itens')
        .doc(itemId)
        .update({
      'isPurchased': !currentStatus,
      'purchasedBy': !currentStatus ? buyerName : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}