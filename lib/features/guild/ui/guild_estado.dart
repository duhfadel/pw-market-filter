import '../domain/papel.dart';

/// The guild panel's door, as a sealed state. `GuildSemAcesso` is a state of
/// its own rather than a flag on `GuildDeslogado`: a signed-in account with
/// no row in `perfis` is not the same as nobody having logged in at all.
sealed class GuildEstado {
  const GuildEstado();
}

class GuildDeslogado extends GuildEstado {
  const GuildDeslogado();
}

class GuildCarregando extends GuildEstado {
  const GuildCarregando();
}

class GuildLogado extends GuildEstado {
  const GuildLogado(this.papel);
  final Papel papel;
}

class GuildSemAcesso extends GuildEstado {
  const GuildSemAcesso();
}
