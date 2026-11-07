import { useEffect, useRef, useState } from 'react'
import { enviar, obtener } from './api.js'
import { formatoHora } from './formato.js'
import PixelLupa from './PixelLupa.jsx'
import './inicio.css'

const consultarCaso = () => Promise.all([obtener('/caso'), obtener('/evento')])

function Inicio({ onIniciar }) {
  const [caso, setCaso] = useState(null)
  // undefined: aun no se consulta; null: el caso no tiene evento central.
  const [evento, setEvento] = useState(undefined)
  const [mensaje, setMensaje] = useState(null)
  const [ocupado, setOcupado] = useState(false)
  const selectorArchivo = useRef(null)

  const actualizarCaso = async () => {
    const [infoCaso, infoEvento] = await consultarCaso()
    setCaso(infoCaso)
    setEvento(infoEvento)
  }

  useEffect(() => {
    // Se ignora la respuesta si la pantalla se desmonto antes de que llegara.
    let activa = true
    consultarCaso()
      .then(([infoCaso, infoEvento]) => {
        if (!activa) return
        setCaso(infoCaso)
        setEvento(infoEvento)
      })
      .catch(error => {
        if (activa) setMensaje({ tipo: 'error', texto: error.message })
      })
    return () => {
      activa = false
    }
  }, [])

  // Ejecuta una accion contra el servidor mostrando su resultado o su error.
  const ejecutar = async accion => {
    setOcupado(true)
    setMensaje(null)
    try {
      setMensaje({ tipo: 'ok', texto: await accion() })
      await actualizarCaso()
    } catch (error) {
      setMensaje({ tipo: 'error', texto: error.message })
    } finally {
      setOcupado(false)
    }
  }

  const cargarArchivo = event => {
    const archivo = event.target.files[0]
    event.target.value = ''
    if (!archivo) return

    ejecutar(async () => {
      const contenido = await archivo.text()
      const respuesta = await enviar('/caso', { nombre: archivo.name, contenido })
      return `Caso "${respuesta.nombre}" cargado con ${respuesta.personas.length} personas.`
    })
  }

  const usarOriginal = () =>
    ejecutar(async () => {
      await enviar('/caso/original')
      return 'Se volvio al caso original.'
    })

  return (
    <main className="fondo pixel-panel">
      <PixelLupa />
      <h1>Academia Detectives</h1>
      <h2 className="inicio__lema">Cada pista es un hecho y Prolog deduce el caso</h2>

      <section className="inicio__caso" aria-live="polite">
        <h3>Caso actual</h3>
        {caso ? (
          <p>
            {caso.origen === 'original' ? 'Original' : 'Cargado'}: {caso.nombre}
          </p>
        ) : (
          <p>Conectando con Prolog...</p>
        )}
        {evento && (
          <p>
            Evento: {evento.nombre} en {evento.lugar} a las {formatoHora(evento.hora)}
          </p>
        )}
        {evento === null && <p>Este caso no tiene un evento central definido.</p>}
      </section>

      {mensaje && (
        <p className={`mensaje mensaje--${mensaje.tipo}`} role={mensaje.tipo === 'error' ? 'alert' : 'status'}>
          {mensaje.texto}
        </p>
      )}

      <div className="inicio__acciones">
        <button type="button" className="pixel-btn" onClick={onIniciar} disabled={!caso || ocupado}>
          Iniciar caso
        </button>
        <button
          type="button"
          className="pixel-btn pixel-btn--secundario"
          onClick={() => selectorArchivo.current.click()}
          disabled={ocupado}
        >
          Cargar archivo
        </button>
        {caso?.origen === 'cargado' && (
          <button type="button" className="pixel-btn pixel-btn--secundario" onClick={usarOriginal} disabled={ocupado}>
            Caso original
          </button>
        )}
        <input
          ref={selectorArchivo}
          type="file"
          accept=".pl"
          hidden
          aria-label="Archivo de hechos (.pl)"
          onChange={cargarArchivo}
        />
      </div>

      {caso && <p className="inicio__pista parpadeo">Presione iniciar</p>}
    </main>
  )
}

export default Inicio
