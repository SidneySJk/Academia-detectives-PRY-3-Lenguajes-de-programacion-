// Cada caracter es un pixel: M marco, B brillo, H mango, . vacio.
const DIBUJO = [
  '..MMMM....',
  '.M....M...',
  'M.BB...M..',
  'M.B....M..',
  'M......M..',
  'M......M..',
  '.M....M...',
  '..MMMMHH..',
  '.......HH.',
  '........HH',
]

const COLORES = {
  M: 'var(--texto)',
  B: '#9fd8e0',
  H: 'var(--acento)',
}

function PixelLupa({ tamano = 80 }) {
  return (
    <svg
      width={tamano}
      height={tamano}
      viewBox="0 0 10 10"
      shapeRendering="crispEdges"
      aria-hidden="true"
    >
      {DIBUJO.flatMap((fila, y) =>
        [...fila].map((pixel, x) =>
          COLORES[pixel] ? (
            <rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" fill={COLORES[pixel]} />
          ) : null,
        ),
      )}
    </svg>
  )
}

export default PixelLupa
