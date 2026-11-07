import { execFile } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const directorio = path.dirname(fileURLToPath(import.meta.url))
const API = path.join(directorio, 'componentes', 'api.pl')
const SWIPL = process.env.SWIPL ?? 'swipl'

export class PrologError extends Error {
  constructor(mensaje, estado = 500) {
    super(mensaje)
    this.estado = estado
  }
}

// Ejecuta `swipl api.pl <accion> <args...>`. Los argumentos van como argv,
// nunca se arma una consulta Prolog con texto del usuario.
export function ejecutar(accion, args = [], hechos = null) {
  const env = { ...process.env }
  if (hechos) env.HECHOS_PL = hechos
  else delete env.HECHOS_PL

  return new Promise((resolve, reject) => {
    execFile(SWIPL, [API, accion, ...args], { env, timeout: 10000, windowsHide: true },
      (error, stdout, stderr) => {
        if (error && error.code === 'ENOENT') {
          return reject(new PrologError('No se encontro swipl; revise el PATH o la variable SWIPL'))
        }
        let datos
        try {
          datos = JSON.parse(stdout)
        } catch {
          return reject(new PrologError(`Prolog no devolvio JSON valido: ${stderr.trim()}`))
        }
        resolve({ ok: !error, datos, stderr })
      })
  })
}

export async function consultar(accion, args = [], hechos = null) {
  const { ok, datos } = await ejecutar(accion, args, hechos)
  if (!ok) {
    const estado = String(datos.error).startsWith('Persona no encontrada') ? 404 : 400
    throw new PrologError(datos.error ?? 'Error en Prolog', estado)
  }
  return datos
}
