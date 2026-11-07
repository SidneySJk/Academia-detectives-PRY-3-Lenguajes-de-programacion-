// Convierte una hora HHMM (1950) a texto (19:50).
export function formatoHora(hora) {
  const horas = Math.floor(hora / 100)
  const minutos = String(hora % 100).padStart(2, '0')
  return `${horas}:${minutos}`
}
