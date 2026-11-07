import express from 'express'
import { mkdir, rename, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { consultar, ejecutar, PrologError } from './prolog.js'

const directorio = path.dirname(fileURLToPath(import.meta.url))
const CASOS = path.join(directorio, 'casos')
const PUERTO = Number(process.env.PORT ?? 3001)

// Caso cargado desde el frontend; null significa el hechos.pl original.
let caso = null

const app = express()
app.use(express.json({ limit: '1mb' }))

// Crea un manejador GET que traduce parametros de la ruta a una accion de api.pl.
const accion = (nombre, ...parametros) => async (req, res) => {
  const args = parametros.map(p => req.params[p])
  res.json(await consultar(nombre, args, caso?.ruta))
}

app.get('/api/personas', accion('personas'))
app.get('/api/lugares', accion('lugares'))
app.get('/api/objetos', accion('objetos'))
app.get('/api/evento', accion('evento'))
app.get('/api/posibles_responsables', accion('posibles_responsables'))
app.get('/api/resolver_caso', accion('resolver_caso'))

app.get('/api/personas/:persona/movimientos', accion('movimientos', 'persona'))
app.get('/api/personas/:persona/explicaciones', accion('explicaciones', 'persona'))
app.get('/api/personas/:persona/coartada', accion('tiene_coartada', 'persona'))
app.get('/api/personas/:persona/contradiccion', accion('tiene_contradiccion', 'persona'))
app.get('/api/personas/:persona/sospechoso', accion('posible_sospechoso', 'persona'))
app.get('/api/personas/:persona/acceso/:lugar', accion('tiene_acceso', 'persona', 'lugar'))

// Consulta generica: { "predicado": "tiene_coartada", "args": ["ana"] }.
// api.pl solo acepta los predicados de su lista de acciones.
app.post('/api/consulta', async (req, res) => {
  const { predicado, args = [] } = req.body ?? {}
  res.json(await consultar(String(predicado), args.map(String), caso?.ruta))
})

app.get('/api/caso', (req, res) => {
  res.json(caso ? { origen: 'cargado', nombre: caso.nombre } : { origen: 'original', nombre: 'hechos.pl' })
})

// Recibe el contenido de un hechos.pl: { "nombre": "caso2.pl", "contenido": "persona(ana). ..." }.
// Se prueba en un archivo temporal y solo se activa si Prolog lo carga sin errores.
app.post('/api/caso', async (req, res) => {
  const { nombre = 'hechos.pl', contenido } = req.body ?? {}
  if (typeof contenido !== 'string' || contenido.trim() === '') {
    throw new PrologError('Debe enviar el contenido del archivo de hechos', 400)
  }

  await mkdir(CASOS, { recursive: true })
  const prueba = path.join(CASOS, 'prueba.pl')
  const actual = path.join(CASOS, 'actual.pl')
  await writeFile(prueba, contenido, 'utf8')

  const { ok, stderr } = await ejecutar('personas', [], prueba)
  if (!ok || /ERROR/.test(stderr)) {
    throw new PrologError(`El archivo no se pudo cargar en Prolog: ${stderr.trim()}`, 400)
  }

  await rename(prueba, actual)
  caso = { nombre: String(nombre), ruta: actual }
  res.json({ origen: 'cargado', nombre: caso.nombre, personas: await consultar('personas', [], actual) })
})

app.post('/api/caso/original', (req, res) => {
  caso = null
  res.json({ origen: 'original', nombre: 'hechos.pl' })
})

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' })
})

app.use((error, req, res, next) => {
  if (!(error instanceof PrologError)) console.error(error)
  res.status(error.estado ?? 500).json({ error: error.message })
})

app.listen(PUERTO, '127.0.0.1', () => {
  console.log(`Servidor en http://127.0.0.1:${PUERTO}`)
})
