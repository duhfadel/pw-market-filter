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
