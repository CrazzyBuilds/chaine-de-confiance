import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import { once } from 'node:events';
import { Server } from 'node:http';
import { AddressInfo } from 'node:net';
import { createServer } from './server';

describe('http server', () => {
  let server: Server;
  let baseUrl: string;

  // Démarre le serveur une fois pour toute la suite, sur un port libre (port 0)
  beforeAll(async () => {
    server = createServer().listen(0);
    await once(server, 'listening');
    baseUrl = `http://localhost:${(server.address() as AddressInfo).port}`;
  });

  afterAll(() => {
    server.close();
  });

  it('should return all system information fields on GET /api/v1/sysinfo', async () => {
    expect.assertions(3);

    const res = await fetch(`${baseUrl}/api/v1/sysinfo`);
    const body = (await res.json()) as Record<string, unknown>;

    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('application/json');
    // L'ordre des clés n'a pas de sens en JSON : on compare la liste triée
    expect(Object.keys(body).sort()).toStrictEqual([
      'cpu',
      'currentLoad',
      'diskLayout',
      'mem',
      'networkInterfaces',
      'os',
      'processes',
      'system',
    ]);
  });

  it('should return 404 on an unknown path', async () => {
    expect.assertions(1);

    const res = await fetch(`${baseUrl}/unknown`);

    expect(res.status).toBe(404);
  });
});
