import http from 'node:http';
import { getSystemInformation } from './stats';

const SYSINFO_PATH = '/api/v1/sysinfo';

function sendJson(
  res: http.ServerResponse,
  status: number,
  body: unknown,
): void {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

/**
 * Crée le serveur HTTP sans le démarrer (listen est appelé par l'appelant),
 * ce qui permet de le lancer sur un port aléatoire dans les tests.
 */
export function createServer(): http.Server {
  return http.createServer(async (req, res) => {
    if (req.method === 'GET' && req.url === SYSINFO_PATH) {
      try {
        sendJson(res, 200, await getSystemInformation());
      } catch {
        sendJson(res, 500, { error: 'Internal Server Error' });
      }
      return;
    }

    sendJson(res, 404, { error: 'Not Found', path: req.url });
  });
}
