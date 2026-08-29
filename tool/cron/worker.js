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

export default {
  async scheduled(event, env, ctx) {
    const resposta = await fetch(
      `https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.GITHUB_TOKEN}`,
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          // A API do GitHub recusa pedido sem User-Agent, com 403 e sem
          // explicar — vale mais que o comentário parece.
          'User-Agent': 'portalpw-cron',
        },
        body: JSON.stringify({ ref: 'main' }),
      },
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
