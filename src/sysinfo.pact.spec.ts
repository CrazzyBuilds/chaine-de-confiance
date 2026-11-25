import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import { MatchersV3, PactV3, Verifier } from '@pact-foundation/pact';
import { once } from 'node:events';
import { Server } from 'node:http';
import { AddressInfo } from 'node:net';
import path from 'node:path';
import { createServer } from './server';
import { fetchSysInfoSummary } from './sysinfo-client';

const { like } = MatchersV3;

const CONSUMER = 'sysinfo-client';
const PROVIDER = 'sysinfo-api';
const PACT_DIR = path.resolve(__dirname, '../pacts');
const PACT_FILE = path.join(PACT_DIR, `${CONSUMER}-${PROVIDER}.json`);

describe('pact contract', () => {
  // 1. Côté consumer : Pact simule le serveur et génère le contrat
  describe('consumer side', () => {
    const provider = new PactV3({
      consumer: CONSUMER,
      provider: PROVIDER,
      dir: PACT_DIR,
      logLevel: 'error',
    });

    it('should read a summary from the sysinfo API', async () => {
      expect.assertions(1);

      // like() : on vérifie le type du champ, pas sa valeur exacte
      provider
        .uponReceiving('a request for system information')
        .withRequest({ method: 'GET', path: '/api/v1/sysinfo' })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            cpu: { brand: like('Intel Core i7'), cores: like(8) },
            mem: { total: like(16000000000), used: like(8000000000) },
            currentLoad: { currentLoad: like(12.5) },
          },
        });

      await provider.executeTest(async (mockServer) => {
        await expect(
          fetchSysInfoSummary(mockServer.url),
        ).resolves.toStrictEqual({
          cpu: 'Intel Core i7',
          cores: 8,
          memoryUsedPercent: 50,
          load: 12.5,
        });
      });
    });
  });

  // 2. Côté provider : Pact rejoue le contrat contre le vrai serveur
  describe('provider side', () => {
    let server: Server;
    let baseUrl: string;

    beforeAll(async () => {
      server = createServer().listen(0);
      await once(server, 'listening');
      baseUrl = `http://localhost:${(server.address() as AddressInfo).port}`;
    });

    afterAll(() => {
      server.close();
    });

    it('should honour the contract', async () => {
      expect.assertions(1);

      const verifier = new Verifier({
        provider: PROVIDER,
        providerBaseUrl: baseUrl,
        pactUrls: [PACT_FILE],
        logLevel: 'error',
      });

      await expect(verifier.verifyProvider()).resolves.toBeDefined();
    }, 30000);
  });
});
