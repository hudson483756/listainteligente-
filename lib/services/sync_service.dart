import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';// Certifique-se de importar seu DatabaseHelper

class SyncService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveScope,
    ],
  );

  static const String _nomeArquivoDb = 'listaInteligente.db';
  static const String _nomePastaDrive = 'ListaInteligente_Backup';
  static const String _nomePastaFotosDrive = 'Fotos_Produtos';

  // Obtém o diretório local de imagens
  static Future<Directory> getDiretorioFotosLocais() async {
    final docDir = await getApplicationDocumentsDirectory();
    final pastaFotos = Directory(p.join(docDir.path, 'Fotos_Produtos'));
    if (!await pastaFotos.exists()) {
      await pastaFotos.create(recursive: true);
    }
    return pastaFotos;
  }

  /// Garante a autenticação com a conta do Google do usuário
  static Future<drive.DriveApi?> _obterDriveApi() async {
    try {
      GoogleSignInAccount? conta = _googleSignIn.currentUser;
      conta ??= await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (conta == null) return null;

      var clienteAutenticado = await _googleSignIn.authenticatedClient();
      if (clienteAutenticado == null) return null;

      return drive.DriveApi(clienteAutenticado);
    } catch (e) {
      stderr.writeln("Erro ao obter cliente do Drive: $e");
      return null;
    }
  }

  /// Busca ou cria dinamicamente uma pasta na raiz do Google Drive do usuário
  static Future<String?> _obterOuCriarPastaDrive(drive.DriveApi driveApi, String nomePasta, {String? idPastaPai}) async {
    try {
      String query = "name = '$nomePasta' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      if (idPastaPai != null) {
        query += " and '$idPastaPai' in parents";
      }

      final lista = await driveApi.files.list(q: query, $fields: "files(id, name)");

      if (lista.files != null && lista.files!.isNotEmpty) {
        return lista.files!.first.id;
      } else {
        final pastaMetadata = drive.File()
          ..name = nomePasta
          ..mimeType = 'application/vnd.google-apps.folder';
        
        if (idPastaPai != null) {
          pastaMetadata.parents = [idPastaPai];
        }

        final pastaCriada = await driveApi.files.create(pastaMetadata);
        return pastaCriada.id;
      }
    } catch (e) {
      stderr.writeln("Erro ao obter/criar pasta no Drive: $e");
      return null;
    }
  }

  /// Envia uma imagem local do produto para a nuvem
  static Future<void> enviarFotoParaDrive(String nomeArquivo) async {
    try {
      if (nomeArquivo.trim().isEmpty) return;

      final nomeLimpo = nomeArquivo.split('/').last.split('\\').last.trim();
      final pastaFotos = await getDiretorioFotosLocais();
      final arquivoLocal = File(p.join(pastaFotos.path, nomeLimpo));

      if (!await arquivoLocal.exists()) return;

      final driveApi = await _obterDriveApi();
      if (driveApi == null) return;

      final idPastaPrincipal = await _obterOuCriarPastaDrive(driveApi, _nomePastaDrive);
      if (idPastaPrincipal == null) return;

      final idPastaFotos = await _obterOuCriarPastaDrive(driveApi, _nomePastaFotosDrive, idPastaPai: idPastaPrincipal);
      if (idPastaFotos == null) return;

      final query = "'$idPastaFotos' in parents and name = '$nomeLimpo' and trashed = false";
      final response = await driveApi.files.list(q: query, $fields: "files(id)");

      if (response.files == null || response.files!.isEmpty) {
        final metadata = drive.File()
          ..name = nomeLimpo
          ..parents = [idPastaFotos];

        final midiaUpload = drive.Media(
          arquivoLocal.openRead(),
          await arquivoLocal.length(),
        );

        await driveApi.files.create(metadata, uploadMedia: midiaUpload);
      }
    } catch (e) {
      stderr.writeln("Erro ao enviar foto para o Drive: $e");
    }
  }

  /// Baixa uma imagem do produto se não existir localmente
  static Future<File?> baixarFotoSeNecessario(String nomeArquivo) async {
    try {
      if (nomeArquivo.trim().isEmpty) return null;

      final nomeLimpo = nomeArquivo.split('/').last.split('\\').last.trim();
      final pastaFotos = await getDiretorioFotosLocais();
      final arquivoLocal = File(p.join(pastaFotos.path, nomeLimpo));

      if (await arquivoLocal.exists()) return arquivoLocal;

      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      final idPastaPrincipal = await _obterOuCriarPastaDrive(driveApi, _nomePastaDrive);
      if (idPastaPrincipal == null) return null;

      final idPastaFotos = await _obterOuCriarPastaDrive(driveApi, _nomePastaFotosDrive, idPastaPai: idPastaPrincipal);
      if (idPastaFotos == null) return null;

      final query = "'$idPastaFotos' in parents and name = '$nomeLimpo' and trashed = false";
      final response = await driveApi.files.list(q: query, $fields: "files(id, name)");

      if (response.files != null && response.files!.isNotEmpty) {
        final fileId = response.files!.first.id!;

        final drive.Media media = await driveApi.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        List<int> bytes = [];
        await for (var chunk in media.stream) {
          bytes.addAll(chunk);
        }

        await arquivoLocal.writeAsBytes(bytes, flush: true);
        return arquivoLocal;
      }
    } catch (e) {
      stderr.writeln("Erro ao baixar foto do Drive: $e");
    }
    return null;
  }

  /// Processo completo de sincronização na abertura do app
  static Future<void> sincronizarComGoogleDrive({
    required Function(String mensagem, double progresso) onProgress,
  }) async {
    try {
      onProgress("Conectando à sua Conta Google...", 0.1);

      final driveApi = await _obterDriveApi();
      if (driveApi == null) {
        throw Exception("Falha ao autenticar cliente.");
      }

      onProgress("Localizando backups...", 0.3);
      final idPastaPrincipal = await _obterOuCriarPastaDrive(driveApi, _nomePastaDrive);
      if (idPastaPrincipal == null) {
        throw Exception("Não foi possível acessar a pasta de backups.");
      }

      onProgress("Verificando dados na nuvem...", 0.5);
      final listaArquivos = await driveApi.files.list(
        q: "name = '$_nomeArquivoDb' and '$idPastaPrincipal' in parents and trashed = false",
        $fields: 'files(id, name, modifiedTime)',
      );

      final caminhoDbLocal = p.join(await getDatabasesPath(), _nomeArquivoDb);
      final arquivoDbLocal = File(caminhoDbLocal);

      if (listaArquivos.files != null && listaArquivos.files!.isNotEmpty) {
        onProgress("Sincronizando suas listas de compras...", 0.7);
        final arquivoNoDrive = listaArquivos.files!.first;
        final idArquivoDrive = arquivoNoDrive.id!;

        final diretorioTemp = await getTemporaryDirectory();
        final caminhoDbTemp = p.join(diretorioTemp.path, 'drive_temp.db');
        final arquivoDbTemp = File(caminhoDbTemp);

        if (await arquivoDbTemp.exists()) await arquivoDbTemp.delete();

        final drive.Media midiaBaixada = await driveApi.files.get(
          idArquivoDrive,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        List<int> bytesIniciais = [];
        await for (var dados in midiaBaixada.stream) {
          bytesIniciais.addAll(dados);
        }
        await arquivoDbTemp.writeAsBytes(bytesIniciais);

        if (await arquivoDbLocal.exists()) {
          await _mesclarBancosDeDados(caminhoDbLocal, caminhoDbTemp);
        } else {
          await arquivoDbLocal.writeAsBytes(bytesIniciais);
        }

        await arquivoDbTemp.delete();

        onProgress("Atualizando nuvem...", 0.9);
        final midiaUpload = drive.Media(
          arquivoDbLocal.openRead(),
          await arquivoDbLocal.length(),
        );

        await driveApi.files.update(
          drive.File(),
          idArquivoDrive,
          uploadMedia: midiaUpload,
        );
      } else {
        onProgress("Criando seu primeiro backup na nuvem...", 0.7);
        if (await arquivoDbLocal.exists()) {
          final metadataNovo = drive.File()
            ..name = _nomeArquivoDb
            ..parents = [idPastaPrincipal];

          final midiaUpload = drive.Media(
            arquivoDbLocal.openRead(),
            await arquivoDbLocal.length(),
          );

          await driveApi.files.create(metadataNovo, uploadMedia: midiaUpload);
        }
      }

      onProgress("Tudo pronto! Entrando...", 1.0);
    } catch (e) {
      stderr.writeln("Erro na Sincronização: $e");
      onProgress("Modo offline ativado. Entrando...", 1.0);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Compara e funde as tabelas do Lista Inteligente usando o timestamp da última atualização
  static Future<void> _mesclarBancosDeDados(String localPath, String tempPath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      if (db.isOpen) {
        await db.close();
      }
    } catch (_) {}

    Database dbLocal = await openDatabase(localPath);
    Database dbTemp = await openDatabase(tempPath);

    // Tabelas específicas do Lista Inteligente
    List<String> tabelasParaSincronizar = ['Listas', 'Itens', 'Categorias'];

    for (String tabela in tabelasParaSincronizar) {
      try {
        List<Map<String, dynamic>> registrosTemp = await dbTemp.query(tabela);

        for (var regTemp in registrosTemp) {
          final id = regTemp['Id'];

          List<Map<String, dynamic>> registroLocalExistente = await dbLocal.query(
            tabela,
            where: 'Id = ?',
            whereArgs: [id],
          );

          if (registroLocalExistente.isEmpty) {
            await dbLocal.insert(tabela, regTemp, conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            var regLocal = registroLocalExistente.first;

            String stringDataTemp = regTemp['UltimaAtualizacao'] ?? '1970-01-01 00:00:00';
            String stringDataLocal = regLocal['UltimaAtualizacao'] ?? '1970-01-01 00:00:00';

            DateTime dataTemp = DateTime.tryParse(stringDataTemp) ?? DateTime.fromMillisecondsSinceEpoch(0);
            DateTime dataLocal = DateTime.tryParse(stringDataLocal) ?? DateTime.fromMillisecondsSinceEpoch(0);

            if (dataTemp.isAfter(dataLocal)) {
              await dbLocal.update(
                tabela,
                regTemp,
                where: 'Id = ?',
                whereArgs: [id],
              );
            }
          }
        }
      } catch (e) {
        stderr.writeln("Tabela $tabela não encontrada para mesclagem: $e");
      }
    }

    await dbLocal.close();
    await dbTemp.close();
  }
}