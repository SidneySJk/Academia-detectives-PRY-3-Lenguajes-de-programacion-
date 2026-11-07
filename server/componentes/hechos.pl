% Personas
persona(ana).
persona(bruno).
persona(carla).
persona(diego).
persona(elena).
% Lugares
lugar(entrada, "Entrada principal del museo.").
lugar(biblioteca, "Biblioteca del museo.").
lugar(laboratorio, "Laboratorio de restauracion.").
lugar(bodega, "Bodega de almacenamiento.").
lugar(oficina, "Oficina administrativa.").
% Objetos
objeto(llave_maestra).
objeto(tarjeta_laboratorio).
objeto(documento).
objeto(caja_herramientas).
% Accesos
acceso(ana, biblioteca).
acceso(ana, oficina).
acceso(bruno, entrada).
acceso(bruno, bodega).
acceso(carla, laboratorio).
acceso(carla, biblioteca).
acceso(diego, entrada).
acceso(diego, biblioteca).
acceso(elena, oficina).
% Acceso mediante objetos
accesoPorObjeto(bodega, llave_maestra).
accesoPorObjeto(laboratorio, tarjeta_laboratorio).
% Registro de presencia
estuvo(ana, entrada, 1900).
estuvo(ana, biblioteca, 1930).
estuvo(bruno, entrada, 1910).
estuvo(bruno, bodega, 1950).
estuvo(carla, biblioteca, 1920).
estuvo(carla, laboratorio, 1955).
estuvo(diego, entrada, 1900).
estuvo(diego, biblioteca, 1940).
estuvo(elena, oficina, 1900).

% Evento
evento(desaparicion, bodega, 2000).
% Evidencias
evidencia(huella, bodega, 1955).
evidencia(llave, bodega, 1950).
evidencia(documento, oficina, 1930).
% Relacion entre evidencia y persona
corresponde(huella, bruno).
corresponde(llave, bruno).
corresponde(documento, ana).
% Testimonios
testimonio(bruno, entrada, 1955).
testimonio(carla, biblioteca, 1955).
testimonio(ana, biblioteca, 1930).