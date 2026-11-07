// Cliente del puente Express. Toda la logica esta en Prolog: aqui solo se
// envian los parametros del usuario y se devuelven las respuestas.
const SIN_SERVIDOR = 'No se pudo conectar con el servidor. Ejecute "npm start" en la carpeta server.'

async function pedir(ruta, opciones) {
  let respuesta
  try {
    respuesta = await fetch(`/api${ruta}`, opciones)
  } catch {
    throw new Error(SIN_SERVIDOR)
  }

  const datos = await respuesta.json().catch(() => null)
  if (!respuesta.ok) throw new Error(datos?.error ?? SIN_SERVIDOR)
  return datos
}

export const obtener = ruta => pedir(ruta)

export const enviar = (ruta, cuerpo = {}) =>
  pedir(ruta, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cuerpo),
  })
