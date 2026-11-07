:- encoding(utf8).
:- use_module('hechos.pl').

% -----------
% Accesos

tiene_acceso(Persona, Lugar) :-
    acceso(Persona, Lugar).

tiene_acceso(Persona, Lugar) :-
    accesoPorObjeto(Lugar, _),
    estuvo(Persona, Lugar, _).

% -----------
% marco_tiempo
% Las horas están en formato HHMM, comparando solo por orden.
% -----------
marco_tiempo(LugarEvento, HoraEvento, Hora) :-
    findall(H, ( evidencia(_, LugarEvento, H), H =< HoraEvento ), Horas),
    min_list([HoraEvento|Horas], Inicio),
    Hora >= Inicio,
    Hora =< HoraEvento.

% -----------
% Último lugar donde estuvo la persona a una hora dada (o antes)
% -----------
ubicada_en(Persona, Hora, Lugar) :-
    findall(H-L, ( estuvo(Persona, L, H), H =< Hora ), Registros),
    Registros \= [],
    msort(Registros, Ordenados),
    last(Ordenados, _-Lugar).

% -----------
% Contradicciones: el testimonio contradice la ultima 
% ubicacion registrada de la persona a esa hora
% -----------
contradiccion_de(Persona, LugarTestimonio, Hora, LugarRegistrado) :-
    testimonio(Persona, LugarTestimonio, Hora),
    ubicada_en(Persona, Hora, LugarRegistrado),
    LugarTestimonio \= LugarRegistrado.

tiene_contradiccion(Persona) :-
    contradiccion_de(Persona, _, _, _).

% -----------
% Coartada
% -----------
tiene_coartada(Persona) :-
    testimonio(Persona, OtroLugar, HoraTestimonio),
    estuvo(Persona, OtroLugar, HoraMovimiento),
    evento(_ , LugarEvento, HoraEvento),
    HoraTestimonio =:= HoraEvento,
    HoraMovimiento =:= HoraEvento,
    OtroLugar \= LugarEvento,
    \+ tiene_contradiccion(Persona).

tiene_coartada(Persona) :-
    testimonio(Persona, OtroLugar, HoraTestimonio),
    evento(_, LugarEvento, HoraEvento),
    HoraTestimonio < HoraEvento,
    OtroLugar \= LugarEvento,
    marco_tiempo(LugarEvento, HoraEvento, HoraTestimonio),
    ubicada_en(Persona, HoraTestimonio, OtroLugar),
    ubicada_en(Persona, HoraEvento, UltimoLugar),
    UltimoLugar \= LugarEvento,
    \+ tiene_contradiccion(Persona).

% -----------
% Posibles responsables: estuvo en el lugar del evento 
% (o tiene evidencia en el lugar) y no tiene coartada
% -----------
estuvo_lugar_evento(Persona) :-
    evento(_, LugarEvento, _),
    ( tiene_acceso(Persona, LugarEvento);
        corresponde(Evidencia, Persona),
        evidencia(Evidencia, LugarEvento, _) ).

posible_sospechoso(Persona) :-
    persona(Persona),
    once(( estuvo_lugar_evento(Persona),
           \+ tiene_coartada(Persona); 
           tiene_contradiccion(Persona) )).

posibles_responsables(Sospechosos) :-
    findall(Persona, ( persona(Persona), 
    posible_sospechoso(Persona) ), Sospechosos).

% -----------
% Argumentos: argumento(Persona, Tipo, Texto)
% Tipo: contra | favor
% -----------
argumento(Persona, contra, Texto) :-
    contradiccion_de(Persona, LugarT, Hora, LugarR),
    format(atom(Texto),
    '~w declaró estar en ~w a las ~w, pero los registros lo ubican en ~w.',
    [Persona, LugarT, Hora, LugarR]).

argumento(Persona, contra, Texto) :-
    evento(_, LugarEvento, _),
    tiene_acceso(Persona, LugarEvento),
    format(atom(Texto), 
    '~w tiene acceso a ~w, lugar del evento.',
    [Persona, LugarEvento]).

argumento(Persona, contra, Texto) :-
    evento(_, LugarEvento, _),
    estuvo(Persona, LugarEvento, Hora),
    format(atom(Texto), '~w estuvo en ~w a las ~w.', 
    [Persona, LugarEvento, Hora]).

argumento(Persona, contra, Texto) :-
    evento(_, LugarEvento, _),
    corresponde(Evidencia, Persona),
    evidencia(Evidencia, LugarEvento, Hora),
    format(atom(Texto),
    'La evidencia ~w, hallada en ~w a las ~w, corresponde a ~w.',
    [Evidencia, LugarEvento, Hora, Persona]).

argumento(Persona, favor, Texto) :-
    tiene_coartada(Persona),
    format(atom(Texto), 'El testimonio de ~w, los registros y el momento del evento permiten establecer una coartada.', [Persona]).

argumento(Persona, favor, Texto) :-
    persona(Persona),
    \+ estuvo_lugar_evento(Persona),
    format(atom(Texto), '~w no tiene acceso ni evidencia en el lugar del evento.', [Persona]).

explicaciones(Persona, Explicacion) :-
    persona(Persona),
    findall(Tipo-Texto, argumento(Persona, Tipo, Texto), Todos),
    list_to_set(Todos, Unicos),
    ( Unicos == [] ->  
        format(atom(Msg), 'No hay información suficiente para determinar la implicación de ~w.', [Persona]),
        Explicacion = [neutro-Msg]; 
        Explicacion = Unicos ).

% --------------------------------------------
% resolver_caso
% Usa posibles_responsables/1, tiene_acceso/2, tiene_coartada/1,
% ubicada_en/3 y los hechos. No usa estuvo_en_intervalo/4,
% evidencias_de/2, descartar/1 ni investigar/1.
% --------------------------------------------

% Relacion entre persona y evento
relacion(Persona, acceso(Lugar)) :-
    evento(_, Lugar, _),
    tiene_acceso(Persona, Lugar).

relacion(Persona, presencia(Lugar, Hora)) :-
    evento(_, Lugar, HoraEvento),
    estuvo(Persona, Lugar, Hora),
    Hora =< HoraEvento.

relacion(Persona, evidencia(Evidencia, Lugar, Hora)) :-
    evento(_, Lugar, HoraEvento),
    corresponde(Evidencia, Persona),
    evidencia(Evidencia, Lugar, Hora),
    Hora =< HoraEvento.

% Hipótesis: acceso al lugar del evento + 
% registro o evidencia + sin coartada
hipotesis(Persona, Vinculos) :-
    persona(Persona),
    findall(V, relacion(Persona, V), ListaVinculos),
    list_to_set(ListaVinculos, Vinculos),
    memberchk(acceso(_), Vinculos),
    ( memberchk(presencia(_, _), Vinculos) ->  
        true ; memberchk(evidencia(_, _, _), Vinculos)),
    \+ tiene_coartada(Persona).

