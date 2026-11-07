% Hechos del caso: se declaran dinamicos para que un hechos.pl de reemplazo
% que omita alguno no provoque errores de existencia.
:- dynamic persona/1, lugar/2, objeto/1, ubicado/2,
    acceso/2, accesoPorObjeto/2, estuvo/3, evento/3,
    evidencia/3, corresponde/2, testimonio/3.

:- consult('hechos.pl').

% Convierte una hora HHMM (1955) a minutos desde la medianoche (1195),
% para que las restas entre horas sean correctas (1955 + 15 no es 2010).
hora_a_minutos(Hora, Minutos) :-
    Minutos is (Hora // 100) * 60 + Hora mod 100.

% Minutos antes y despues del evento que se consideran relevantes.
margen_evento(15).

% Una hora esta en la ventana del evento si dista a lo sumo margen_evento
% minutos de la hora del evento central.
en_ventana_evento(Hora) :-
    evento(_, _, HoraEvento),
    margen_evento(Margen),
    hora_a_minutos(Hora, Minutos),
    hora_a_minutos(HoraEvento, MinutosEvento),
    abs(Minutos - MinutosEvento) =< Margen.

% Una persona puede obtener un objeto si tiene acceso directo al lugar
% donde esta ubicado, o si el objeto es una evidencia que le corresponde.
puede_obtener(Persona, Objeto) :-
    ubicado(Objeto, Lugar),
    acceso(Persona, Lugar).

puede_obtener(Persona, Objeto) :-
    corresponde(Objeto, Persona).

tiene_acceso(Persona, Lugar) :-
    acceso(Persona, Lugar).

tiene_acceso(Persona, Lugar) :-
    accesoPorObjeto(Lugar, Objeto),
    puede_obtener(Persona, Objeto),
    \+ acceso(Persona, Lugar).

% Minutos de diferencia con los que dos registros se consideran el mismo momento.
margen_mismo_momento(5).

mismo_momento(Hora1, Hora2) :-
    margen_mismo_momento(Margen),
    hora_a_minutos(Hora1, Minutos1),
    hora_a_minutos(Hora2, Minutos2),
    abs(Minutos1 - Minutos2) =< Margen.

% Un testimonio queda contradicho si un registro de movimiento ubica a la
% persona en otro lugar en el mismo momento.
testimonio_contradicho(Persona, Lugar, Hora) :-
    estuvo(Persona, OtroLugar, HoraRegistro),
    OtroLugar \= Lugar,
    mismo_momento(Hora, HoraRegistro).

% Coartada: un testimonio la ubica lejos del lugar del evento durante la
% ventana del evento y ningun registro de movimiento lo contradice.
tiene_coartada(Persona) :-
    testimonio(Persona, Lugar, Hora),
    en_ventana_evento(Hora),
    evento(_, LugarEvento, _),
    Lugar \= LugarEvento,
    \+ testimonio_contradicho(Persona, Lugar, Hora).

tiene_contradiccion(Persona) :-
    testimonio(Persona, Lugar, Hora),
    testimonio_contradicho(Persona, Lugar, Hora).

% La persona queda ligada al evento si estuvo en su lugar durante la
% ventana del evento o si le corresponde una evidencia hallada alli.
vinculado_al_evento(Persona) :-
    evento(_, LugarEvento, _),
    estuvo(Persona, LugarEvento, Hora),
    en_ventana_evento(Hora).

vinculado_al_evento(Persona) :-
    evento(_, LugarEvento, _),
    evidencia(Evidencia, LugarEvento, _),
    corresponde(Evidencia, Persona).

% Sospecha por oportunidad: podia entrar al lugar del evento, esta ligada a
% el y no tiene coartada.
cumple_sospecha(Persona) :-
    evento(_, LugarEvento, _),
    tiene_acceso(Persona, LugarEvento),
    vinculado_al_evento(Persona),
    \+ tiene_coartada(Persona).

% Sospecha por inconsistencia: esta ligada al evento y su testimonio
% contradice los registros, aunque no tuviera acceso autorizado.
cumple_sospecha(Persona) :-
    vinculado_al_evento(Persona),
    tiene_contradiccion(Persona).

posible_sospechoso(Persona) :-
    persona(Persona),
    once(cumple_sospecha(Persona)).

% Recorre todas las personas del caso y conserva las que cumplen las
% reglas de sospecha.
posibles_responsables(Lista) :-
    findall(Persona, (persona(Persona), posible_sospechoso(Persona)), Lista).
