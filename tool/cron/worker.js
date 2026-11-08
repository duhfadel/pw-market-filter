// Um relógio que o GitHub não controla.
//
// O `schedule` das Actions é melhor esforço, e medido entre 26 e 29/08 ele
// entregou de 45 minutos a 12 horas onde o cron pedia 20. Nada falhava: o
// GitHub simplesmente não disparava. Este Worker acorda no horário e pede a
// coleta pela API, então o relógio passa a ser da Cloudflare — que já serve o
// site inteiro.
//
// **Não tem rota HTTP, de propósito.** Um endereço público que dispara a
// coleta é um endereço que qualquer um pode marretar, e cada disparo são ~1000
// requisições ao marketplace, que bloqueia por hora quando é maltratado. O
// `workers_dev = false` no wrangler.toml é o que garante isso: a única porta
// de entrada é o cron.

const REPO = 'duhfadel/pw-market-filter';
const WORKFLOW = 'publish.yml';

// Quatro horários da coleta agora, dois por versão — cada mercado atualiza a
// cada 30 minutos, decisão do dono e registrada em `wrangler.toml` com a
// conta completa. `publish.yml` ganhou `inputs.server` (padrão `pw187`)
// justamente para isto: uma corrida colhe uma versão e arrasta a outra do
// que já está no ar (ver `tool/collect.dart --carry-forward` e o passo
// "Arrastar a versão que esta corrida não colheu"), então alternar os
// quatro horários é o que cobre os dois mercados sem dobrar o orçamento
// total de disparos — que continua quatro por hora, o mesmo de antes de
// existir uma segunda versão.
//
// **As duas listas são comparadas string a string com os quatro `crons` do
// `wrangler.toml`.** Deixar qualquer entrada divergir faz o ramo daquela
// coleta nunca disparar, caindo calado no keep-alive do Supabase — o
// `wrangler.toml` avisa disso e agora há quatro formas de acontecer em vez
// de uma.
// **Um horário, e uma corrida colhe todas as versões.** Até 06/10/2026 havia
// um horário por mercado, porque cada corrida colhia um — e isso trouxe dois
// problemas que `publish.yml` conta por extenso: a corrida de dados do
// `--carry-forward`, e o facto de três ou mais corridas por hora darem
// intervalos que não cabem a coleta mais lenta medida, 18 minutos.
//
// Agora uma corrida colhe **todas** as versões, em jobs paralelos. Portanto
// não há versão a escolher no disparo, e uma versão nova não precisa de um
// horário novo — entra na matriz do workflow.
//
// **De meia em meia hora desde 11/10/2026, e a aritmética é outra agora.** A
// tentativa de 05/10 falhou por serem *quatro* corridas por hora — uma de
// quinze em quinze minutos, com duas coletas a disputar a fila do Pages, que
// guarda uma pendente só. Com a matriz há **duas** corridas por hora e 30
// minutos entre elas, e a corrida inteira leva 3 a 4 minutos: a coleta mais
// lenta já medida, 18 minutos, cabe com folga. O que mudou não foi a
// vontade, foi o número de corridas a competir.
const CRON_DA_COLETA = '7,37 * * * *';


// O banco que guarda o contador de visitas e os donos dos territórios.
//
// A chave é a publicável, a mesma que já está compilada no bundle de todo
// visitante — não é segredo e não tem por que virar um. Quem segura a porta é
// o RLS: `visit_days` não tem policy nenhuma, então leitura e escrita diretas
// são negadas, e as duas funções `security definer` são a única entrada.
// A cada quanto o Worker pergunta à Twitch quem está ao vivo.
//
// Cinco minutos e não um: uma live que começou há três minutos não é notícia
// urgente, e o atraso é invisível para quem chega no site. O que não pode é
// crescer muito — um banner que anuncia alguém que já saiu do ar é pior que
// banner nenhum.
const CRON_DA_TWITCH = '*/5 * * * *';

// **Uma vez por dia, e tem de bater com `wrangler.toml` carácter a
// carácter** — o despacho compara as strings, como o da coleta. 14:11 UTC
// são 11:11 em Brasília: as guerras são à sexta e ao sábado à noite, os
// vídeos sobem no dia seguinte, e um aviso de madrugada é um aviso que
// ninguém lê.
const CRON_DOS_VIDEOS = '11 14 * * *';

// Público por decisão da Twitch, não por descuido: a documentação diz que o
// Client ID "is considered public and can be embedded in a web page's source".
// O que não pode aparecer é o secret, e ele vive no `wrangler secret`.
const TWITCH_CLIENT_ID = 'g5aijijz2yef9fx7wonix8ht6cj36y';

// O canal cujas mensagens viram novidade no site: #📢・novidades.
//
// **A segurança disto é a permissão do canal, não este código.** O Worker
// copia o que estiver lá, então quem puder escrever no canal publica na home
// — e é por isso que ele é restrito ao dono. Trocar por um canal aberto
// entrega a página para o servidor inteiro.
const CANAL_DAS_NOVIDADES = '1550593679503269948';

// Quantas mensagens o Worker olha por rodada.
//
// Vinte e não todas: é a janela dentro da qual uma mensagem apagada no
// Discord também some do site. Mais fundo custaria requisição para reler
// coisa que nunca muda; menos deixaria um apagado recente sobreviver.
const JANELA_DAS_NOVIDADES = 20;

const SUPABASE = 'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1';
const SUPABASE_KEY = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

// Uma rodada parada na fila por mais tempo que isto está travada, não ocupada.
// Uma coleta normal leva ~3 minutos; a fila do GitHub é instantânea quando há
// máquina. Dez minutos é folgado o bastante para nunca pegar uma rodada sã e
// curto o bastante para o buraco no site ser meia hora, não duas.
const PRESA_DEMAIS_MS = 10 * 60 * 1000;

// O que conta como "na fila". `in_progress` nunca entra aqui: uma coleta em
// andamento está trabalhando, e quem a mata quando trava de verdade é o
// `timeout-minutes` do workflow.
const NA_FILA = new Set(['queued', 'pending', 'waiting', 'requested']);

export default {
  async scheduled(event, env, ctx) {

    // Dois gatilhos, duas tarefas. O do Supabase não dispara coleta nenhuma:
    // ele existe justamente para os períodos em que não há coleta.
    if (event.cron === CRON_DA_TWITCH) {
      await atualizarQuemEstaAoVivo(env);
      await lerAsNovidades(env);
      // De carona nesta batida: uma coleta que quebrou esperava a próxima
      // hora daquela versão, e aqui a espera cai para cinco minutos.
      await ressuscitarColeta(env);
      await vigiarOSite(env);
      return;
    }

    if (event.cron === CRON_DOS_VIDEOS) {
      await procurarVideosDeGuerra(env);
      return;
    }

    // Nem a Twitch, nem os vídeos, nem a coleta: sobra o keep-alive do banco.
    if (event.cron !== CRON_DA_COLETA) {
      await manterOBancoAcordado();
      return;
    }

    await destravarFila(env);

    const resposta = await github(
      env,
      `/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches`,
      'POST',
      { ref: 'main' },
    );

    // 204 é o sucesso aqui: o GitHub aceita o pedido e não devolve corpo.
    if (resposta.status !== 204) {
      // Cai no log do Worker (`wrangler tail`). Um disparo perdido não é
      // urgência — a próxima hora tenta de novo, e a data da coleta no
      // site é o que denuncia se pararem todos.
      console.error(
        `disparo recusado (${servidor}): ${resposta.status} ` +
          `${await resposta.text()}`,
      );
    } else {
      // Qual versão disparou, sempre — não só no erro. Com um horário só
      // isso era óbvio pelo relógio; com dois, o log é o único lugar que
      // diz qual dos dois realmente saiu.
      console.log(`coleta disparada: ${servidor}`);
    }
  },
};

// Redispara a coleta quando a última quebrou, sem esperar o relógio.
//
// **Só depois de uma falha isolada, e nunca de duas seguidas — por versão.**
// Disparar a cada falha transformaria uma quebra persistente numa versão em
// corridas martelando o marketplace deles — exatamente o que o ritmo do
// coletor existe para impedir. Duas falhas em sequência *da mesma versão* não
// são soluço: são problema, e insistir piora. Aí o relógio daquela versão
// assume — meia hora depois, com os quatro horários de `wrangler.toml` — e a
// data da coleta no site é o que denuncia.
//
// **"Por versão" é a parte que mudou, e é a parte que importa agora que as
// duas se alternam.** Olhar só as duas rodadas mais recentes, sem filtrar por
// versão, compara `ultima` contra `anterior` mesmo quando elas são de
// mercados diferentes — então duas falhas seguidas do 126 nunca encontram
// outra falha do 126 bem ao lado para acionar o freio, porque entre elas quase
// sempre há uma corrida boa do 187. `per_page=10` em vez de 5 é para sobrar
// histórico suficiente de cada versão depois de filtrar pela mesma.
//
// **O comentário que estava aqui dizia o contrário do que o código fazia, e
// a forma é a de sempre: descrevia a intenção em vez da consulta.** Ele
// garantia que "assim que a nova rodada nasce, a mais recente deixa de ser a
// que quebrou" — e isso é falso enquanto a consulta pedir
// `status=completed`, porque uma rodada recém-disparada está `queued` e
// portanto **não aparece nesta lista**. A mais recente *completada* continua
// a ser a que falhou até a nova terminar.
//
// Com batida de cinco minutos e uma coleta de 65 minutos, isso são treze
// disparos pela mesma falha. E com `cancel-in-progress: false` o GitHub
// guarda **uma** pendente só, portanto cada disparo novo mata a que espera:
// é exactamente a forma do bloqueio de 01/10, trinta e duas corridas
// canceladas e dez horas sem deploy.
//
// Não mordeu em 05/10 por sorte de calendário: a corrida de recuperação
// demorou 4 min 05 s e acabou às 16:44:31, antes da batida das 16:45. O
// freio verdadeiro é perguntar se já existe uma rodada daquela versão **por
// terminar**, e é isso que `jaVemOutra` faz.
// O endereço que um visitante abre, e o ficheiro de que ele depende.
const VERSOES_PUBLICADAS = 'https://portalpw.net/versoes.json';

// Duas coletas falhadas. O relógio é de hora em hora, portanto nada de
// saudável chega aqui — e um limite mais apertado dispararia em cima de uma
// corrida que simplesmente demorou.
const VELHO_DEMAIS_MS = 2 * 60 * 60 * 1000;

/// Avisa quando o site está parado **ou** quando as portas não abrem.
///
/// **Existe por causa de 06/10/2026, em que nada falhou e o site estava
/// inutilizável.** A matriz de jobs deixou de escrever `versoes.json`, o ecrã
/// de escolha passou a desenhar as duas portas como *em breve* e não deixava
/// entrar em mercado nenhum. As coletas corriam, os índices estavam frescos,
/// as corridas estavam verdes — e o único sinal era um 404 na consola do
/// browser. Quem deu por isso foi o dono.
///
/// Daí serem **duas** perguntas e não uma. "Os índices estão frescos?" não
/// teria apanhado aquele dia; "o ficheiro que abre as portas responde?"
/// teria. Um alerta que só vigia o que já correu mal uma vez é um alerta que
/// aprende devagar demais.
///
/// **No máximo um aviso por hora**, e sem guardar estado em lado nenhum: só
/// dispara na batida em que o minuto é menor que cinco. O Worker não tem KV e
/// não vale uma tabela para isto; a mensagem diz há quanto tempo o problema
/// dura, portanto repetir de hora a hora informa em vez de incomodar.
async function vigiarOSite(env) {
  if (new Date().getUTCMinutes() >= 5) return;

  const problemas = [];

  let versoes = null;
  try {
    const resposta = await fetch(VERSOES_PUBLICADAS, { cache: 'no-store' });
    if (!resposta.ok) {
      problemas.push(
        `\`versoes.json\` responde **${resposta.status}** — o ecrã de ` +
          'escolha mostra as duas portas como *em breve* e ninguém entra.',
      );
    } else {
      versoes = await resposta.json();
      if (!versoes || Object.keys(versoes).length === 0) {
        problemas.push(
          '`versoes.json` veio vazio — as portas fecham do mesmo jeito.',
        );
      }
    }
  } catch (erro) {
    problemas.push(`não consegui ler \`versoes.json\`: ${erro}`);
  }

  for (const [chave, versao] of Object.entries(versoes || {})) {
    const colhido = Date.parse(versao?.coletadoEm ?? '');
    if (Number.isNaN(colhido)) {
      problemas.push(`**${chave}** não diz quando foi colhido.`);
      continue;
    }
    const parado = Date.now() - colhido;
    if (parado > VELHO_DEMAIS_MS) {
      const horas = Math.floor(parado / 3600000);
      const minutos = Math.round((parado % 3600000) / 60000);
      problemas.push(
        `**${chave}** está parado há ${horas}h${String(minutos).padStart(2, '0')}.`,
      );
    }
  }

  if (problemas.length === 0) return;

  const texto = ['⚠️ **O portalpw.net precisa de atenção**', ...problemas].join(
    '\n',
  );
  console.error(texto);

  // Sem webhook, o aviso fica no log do Worker e nada se perde em silêncio —
  // o mesmo recuo que o coletor faz quando lhe falta o segredo dos alertas.
  if (!env.DISCORD_ALERTAS) {
    console.error('sem DISCORD_ALERTAS: aviso ficou só no log.');
    return;
  }

  const enviado = await fetch(env.DISCORD_ALERTAS, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ content: texto.slice(0, 1900) }),
  });
  if (!enviado.ok) {
    console.error(`Discord recusou o aviso: ${enviado.status}`);
  }
}

async function ressuscitarColeta(env) {
  // Sem `status=completed`: as rodadas por terminar são metade da pergunta.
  // `per_page=20` porque agora a lista mistura as duas versões *e* os dois
  // estados, e ainda tem de sobrar histórico de cada versão depois de
  // filtrar.
  const resposta = await github(
    env,
    `/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?per_page=20`,
  );
  if (!resposta.ok) return;

  const { workflow_runs: todas = [] } = await resposta.json();
  if (!todas.length) return;

  const rodadas = todas.filter((rodada) => rodada.status === 'completed');
  if (!rodadas.length) return;

  const [ultima] = rodadas;
  if (ultima.conclusion !== 'failure') return;

  // A rodada completada anterior. **Já não há "da mesma versão"**: uma
  // corrida colhe todas, portanto duas falhas seguidas são simplesmente as
  // duas últimas — e duas seguidas não são soluço, é o relógio que assume.
  const anterior = rodadas[1];
  if (anterior?.conclusion === 'failure') {
    console.log('duas falhas seguidas: deixando o relógio assumir.');
    return;
  }

  const disparo = await github(
    env,
    `/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches`,
    'POST',
    { ref: 'main' },
  );
  console.log(`rodada ${ultima.id} falhou; redisparo ${disparo.status}`);
}

// Cancela rodada que ficou presa na fila, antes de pedir a próxima.
//
// **É o segundo modo de falha, e é pior que o primeiro.** Em 13/09 a rodada
// das 04:07 UTC ficou 1h40 esperando uma máquina do GitHub: sem runner, sem
// erro, sem nada vermelho. Como o workflow só deixa uma coleta por vez, ela
// segurou a vaga e as duas seguintes foram canceladas ao chegar atrás — o site
// ficou duas horas no mesmo índice. O `githubstatus.com` dizia *All Systems
// Operational* o tempo todo, e um job na fila só expira sozinho depois de 24
// horas, então sem alguém olhando o estrago seria de um dia.
//
// O conserto é o que foi feito à mão naquele dia: matar o job morto. No
// segundo seguinte a rodada seguinte pegou máquina.
async function destravarFila(env) {
  const resposta = await github(
    env,
    `/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?per_page=20`,
  );

  if (!resposta.ok) {
    // Não é motivo para desistir do disparo: no pior caso a fila continua
    // como estava, que é exatamente o que acontecia antes deste bloco existir.
    console.error(`não deu para ler a fila: ${resposta.status}`);
    return;
  }

  const { workflow_runs: rodadas = [] } = await resposta.json();
  const agora = Date.now();

  for (const rodada of rodadas) {
    if (!NA_FILA.has(rodada.status)) continue;
    const parada = agora - Date.parse(rodada.created_at);
    if (parada < PRESA_DEMAIS_MS) continue;

    const cancelamento = await github(
      env,
      `/repos/${REPO}/actions/runs/${rodada.id}/cancel`,
      'POST',
    );
    console.log(
      `rodada ${rodada.id} estava ${rodada.status} há ` +
        `${Math.round(parada / 60000)} min: cancelamento ${cancelamento.status}`,
    );
  }
}

// Uma chamada por dia ao Supabase, para o projeto não ser pausado.
//
// O plano gratuito pausa depois de 7 dias sem atividade, e a atividade vinha
// inteira dos visitantes: o site ficou quatro dias fechado em setembro e o
// aviso de pausa chegou. Pausado, some o contador e some o mapa — 52
// territórios, guildas e brasões — recuperáveis por 90 dias e não além.
//
// É `register_visit` por decisão do dono, ciente do custo: a chamada **soma
// uma visita por dia** ao contador, uns 365 por ano. `visit_total` faria o
// mesmo serviço sem escrever nada, e trocar é uma palavra aqui.
async function manterOBancoAcordado() {
  const resposta = await fetch(`${SUPABASE}/rpc/register_visit`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: '{}',
  });

  if (!resposta.ok) {
    // Cai no `wrangler tail`. Uma falha isolada não é urgência — há sete dias
    // de folga contra o limite —, mas sete falhas seguidas e em silêncio são
    // exatamente como o projeto seria pausado sem ninguém ver.
    console.error(
      `ping do Supabase recusado: ${resposta.status} ${await resposta.text()}`,
    );
    return;
  }
  console.log(`Supabase acordado; total de visitas: ${await resposta.text()}`);
}

// Pergunta à Twitch quem dos canais cadastrados está ao vivo e grava.
//
// **Uma falha nunca apaga ninguém.** Se a Twitch não responder, o certo é
// deixar a tabela como está e não gravar nada: marcar todo mundo offline
// transformaria um problema de rede numa afirmação falsa, e o carimbo
// `visto_em` já faz a página tratar dado velho como desconhecido. Ausência de
// resposta não é ausência de live.
async function atualizarQuemEstaAoVivo(env) {
  const canais = await canaisAtivos(env);
  if (!canais.length) return;

  const token = await tokenDaTwitch(env);
  if (!token) return;

  // Um pedido só resolve até cem canais, então a lista inteira cabe numa
  // chamada e vai caber por muito tempo.
  const busca = canais
    .map(({ canal }) => `user_login=${encodeURIComponent(canal)}`)
    .join('&');
  const resposta = await fetch(`https://api.twitch.tv/helix/streams?${busca}`, {
    headers: {
      'Client-Id': TWITCH_CLIENT_ID,
      Authorization: `Bearer ${token}`,
    },
  });

  if (!resposta.ok) {
    console.error(
      `Twitch recusou: ${resposta.status} ${await resposta.text()}`,
    );
    return;
  }

  const { data = [] } = await resposta.json();
  const aoVivo = new Map(
    data.map((s) => [String(s.user_login).toLowerCase(), s]),
  );
  const agora = new Date().toISOString();

  // Uma linha por canal, inclusive os que estão fora do ar — é assim que
  // alguém que acabou de encerrar volta a ser `false` em vez de ficar
  // eternamente ao vivo.
  const linhas = canais.map(({ canal, nome }) => {
    const live = aoVivo.get(canal);
    return {
      canal,
      // Sempre presente, nunca `undefined`.
      //
      // **O PostgREST exige que todos os objetos de um lote tenham as mesmas
      // chaves** — `All object keys must match`, PGRST102 — e `undefined`
      // some no `JSON.stringify`. Com um canal só isso nunca aparecia: um
      // objeto sozinho sempre combina consigo mesmo. Bastou o segundo, com um
      // ao vivo e outro não, para o lote inteiro ser recusado e ninguém ser
      // gravado.
      //
      // Offline mantém o nome que já estava: ele vem da Twitch, é estável, e
      // apagá-lo faria o card perder a grafia própria do streamer até a
      // próxima live.
      nome: live ? live.user_name : nome,
      ao_vivo: Boolean(live),
      titulo: live ? live.title : null,
      jogo: live ? live.game_name : null,
      espectadores: live ? live.viewer_count : null,
      // A miniatura vem com {width} e {height} para quem pede o tamanho.
      thumb: live
        ? String(live.thumbnail_url)
            .replace('{width}', '440')
            .replace('{height}', '248')
        : null,
      visto_em: agora,
    };
  });

  await gravarNoSupabase(env, linhas);
  console.log(`Twitch: ${aoVivo.size} de ${canais.length} ao vivo`);

  await batizarOsNovos(env, token, canais);
}

// Descobre o nome próprio de quem ainda não tem, e denuncia canal que não
// existe.
//
// **É o detector de erro de digitação.** O nome só chegaria pelo `/streams`,
// que só responde por quem está ao vivo — então um canal escrito errado
// ficaria offline para sempre, em silêncio, e ninguém saberia a diferença
// entre "não transmite" e "não existe". O `/users` responde sempre, e o login
// que ele não devolve é um login que não existe.
//
// Só para quem falta, então custa zero requisição no dia a dia: é uma chamada
// a mais na primeira rodada depois de alguém ser adicionado, e nunca mais.
async function batizarOsNovos(env, token, canais) {
  const semNome = canais.filter(({ nome }) => !nome);
  if (!semNome.length) return;

  const busca = semNome
    .map(({ canal }) => `login=${encodeURIComponent(canal)}`)
    .join('&');
  const resposta = await fetch(`https://api.twitch.tv/helix/users?${busca}`, {
    headers: {
      'Client-Id': TWITCH_CLIENT_ID,
      Authorization: `Bearer ${token}`,
    },
  });

  if (!resposta.ok) {
    console.error(`/users recusado: ${resposta.status}`);
    return;
  }

  const { data = [] } = await resposta.json();
  const achados = new Map(
    data.map((u) => [String(u.login).toLowerCase(), u.display_name]),
  );

  const inexistentes = semNome
    .map(({ canal }) => canal)
    .filter((canal) => !achados.has(canal));
  if (inexistentes.length) {
    console.error(
      `AVISO: a Twitch não conhece ${inexistentes.join(', ')} — ` +
        'provavelmente o login está escrito errado.',
    );
  }

  if (!achados.size) return;

  await gravarNoSupabase(
    env,
    [...achados].map(([canal, nome]) => ({ canal, nome })),
  );
  console.log(`nomes descobertos: ${[...achados.values()].join(', ')}`);
}

// Os canais ligados, com o nome que já se sabe deles.
//
// O nome vem junto porque a gravação precisa mandá-lo mesmo para quem está
// offline — ver o comentário em `nome` acima.
async function canaisAtivos(env) {
  const resposta = await supabase(
    env,
    '/canais_twitch?select=canal,nome&ativo=is.true',
  );
  if (!resposta.ok) {
    console.error(`não deu para ler os canais: ${resposta.status}`);
    return [];
  }
  return (await resposta.json()).map(({ canal, nome }) => ({
    canal,
    // `null` viraria a string "null" em nada, mas deixa a chave presente, que
    // é o que o lote exige.
    nome: nome ?? null,
  }));
}

// Um token de aplicativo, pedido a cada rodada.
//
// A Twitch recomenda guardar e reusar, e um Worker não tem onde guardar sem
// adicionar um KV só para isso. Um pedido a mais a cada cinco minutos é ruído
// perto do que a conta permite, e o que se ganha é não ter mais uma peça que
// pode ficar dessincronizada.
async function tokenDaTwitch(env) {
  const resposta = await fetch('https://id.twitch.tv/oauth2/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: TWITCH_CLIENT_ID,
      client_secret: env.TWITCH_SECRET,
      grant_type: 'client_credentials',
    }),
  });

  if (!resposta.ok) {
    // O primeiro lugar a olhar quando o banner sumir: um secret errado
    // responde 403 aqui e nada mais acontece.
    console.error(
      `token da Twitch recusado: ${resposta.status} ${await resposta.text()}`,
    );
    return null;
  }
  return (await resposta.json()).access_token;
}

// Grava as linhas por cima das que existem, casando por `canal`.
async function gravarNoSupabase(env, linhas) {
  const resposta = await supabase(env, '/canais_twitch?on_conflict=canal', {
    method: 'POST',
    // `merge-duplicates` é o upsert do PostgREST: sem isso, a segunda rodada
    // bate na chave única e não grava nada.
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: linhas,
  });

  if (!resposta.ok) {
    console.error(
      `Supabase recusou a gravação: ${resposta.status} ${await resposta.text()}`,
    );
  }
}

// A chave de serviço, que é a única que escreve.
//
// A tabela tem RLS com policy só de leitura, então a chave publicável do site
// não grava nada — de propósito. Esta fura o RLS e por isso vive no
// `wrangler secret`, nunca no repositório e nunca no navegador.
function supabase(env, caminho, { method = 'GET', prefer, body } = {}) {
  return fetch(`${SUPABASE}${caminho}`, {
    method,
    headers: {
      apikey: env.SUPABASE_SERVICE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      ...(prefer ? { Prefer: prefer } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

// Copia o canal de novidades do Discord para a tabela.
//
// **Uma falha não apaga nada**, pela mesma razão da Twitch: se o Discord não
// responder, o certo é deixar como está. Sumir com as novidades porque a rede
// falhou seria transformar um problema de rede numa página vazia.
async function lerAsNovidades(env) {
  const resposta = await fetch(
    `https://discord.com/api/v10/channels/${CANAL_DAS_NOVIDADES}` +
      `/messages?limit=${JANELA_DAS_NOVIDADES}`,
    { headers: { Authorization: `Bot ${env.DISCORD_TOKEN}` } },
  );

  if (!resposta.ok) {
    console.error(
      `Discord recusou: ${resposta.status} ${await resposta.text()}`,
    );
    return;
  }

  const mensagens = await resposta.json();
  const agora = new Date().toISOString();

  // Só mensagem de gente com texto. Entrada de membro, fixação e mensagem de
  // bot têm `type` diferente de 0 e não são novidade nenhuma.
  const uteis = mensagens.filter(
    (m) => m.type === 0 && !m.author?.bot && String(m.content || '').trim(),
  );

  if (uteis.length) {
    await gravarNoSupabase2(env, '/novidades?on_conflict=mensagem_id', uteis.map((m) => ({
      mensagem_id: m.id,
      autor: m.author?.global_name || m.author?.username || null,
      texto: String(m.content).trim(),
      // A data da mensagem, não a da leitura: ela não pode mudar porque o
      // Worker reiniciou.
      publicada_em: m.timestamp,
      visivel: true,
      vista_em: agora,
    })));
  }

  await esconderApagadas(env, mensagens, uteis);
  // Quantas vieram contra quantas serviram. As duas causas de "zero" se
  // parecem na tabela e não no log: canal errado devolve nenhuma mensagem,
  // e falta da intent de conteúdo devolve todas com o texto vazio.
  const comTexto = mensagens.filter((m) => String(m.content || '').trim()).length;
  console.log(
    `novidades: ${mensagens.length} vieram, ${comTexto} com texto, ` +
      `${uteis.length} aproveitadas`,
  );
}

// Some do site o que foi apagado no Discord.
//
// **Quando a leitura traz menos que o limite, o canal inteiro foi visto** — e
// aí não existe "fora de alcance": qualquer linha visível que não veio na
// resposta foi apagada. Foi o que a primeira versão errou: ela sempre exigia
// que a linha fosse mais nova que a mensagem mais velha da rodada, então num
// canal com duas mensagens o teste apagado ficava abaixo do piso e sobrevivia
// para sempre. Levou uma hora no ar para aparecer, porque o sintoma é a
// ausência de uma mudança.
//
// Com o limite cheio pode haver mensagem mais antiga que ninguém leu, e aí o
// piso volta a valer: sumir com uma linha por falta de informação seria
// apagar história sem decisão de ninguém.
async function esconderApagadas(env, mensagens, uteis) {
  if (!mensagens.length) return;

  const vivas = new Set(uteis.map((m) => m.id));
  const vimosTudo = mensagens.length < JANELA_DAS_NOVIDADES;

  // Snowflakes são texto nesta coluna, então `gte` compara como string. Isso
  // só acerta porque todos têm o mesmo comprimento — verdade desde 2016 e por
  // muitos anos ainda, mas é a razão de o piso existir só quando precisa.
  const piso = vimosTudo
    ? ''
    : `&mensagem_id=gte.${mensagens[mensagens.length - 1].id}`;

  const r = await supabase(
    env,
    `/novidades?select=mensagem_id&visivel=is.true${piso}`,
  );
  if (!r.ok) return;

  const sumidas = (await r.json())
    .map((linha) => linha.mensagem_id)
    .filter((id) => !vivas.has(id));
  if (!sumidas.length) return;

  await supabase(
    env,
    `/novidades?mensagem_id=in.(${sumidas.join(',')})`,
    { method: 'PATCH', prefer: 'return=minimal', body: { visivel: false } },
  );
  console.log(`novidades apagadas no Discord: ${sumidas.length}`);
}

// Grava em qualquer tabela, com o mesmo upsert que os streamers usam.
async function gravarNoSupabase2(env, caminho, linhas) {
  const r = await supabase(env, caminho, {
    method: 'POST',
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: linhas,
  });
  if (!r.ok) {
    console.error(`Supabase recusou: ${r.status} ${await r.text()}`);
  }
}

function github(env, caminho, method = 'GET', body) {
  return fetch(`https://api.github.com${caminho}`, {
    method,
    headers: {
      Authorization: `Bearer ${env.GITHUB_TOKEN}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      // A API do GitHub recusa pedido sem User-Agent, com 403 e sem explicar —
      // vale mais que o comentário parece.
      'User-Agent': 'portalpw-cron',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

// ── Vídeos de guerra ────────────────────────────────────────────────────────
//
// Lê os feeds RSS dos canais em `canais_youtube` e avisa no Discord o que há
// de novo — e o que **deixou de existir**.
//
// **Avisa, não insere, e isso é decisão e não preguiça.** Três coisas que uma
// linha de `videos` precisa não saem do feed de forma fiável:
//
//   1. **TW não é a única guerra.** Os mesmos canais publicam NW, GVG, Soldo,
//      Mini TW e vídeos de build. A 02/11/2026, ao levantar isto à mão, cinco
//      vídeos foram descartados por isso. O título dá um palpite, não uma
//      certeza.
//   2. **A data da guerra não é a data do upload.** O LeoBiju publicou a 27/10
//      uma guerra de 24/10. Gravar o upload poria o vídeo na noite errada.
//   3. **A classe e o personagem não estão no feed.** Vêm da tabela de canais,
//      e é por isso que ela os guarda — mas um canal pode publicar o vídeo de
//      outra pessoa, e aí só quem lê é que sabe.
//
// Um job que adivinhasse as três erraria em silêncio. Este propõe e espera.
//
// **E olha nos dois sentidos, o que custou um defeito para aprender.** A
// 02/11 inseri o vídeo do WinX-Sombrao; a 03/11 ele já respondia 404 — apagado
// ou tornado privado em menos de um dia. Um cartão morto no site é pior do
// que um cartão a menos, e ninguém ia reparar.
const FEED_YOUTUBE = 'https://www.youtube.com/feeds/videos.xml?channel_id=';

// **A marca é negativa: ➖ só com prova de que é outra coisa.**
//
// A primeira versão exigia a palavra *TW* no título, e medida contra os
// feeds reais a 03/11/2026 reprovou sete vídeos do Mozaum que são todos
// guerra territorial — ele escreve «Ragnarok x Nexus 31/10/2026» e mais
// nada. Exigir a palavra punha o trabalho todo de volta em quem lê.
//
// «Mini TW» tem *TW* lá dentro e não é, e é por isso que esta lista existe
// e ganha.
//
// **O canal do Fezinho acrescentou cinco provas de uma vez, a 08/11/2026.**
// Ele foi o décimo-terceiro canal a entrar, e medir a regra contra o feed
// dele deu **sete anúncios para dois vídeos certos** — cinco de ruído. O
// que faltava não era afinação: eram três famílias inteiras.
//
// *Guerra Celeste* é outro evento, e escreve-se nas duas línguas —
// `Celeste War` e `Guerra Celestial` no mesmo canal. *PW NH* é outro
// servidor, e `1.8.8` é outra versão: nenhum dos dois é guerra nossa, por
// mais TW que haja no vídeo. E `War of the Nations` é a *Nation War* por
// extenso, que a lista já tinha na forma curta — a mesma coisa escrita de
// um jeito que a regra não via.
//
// A lição é a de sempre aqui: a prova vem do feed, nunca do palpite. Cada
// termo abaixo saiu de um título real.
const NAO_E_TW =
  /\b(mini.?tw|nw|nation war|war of the nations|guerra das na|gvg|soldo|arena|x1|evento|arte(s)? marciai|como |build|guerra celes|celes\w* war|macroplayer|pw nh|1\.8\.8)/i;

async function procurarVideosDeGuerra(env) {
  const canais = await lerCanaisDoYoutube(env);
  if (canais.length === 0) {
    console.error('nenhum canal activo em canais_youtube.');
    return;
  }

  const conhecidos = await lerVideosConhecidos(env);
  if (conhecidos === null) {
    // Sem a lista do que já temos, tudo pareceria novo. Calar é o certo.
    console.error('não deu para ler a tabela videos; nada a avisar.');
    return;
  }

  const novos = [];
  const mudos = [];

  for (const canal of canais) {
    const entradas = await lerFeed(canal.canal);
    if (entradas === null) {
      mudos.push(canal.nome);
      continue;
    }
    await marcarCanalVisto(env, canal.canal);

    for (const e of entradas) {
      if (conhecidos.has(e.id)) continue;
      // Só o que subiu nos últimos dez dias: o feed traz quinze vídeos por
      // canal e alguns canais têm anos de histórico. Sem este corte, o
      // primeiro aviso teria cento e vinte e oito linhas.
      if (diasDesde(e.publicado) > 10) continue;
      novos.push({ ...e, canal });
    }
  }

  const mortos = await procurarVideosMortos(env);
  await contarOsVideos(env, novos, mortos, mudos);
}

// Os vídeos visíveis que o YouTube já não serve.
//
// **Só esconde com um 404 na mão.** Uma falha de rede não é prova de que o
// vídeo morreu, e marcar como ausente o que apenas não respondeu seria
// transformar um problema de rede numa afirmação falsa — a mesma regra que a
// Twitch já segue aqui.
async function procurarVideosMortos(env) {
  const resposta = await supabase(
    env,
    '/videos?select=id,youtube,personagem,data&visivel=is.true',
  );
  if (!resposta.ok) return [];

  const mortos = [];
  for (const v of await resposta.json()) {
    const existe = await videoExiste(v.youtube);
    if (existe !== false) continue;
    const escondido = await supabase(env, `/videos?id=eq.${v.id}`, {
      method: 'PATCH',
      body: { visivel: false },
    });
    mortos.push({ ...v, escondido: escondido.ok });
  }
  return mortos;
}

// `true` existe, `false` não existe, `null` não deu para saber.
async function videoExiste(id) {
  try {
    const r = await fetch(
      `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${id}&format=json`,
    );
    if (r.status === 404) return false;
    if (r.ok) return true;
    return null;
  } catch (erro) {
    console.error(`oembed falhou para ${id}: ${erro}`);
    return null;
  }
}

async function lerCanaisDoYoutube(env) {
  const r = await supabase(
    env,
    '/canais_youtube?select=canal,nome,personagem,classe&ativo=is.true',
  );
  if (!r.ok) {
    console.error(`canais_youtube respondeu ${r.status}`);
    return [];
  }
  return r.json();
}

async function lerVideosConhecidos(env) {
  // **Inclui os invisíveis de propósito.** Um vídeo escondido por ter morrido
  // continua conhecido; sem isto, o aviso voltaria a propô-lo todos os dias.
  const r = await supabase(env, '/videos?select=youtube');
  if (!r.ok) return null;
  return new Set((await r.json()).map((v) => v.youtube));
}

async function lerFeed(canal) {
  try {
    const r = await fetch(FEED_YOUTUBE + canal);
    if (!r.ok) return null;
    const xml = await r.text();
    const entradas = [];
    for (const bloco of xml.split('<entry>').slice(1)) {
      const id = entre(bloco, '<yt:videoId>', '</yt:videoId>');
      const titulo = entre(bloco, '<title>', '</title>');
      const publicado = entre(bloco, '<published>', '</published>');
      if (id && publicado) entradas.push({ id, titulo, publicado });
    }
    return entradas;
  } catch (erro) {
    console.error(`feed de ${canal} falhou: ${erro}`);
    return null;
  }
}

function entre(texto, abre, fecha) {
  const i = texto.indexOf(abre);
  if (i < 0) return '';
  const j = texto.indexOf(fecha, i + abre.length);
  return j < 0 ? '' : texto.slice(i + abre.length, j);
}

function diasDesde(iso) {
  return (Date.now() - new Date(iso).getTime()) / 86400000;
}

// A data que o título anuncia, que é a da guerra — não a do upload.
//
// Aceita `31/10`, `31.10.26`, `01/11/2026` e `24.10.26`. Devolve `null` quando
// não encontra, e **isso é melhor do que devolver o upload**: um palpite
// marcado como palpite custa uma pergunta, um palpite disfarçado de facto
// põe o vídeo na noite errada.
function dataNoTitulo(titulo, publicado) {
  // **Tenta todos os candidatos e aceita o primeiro que faz sentido** — em
  // vez de tentar limpar a versão do jogo antes de procurar.
  //
  // A primeira versão apagava `\d+.\d+.\d+` para se livrar de «The Classic
  // PW 1.8.7», que casava como 1 de Agosto. Medida a 03/11/2026 contra os
  // feeds reais, essa limpeza **apagava também as datas**: `24.10.26` e
  // `25.10.26` têm exactamente a mesma forma que `1.8.7`, e três títulos
  // perderam a data que tinham.
  //
  // Não há como distinguir os dois pela forma, e por isso nem se tenta. O
  // que distingue é o resultado: `1.8.7` lido como data dá 1 de Agosto, a
  // noventa dias do upload, e cai na mesma prova que já existia. Varrer os
  // candidatos pela ordem e ficar com o primeiro plausível resolve os dois
  // casos com uma regra só.
  const padrao = /\b(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?\b/g;
  const subida = new Date(publicado).getTime();

  for (const m of titulo.matchAll(padrao)) {
    const dia = Number(m[1]);
    const mes = Number(m[2]);
    if (dia < 1 || dia > 31 || mes < 1 || mes > 12) continue;
    let ano = m[3] ? Number(m[3]) : new Date(publicado).getUTCFullYear();
    if (ano < 100) ano += 2000;
    const d = `${ano}-${String(mes).padStart(2, '0')}-${String(dia).padStart(2, '0')}`;

    // A guerra vem antes do upload, e não muito antes. Isto é o que recusa a
    // versão do jogo, e também o que apanha um título mal escrito: o
    // «31.11.2026» do Sombrão é um dia que não existe, e o `Date` devolve 1
    // de Dezembro — distante do upload, portanto recusado.
    const dist = (subida - new Date(d + 'T12:00:00Z').getTime()) / 86400000;
    if (Number.isNaN(dist) || dist < -1 || dist > 30) continue;
    // Guarda contra o 31 de Novembro e companhia: se o `Date` normalizou
    // para outro dia, a data escrita não existe.
    const voltou = new Date(d + 'T12:00:00Z').toISOString().slice(0, 10);
    if (voltou !== d) continue;
    return d;
  }
  return null;
}

async function marcarCanalVisto(env, canal) {
  await supabase(env, `/canais_youtube?canal=eq.${encodeURIComponent(canal)}`, {
    method: 'PATCH',
    body: { visto_em: new Date().toISOString() },
  });
}

async function contarOsVideos(env, novos, mortos, mudos) {
  if (novos.length === 0 && mortos.length === 0 && mudos.length === 0) {
    console.log('vídeos de guerra: nada novo, nada morto.');
    return;
  }

  const linhas = [];

  if (novos.length > 0) {
    // Os que parecem TW primeiro, porque são os que pedem acção.
    const ordenados = [...novos].sort(
      (a, b) => Number(ehTW(b.titulo)) - Number(ehTW(a.titulo)),
    );
    linhas.push(`🎥 **${novos.length} vídeo(s) novo(s)**`);
    for (const v of ordenados.slice(0, 12)) {
      const data = dataNoTitulo(v.titulo, v.publicado);
      const marca = ehTW(v.titulo) ? '🗡️' : '➖';
      linhas.push(
        `${marca} **${v.canal.personagem}** (${v.canal.classe}) · ` +
          `${data ?? '`data?`'} · <https://youtu.be/${v.id}>\n` +
          `    ${v.titulo.slice(0, 90)}`,
      );
    }
    if (ordenados.length > 12) {
      // Nunca cortar em silêncio: um aviso que esconde metade ensina a
      // confiar no número errado.
      linhas.push(`… e mais ${ordenados.length - 12} não listados.`);
    }
    linhas.push('🗡️ parece TW · ➖ parece NW, GVG, Soldo ou outra coisa');
  }

  if (mortos.length > 0) {
    linhas.push(`\n💀 **${mortos.length} vídeo(s) do site deixaram de existir**`);
    for (const v of mortos.slice(0, 8)) {
      linhas.push(
        `• ${v.personagem} · ${v.data} · \`${v.youtube}\`` +
          (v.escondido ? ' — escondido' : ' — **não deu para esconder**'),
      );
    }
  }

  if (mudos.length > 0) {
    linhas.push(`\n🔇 Sem resposta: ${mudos.join(', ')}`);
  }

  const texto = linhas.join('\n');
  console.log(texto);

  if (!env.DISCORD_ALERTAS) {
    console.error('sem DISCORD_ALERTAS: aviso dos vídeos ficou só no log.');
    return;
  }
  const enviado = await fetch(env.DISCORD_ALERTAS, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ content: texto.slice(0, 1900) }),
  });
  if (!enviado.ok) {
    console.error(`Discord recusou o aviso dos vídeos: ${enviado.status}`);
  }
}

function ehTW(titulo) {
  return !NAO_E_TW.test(titulo);
}
