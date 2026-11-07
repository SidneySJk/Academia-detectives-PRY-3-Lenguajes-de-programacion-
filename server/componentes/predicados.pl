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

% Convierte una hora HHMM (1950) a texto ("19:50").
hora_texto(Hora, Texto) :-
    H is Hora // 100,
    M is Hora mod 100,
    format(string(Texto), "~d:~|~`0t~d~2+", [H, M]).

% Cada clausula de explicacion/2 construye una justificacion a partir de los
% hechos; por backtracking se obtienen todas las explicaciones de la persona.
explicaciones(Persona, Explicacion) :-
    persona(Persona),
    explicacion(Persona, Explicacion).

explicacion(Persona, Explicacion) :-
    evento(_, LugarEvento, _),
    acceso(Persona, LugarEvento),
    format(string(Explicacion),
        "Tiene acceso autorizado a ~w, lugar del evento.", [LugarEvento]).

explicacion(Persona, Explicacion) :-
    evento(_, LugarEvento, _),
    accesoPorObjeto(LugarEvento, Objeto),
    puede_obtener(Persona, Objeto),
    \+ acceso(Persona, LugarEvento),
    format(string(Explicacion),
        "Puede entrar a ~w porque puede obtener el objeto ~w.",
        [LugarEvento, Objeto]).

explicacion(Persona, Explicacion) :-
    evento(NombreEvento, LugarEvento, HoraEvento),
    estuvo(Persona, LugarEvento, Hora),
    en_ventana_evento(Hora),
    hora_texto(Hora, Texto),
    hora_texto(HoraEvento, TextoEvento),
    format(string(Explicacion),
        "Estuvo en ~w a las ~w, cerca del evento ~w (~w).",
        [LugarEvento, Texto, NombreEvento, TextoEvento]).

explicacion(Persona, Explicacion) :-
    corresponde(Evidencia, Persona),
    evidencia(Evidencia, Lugar, Hora),
    hora_texto(Hora, Texto),
    format(string(Explicacion),
        "La evidencia ~w, hallada en ~w a las ~w, le corresponde.",
        [Evidencia, Lugar, Texto]).

explicacion(Persona, Explicacion) :-
    testimonio(Persona, Lugar, Hora),
    estuvo(Persona, OtroLugar, HoraRegistro),
    OtroLugar \= Lugar,
    mismo_momento(Hora, HoraRegistro),
    hora_texto(Hora, Texto),
    hora_texto(HoraRegistro, TextoRegistro),
    format(string(Explicacion),
        "Declaro estar en ~w a las ~w, pero el registro indica que estuvo en ~w a las ~w.",
        [Lugar, Texto, OtroLugar, TextoRegistro]).

explicacion(Persona, Explicacion) :-
    testimonio(Persona, Lugar, Hora),
    en_ventana_evento(Hora),
    evento(_, LugarEvento, _),
    Lugar \= LugarEvento,
    \+ testimonio_contradicho(Persona, Lugar, Hora),
    hora_texto(Hora, Texto),
    format(string(Explicacion),
        "Su testimonio indica que estaba en ~w a las ~w, lejos de ~w y sin contradicciones: posible coartada.",
        [Lugar, Texto, LugarEvento]).

explicacion(Persona, Explicacion) :-
    evento(_, LugarEvento, _),
    once(tiene_acceso(Persona, LugarEvento)),
    once(vinculado_al_evento(Persona)),
    \+ tiene_coartada(Persona),
    format(string(Explicacion),
        "Conclusion: posible sospechoso por oportunidad (acceso a ~w, vinculo con el evento y sin coartada).",
        [LugarEvento]).

explicacion(Persona, Explicacion) :-
    once(vinculado_al_evento(Persona)),
    once(tiene_contradiccion(Persona)),
    Explicacion = "Conclusion: posible sospechoso por inconsistencia (vinculo con el evento y testimonio contradicho).".

% Una solucion es valida si la persona sigue cumpliendo la sospecha, pudo
% llegar al lugar del evento (acceso o presencia registrada) y ninguna
% coartada la aleja de el.
solucion_valida(Persona) :-
    posible_sospechoso(Persona),
    evento(_, LugarEvento, _),
    once((tiene_acceso(Persona, LugarEvento) ; estuvo(Persona, LugarEvento, _))),
    \+ tiene_coartada(Persona).

% Reune toda la informacion que sustenta la conclusion sobre una persona.
reporte(Persona, reporte(Persona, Evidencias, Movimientos, Accesos,
                         Coartadas, Contradicciones, Explicaciones, Valida)) :-
    findall(evidencia(Evidencia, Lugar, Hora),
        (corresponde(Evidencia, Persona), evidencia(Evidencia, Lugar, Hora)),
        Evidencias),
    findall(estuvo(Lugar, Hora), estuvo(Persona, Lugar, Hora), Movimientos),
    findall(Lugar, tiene_acceso(Persona, Lugar), Accesos),
    findall(testimonio(Lugar, Hora),
        (testimonio(Persona, Lugar, Hora),
         en_ventana_evento(Hora),
         evento(_, LugarEvento, _),
         Lugar \= LugarEvento,
         \+ testimonio_contradicho(Persona, Lugar, Hora)),
        Coartadas),
    findall(contradiccion(Lugar, Hora, OtroLugar, HoraRegistro),
        (testimonio(Persona, Lugar, Hora),
         estuvo(Persona, OtroLugar, HoraRegistro),
         OtroLugar \= Lugar,
         mismo_momento(Hora, HoraRegistro)),
        Contradicciones),
    findall(Explicacion, explicaciones(Persona, Explicacion), Explicaciones),
    (solucion_valida(Persona) -> Valida = si ; Valida = no).

resolver_caso :-
    \+ evento(_, _, _),
    !,
    writeln("El caso no tiene un evento central definido.").

resolver_caso :-
    evento(Nombre, Lugar, Hora),
    hora_texto(Hora, Texto),
    format("Evento: ~w en ~w a las ~w~n", [Nombre, Lugar, Texto]),
    posibles_responsables(Responsables),
    (   Responsables == []
    ->  writeln("Ninguna persona cumple las reglas para ser responsable.")
    ;   format("Posibles responsables: ~w~n", [Responsables]),
        forall(member(Persona, Responsables), mostrar_reporte(Persona))
    ).

mostrar_reporte(Persona) :-
    reporte(Persona, reporte(_, Evidencias, Movimientos, Accesos,
                             Coartadas, Contradicciones, Explicaciones, Valida)),
    format("~n== ~w ==~n", [Persona]),
    titulo("Evidencias", Evidencias),
    forall(member(evidencia(E, L, H), Evidencias),
        (hora_texto(H, T), format("  - ~w en ~w a las ~w~n", [E, L, T]))),
    titulo("Movimientos", Movimientos),
    forall(member(estuvo(L, H), Movimientos),
        (hora_texto(H, T), format("  - ~w a las ~w~n", [L, T]))),
    format("Accesos: ~w~n", [Accesos]),
    titulo("Coartadas", Coartadas),
    forall(member(testimonio(L, H), Coartadas),
        (hora_texto(H, T), format("  - ~w a las ~w~n", [L, T]))),
    titulo("Contradicciones", Contradicciones),
    forall(member(contradiccion(L, H, L2, H2), Contradicciones),
        (hora_texto(H, T), hora_texto(H2, T2),
         format("  - dijo ~w a las ~w, registro ~w a las ~w~n", [L, T, L2, T2]))),
    writeln("Justificacion:"),
    forall(member(Explicacion, Explicaciones), format("  - ~w~n", [Explicacion])),
    format("Solucion valida: ~w~n", [Valida]).

titulo(Titulo, []) :-
    !,
    format("~w: ninguna~n", [Titulo]).

titulo(Titulo, _) :-
    format("~w:~n", [Titulo]).
