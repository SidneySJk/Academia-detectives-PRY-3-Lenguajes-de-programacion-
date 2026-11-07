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

evidencia_de(Persona, Evidencias) :-
    (persona(Persona) ->
    findall(Evidencia, corresponde(Evidencia, Persona), Evidencias);
    Evidencias == []).

evidencia_de(Persona, Evidencias) :-
    findall(Evidencia, corresponde(Evidencia, Persona), Evidencias).

tiene_coartada(Persona) :-
    testimonio(Persona, OtroLugar, HoraTestimonio),
    estuvo(Persona, OtroLugar, HoraMovimiento),
    evento(_ , LugarEvento, HoraEvento),
    HoraTestimonio =:= HoraEvento,
    HoraMovimiento =:= HoraEvento,
    OtroLugar \= LugarEvento.
