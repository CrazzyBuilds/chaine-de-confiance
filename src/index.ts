import { createServer } from './server';

const PORT = Number(process.env.PORT) || 8000;

createServer().listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
