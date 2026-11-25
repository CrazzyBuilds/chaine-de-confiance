import si from 'systeminformation';
import { ISystemInformation } from './ISystemInformation';

/**
 * Collecte les informations système de la machine hôte.
 * Les appels sont lancés en parallèle pour réduire la latence.
 */
export async function getSystemInformation(): Promise<ISystemInformation> {
  const [
    cpu,
    system,
    mem,
    os,
    currentLoad,
    processes,
    diskLayout,
    networkInterfaces,
  ] = await Promise.all([
    si.cpu(),
    si.system(),
    si.mem(),
    si.osInfo(),
    si.currentLoad(),
    si.processes(),
    si.diskLayout(),
    si.networkInterfaces(),
  ]);

  return {
    cpu,
    system,
    mem,
    os,
    currentLoad,
    processes,
    diskLayout,
    networkInterfaces,
  };
}
