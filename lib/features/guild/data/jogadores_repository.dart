import 'dart:typed_data';

import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/jogador.dart';

class JogadoresRepository {
  Future<Result<List<Jogador>>> lista() async {
    try {
      final linhas = await supa.from('jogadores').select().order('nome');
      return Success([for (final l in linhas) Jogador.fromJson(l)]);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  Future<Result<void>> criar(Jogador j) async {
    try {
      // Does not send 'id': the database generates it (gen_random_uuid()). A
      // new player has no client-side id — sending one would assert a key
      // that does not exist.
      final dados = j.toJson()..remove('id');
      await supa.from('jogadores').insert(dados);
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }

  /// Uploads the print to the private `prints` bucket and returns the path
  /// stored in `jogadores.print_url`. The file name must come with a unique
  /// suffix (the caller decides), so two prints of the same nick never
  /// overwrite each other.
  Future<Result<String>> subirPrint(Uint8List bytes, String nomeArquivo) async {
    try {
      await supa.storage.from('prints').uploadBinary(nomeArquivo, bytes);
      return Success(nomeArquivo);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.upload));
    }
  }

  /// Hand correction of a player's fields — a direct PATCH, no new print in
  /// this round (see the spec's deferred decision).
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async {
    try {
      await supa.from('jogadores').update(campos).eq('id', id);
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
