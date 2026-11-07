import { PrologError } from './prolog.js'

// Un nombre valido es un atomo Prolog simple: ana, llave_maestra, sala2.
const NOMBRE = /^[a-z][a-zA-Z0-9_]{0,63}$/

// Predicados que se pueden pedir por POST /api/consulta y cuantos argumentos llevan.
const PREDICADOS = {
  personas: 0,
  lugares: 0,
  objetos: 0,
  evento: 0,
  posibles_responsables: 0,
  resolver_caso: 0,
  movimientos: 1,
  explicaciones: 1,
  tiene_coartada: 1,
  tiene_contradiccion: 1,
  posible_sospechoso: 1,
  tiene_acceso: 2,
}

// Directivas que puede traer un archivo de hechos sin ejecutar codigo.
const DIRECTIVAS_PERMITIDAS = /(^|\.)\s*:-\s*(dynamic|discontiguous|encoding)\b/g

export function validarNombre(valor, campo = 'nombre') {
  if (typeof valor !== 'string' || !NOMBRE.test(valor)) {
    throw new PrologError(`${campo} invalido: debe ser un atomo en minuscula (ej. ana, llave_maestra)`, 400)
  }
  return valor
}

// Middleware para app.param: valida :persona y :lugar antes de llegar a Prolog.
export const validarParametro = (req, res, next, valor, campo) => {
  validarNombre(valor, campo)
  next()
}

export function validarConsulta(cuerpo) {
  const { predicado, args = [] } = cuerpo ?? {}
  if (!Object.hasOwn(PREDICADOS, predicado)) {
    throw new PrologError(`Predicado no permitido: ${predicado}`, 400)
  }
  if (!Array.isArray(args) || args.length !== PREDICADOS[predicado]) {
    throw new PrologError(`${predicado} espera ${PREDICADOS[predicado]} argumento(s)`, 400)
  }
  return { predicado, args: args.map((a, i) => validarNombre(a, `args[${i}]`)) }
}

// Un archivo de hechos solo puede tener hechos: se rechazan reglas (:-) y
// directivas que ejecuten codigo al cargarse, salvo dynamic/discontiguous/encoding.
export function validarHechos(contenido) {
  if (typeof contenido !== 'string' || contenido.trim() === '') {
    throw new PrologError('Debe enviar el contenido del archivo de hechos', 400)
  }
  const codigo = contenido
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/"(\\.|[^"\\])*"/g, '""')
    .replace(/'(\\.|[^'\\])*'/g, "''")
    .replace(/%.*$/gm, ' ')

  const total = (codigo.match(/:-|\?-/g) ?? []).length
  const permitidas = (codigo.match(DIRECTIVAS_PERMITIDAS) ?? []).length
  if (total > permitidas) {
    throw new PrologError('El archivo solo puede contener hechos (no reglas ni directivas que ejecuten codigo)', 400)
  }
  return contenido
}

export function nombreArchivo(nombre) {
  const limpio = String(nombre ?? 'hechos.pl').split(/[\\/]/).pop().slice(0, 100)
  return limpio || 'hechos.pl'
}
