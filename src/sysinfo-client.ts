import { ISystemInformation } from './ISystemInformation';

export interface SysInfoSummary {
  cpu: string;
  cores: number;
  memoryUsedPercent: number;
  load: number;
}

/**
 * Client de l'API sysinfo (le "consumer" pour Pact).
 * Il n'utilise qu'une partie des champs renvoyés par le serveur.
 */
export async function fetchSysInfoSummary(
  baseUrl: string,
): Promise<SysInfoSummary> {
  const res = await fetch(`${baseUrl}/api/v1/sysinfo`);
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}`);
  }

  const data = (await res.json()) as ISystemInformation;

  return {
    cpu: data.cpu.brand,
    cores: data.cpu.cores,
    memoryUsedPercent: Math.round((data.mem.used / data.mem.total) * 100),
    load: data.currentLoad.currentLoad,
  };
}
