import 'package:flutter/painting.dart';

/// Os números que a maquete da home fixou, num sítio só.
///
/// **A maquete é a referência e está versionada** em `docs/maquete/home.html`.
/// Estes valores são lidos do CSS dela, e `medidas_da_maquete_test` volta a
/// lê-los do ficheiro a cada corrida para os comparar com o que está aqui —
/// portanto mexer num dos dois lados sem mexer no outro põe a suíte vermelha.
///
/// **Existe porque três voltas no herói saíram de eu deduzir em vez de ler.**
/// Olhei para capturas, inferi o enquadramento, e o CSS dizia tudo em quatro
/// linhas desde o princípio. Uma tabela de números não impede isso sozinha; o
/// teste que a confronta com o ficheiro, sim.
class Maquete {
  const Maquete._();

  /// `.env { max-width: var(--col) }` com `--col: 1180px`.
  static const colunaDeLeitura = 1180.0;

  /// `.heroi { min-height: min(86vh, 760px) }`.
  static const heroiFraccaoDaJanela = 0.86;
  static const heroiAlturaMaxima = 760.0;

  /// Um chão que a maquete não precisa de declarar porque o browser não
  /// desenha uma janela de 400 px de altura. Aqui precisa: `MediaQuery` dá
  /// alturas pequenas durante transições.
  static const heroiAlturaMinima = 420.0;

  /// `.arteheroi { object-position: 76% 20% }`.
  ///
  /// Em CSS, `20%` quer dizer *põe o ponto a 20% da imagem a 20% da caixa*; o
  /// equivalente em Flutter é `2 × 0,20 − 1`.
  static const arteDoHeroiX = 0.76;
  static const arteDoHeroiY = 0.20;

  static Alignment get alinhamentoDaArte =>
      Alignment(arteDoHeroiX * 2 - 1, arteDoHeroiY * 2 - 1);

  /// `.heroi h1 { font-size: clamp(38px, 5.6vw, 68px) }`.
  static const mancheteMinima = 38.0;
  static const mancheteFraccao = 0.056;
  static const mancheteMaxima = 68.0;

  /// `.pil { background: rgba(11,11,26,.42); backdrop-filter: blur(8px) }`.
  static const pilulaOpacidade = 0.42;
  static const pilulaDesfoque = 8.0;

  /// `.pil { border: 1px solid rgba(255,255,255,.18) }` e, na variante de
  /// ouro, `rgba(255,180,84,.55)`.
  static const pilulaBorda = 0.18;
  static const pilulaBordaOuro = 0.55;

  /// `section { padding: 58px 0 }`.
  static const respiroDeSeccao = 58.0;

  /// `.vz.breve { opacity: .62 }`.
  static const versaoFechadaOpacidade = 0.62;

  /// `.vz:hover { background: rgba(255,180,84,.045) }`.
  static const versaoSobOPonteiro = 0.045;
}
