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

// O cron da coleta. O outro, o do Supabase, é qualquer coisa que não seja
// este — comparar contra o que acorda o Worker é o que separa as duas tarefas.
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
      return;
    }

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
      // urgência — a próxima meia hora tenta de novo, e a data da coleta no
      // site é o que denuncia se pararem todos.
      console.error(
        `disparo recusado: ${resposta.status} ${await resposta.text()}`,
      );
    }
  },
};

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
// Só dentro da janela lida: uma linha mais antiga que a mensagem mais velha
// desta rodada simplesmente saiu do alcance, e sumir com ela seria apagar
// história por falta de informação, não por decisão de ninguém.
async function esconderApagadas(env, mensagens, uteis) {
  if (!mensagens.length) return;

  const maisVelha = mensagens[mensagens.length - 1].id;
  const vivas = new Set(uteis.map((m) => m.id));

  const r = await supabase(
    env,
    `/novidades?select=mensagem_id&visivel=is.true&mensagem_id=gte.${maisVelha}`,
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
