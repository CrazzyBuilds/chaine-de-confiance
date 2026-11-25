import { createServer } from './server';

const PORT = Number(process.env.PORT) || 8000;

const server = createServer().listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});

// Dans un conteneur, l'API est PID 1 : sans gestionnaire, le noyau ne lui
// transmet pas SIGTERM, et `docker stop` (10 s) ou Kubernetes (30 s) attend
// la fin du délai de grâce avant d'envoyer SIGKILL. On s'arrête proprement :
// plus de nouvelles connexions, on finit les requêtes en cours, puis on sort.
process.on('SIGTERM', () => {
  console.log('SIGTERM reçu : arrêt propre');
  server.close(() => process.exit(0));
  server.closeIdleConnections();
});
