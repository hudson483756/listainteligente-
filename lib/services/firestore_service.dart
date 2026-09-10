import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna as listas das quais o usuário é membro ou dono
  Stream<QuerySnapshot> getLists() {
    final user = FirebaseAuth.instance.currentUser;
    final String userUid = user?.uid ?? '';
    final String userEmail = user?.email?.toLowerCase() ?? 'teste@exemplo.com';

    return _db
        .collection('listas')
        .where('membros', arrayContainsAny: [userUid, userEmail])
        .snapshots();
  }

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
    final String userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : userEmail.split('@').first;

    final String shareCode = DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(36)
        .substring(2, 8)
        .toUpperCase();

    final docRef = await _db.collection('listas').add({
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

    await sendSystemMessage(docRef.id, '$userName criou a lista "$name".');

    return docRef;
  }

  /// Entrar em uma lista diretamente pelo ID ou código de compartilhamento
  Future<void> joinList(String inputCodeOrId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final String queryStr = inputCodeOrId.trim();
    final String userUid = user.uid;
    final String userEmail = user.email?.toLowerCase() ?? '';
    final String userName = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : userEmail.split('@').first;

    DocumentReference? listRef;

    final docSnap = await _db.collection('listas').doc(queryStr).get();
    if (docSnap.exists) {
      listRef = docSnap.reference;
    } else {
      final queryByCode = await _db
          .collection('listas')
          .where('shareCode', isEqualTo: queryStr.toUpperCase())
          .limit(1)
          .get();

      if (queryByCode.docs.isNotEmpty) {
        listRef = queryByCode.docs.first.reference;
      }
    }

    if (listRef == null) {
      throw Exception('Lista não encontrada. Verifique o ID ou código informado.');
    }

    final snap = await listRef.get();
    final data = snap.data() as Map<String, dynamic>;
    final List membros = data['membros'] ?? [];

    if (membros.contains(userUid) || membros.contains(userEmail)) {
      return;
    }

    await listRef.update({
      'membros': FieldValue.arrayUnion([userUid, userEmail]),
      'membrosInfo.$userUid': {
        'nome': userName,
        'email': userEmail,
        'papel': 'convidado',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await sendSystemMessage(listRef.id, '$userName entrou na lista.');
  }

  /// Excluir a lista, seus itens e todas as mensagens do chat em lote
  Future<void> deleteList(String listId) async {
    final WriteBatch batch = _db.batch();
    final DocumentReference listRef = _db.collection('listas').doc(listId);

    final QuerySnapshot itemsSnapshot = await listRef.collection('itens').get();
    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final QuerySnapshot messagesSnapshot = await listRef.collection('mensagens').get();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(listRef);
    await batch.commit();
  }

  /// Finaliza a lista gravando o valor total realmente pago
  Future<void> finalizeList(String listId, String listName, double actualAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : user?.email?.split('@').first ?? 'Alguém';

    await _db.collection('listas').doc(listId).update({
      'isFinalized': true,
      'finalizedAmount': actualAmount,
      'finalizedAt': FieldValue.serverTimestamp(),
      'finalizedBy': userName,
    });

    await sendSystemMessage(
      listId,
      '$userName finalizou a compra! Valor real pago: R\$ ${actualAmount.toStringAsFixed(2)}',
    );
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

    final String userName = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : user.email?.split('@').first ?? 'Convidado';

    await doc.reference.update({
      'solicitacoesPendentes.${user.uid}': {
        'nome': userName,
        'email': user.email,
        'solicitadoEm': FieldValue.serverTimestamp(),
      }
    });

    return 'Solicitação enviada! Aguarde a aprovação do dono.';
  }

  /// Aceitar solicitação de um participante
  Future<void> acceptMember(String listId, String applicantUid, Map applicantData) async {
    final listRef = _db.collection('listas').doc(listId);

    await listRef.update({
      'membros': FieldValue.arrayUnion([applicantUid]),
      'membrosInfo.$applicantUid': {
        'nome': applicantData['nome'] ?? 'Convidado',
        'email': applicantData['email'] ?? '',
        'papel': 'convidado',
      },
      'solicitacoesPendentes.$applicantUid': FieldValue.delete(),
    });

    final memberName = applicantData['nome'] ?? 'Novo participante';
    await sendSystemMessage(listId, '$memberName entrou na lista.');
  }

  /// Recusar solicitação pendente
  Future<void> rejectMember(String listId, String applicantUid) async {
    await _db.collection('listas').doc(listId).update({
      'solicitacoesPendentes.$applicantUid': FieldValue.delete(),
    });
  }

  /// Remover membro da lista (Ação do Dono)
  Future<void> removeMember(String listId, String memberUid) async {
    await _db.collection('listas').doc(listId).update({
      'membros': FieldValue.arrayRemove([memberUid]),
      'membrosInfo.$memberUid': FieldValue.delete(),
    });
  }

  /// Alternar compra de item gravando o nome de quem comprou e notificando o chat
  Future<void> toggleItemPurchased(String listId, String itemId, bool currentStatus, String itemName) async {
    final user = FirebaseAuth.instance.currentUser;
    final String buyerName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : user?.email?.split('@').first ?? 'Alguém';

    final bool newStatus = !currentStatus;

    await _db.collection('listas').doc(listId).collection('itens').doc(itemId).update({
      'isPurchased': newStatus,
      'purchasedBy': newStatus ? buyerName : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus) {
      await sendSystemMessage(listId, '$buyerName marcou "$itemName" como comprado.');
    }
  }

  // --- MÉTODOS DE BATE-PAPO DA LISTA ---

  Future<void> sendMessage(String listId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;

    final String senderName = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : user.email?.split('@').first ?? 'Usuário';

    await _db.collection('listas').doc(listId).collection('mensagens').add({
      'texto': text.trim(),
      'remetenteUid': user.uid,
      'remetenteNome': senderName,
      'isSystem': false,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendSystemMessage(String listId, String text) async {
    await _db.collection('listas').doc(listId).collection('mensagens').add({
      'texto': text,
      'remetenteUid': 'system',
      'remetenteNome': 'Sistema',
      'isSystem': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getListMessages(String listId) {
    return _db
        .collection('listas')
        .doc(listId)
        .collection('mensagens')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }
}