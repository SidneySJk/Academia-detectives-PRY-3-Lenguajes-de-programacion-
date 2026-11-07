import { useState } from 'react'
import Inicio from './inicio.jsx'

function App() {
  const [pantalla, setPantalla] = useState('inicio')

  if (pantalla === 'inicio') {
    return <Inicio onIniciar={() => setPantalla('tablero')} />
  }

  // El tablero del caso se implementa en el siguiente commit.
  return (
    <main className="pixel-panel">
      <h2>Tablero del caso</h2>
      <p>En construcción.</p>
      <button type="button" className="pixel-btn" onClick={() => setPantalla('inicio')}>
        Volver
      </button>
    </main>
  )
}

export default App
