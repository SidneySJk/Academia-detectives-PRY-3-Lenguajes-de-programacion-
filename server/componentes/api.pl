% Punto de entrada para el puente en Node. Se ejecuta como:
%   swipl api.pl <accion> [argumentos...]
% Los argumentos llegan como atomos desde argv, por lo que nunca se evalua
% texto del usuario como codigo. La respuesta se imprime como JSON.
:- consult('predicados.pl').

:- initialization(main, main).

main :-
    set_stream(user_output, encoding(utf8)),
    current_prolog_flag(argv, Argv),
    (   respuesta(Argv, Json)
    ->  json(Json), nl
    ;   mensaje_error(Argv, Mensaje),
        json(obj([error-Mensaje])), nl,
        halt(1)
    ).

mensaje_error([_, Persona | _], Mensaje) :-
    \+ persona(Persona),
    !,
    format(string(Mensaje), "Persona no encontrada: ~w", [Persona]).

mensaje_error(_, "Consulta no valida").

% ---------- Acciones permitidas ----------

respuesta([personas], Personas) :-
    findall(Persona, persona(Persona), Personas).

respuesta([lugares], Lugares) :-
    findall(obj([nombre-Lugar, descripcion-Descripcion]),
        lugar(Lugar, Descripcion), Lugares).

respuesta([objetos], Objetos) :-
    findall(Objeto, objeto(Objeto), Objetos).

respuesta([evento], obj([nombre-Nombre, lugar-Lugar, hora-Hora])) :-
    evento(Nombre, Lugar, Hora),
    !.

respuesta([evento], null).

respuesta([movimientos, Persona], Movimientos) :-
    persona(Persona),
    findall(obj([lugar-Lugar, hora-Hora]), estuvo(Persona, Lugar, Hora), Movimientos).

respuesta([tiene_acceso, Persona, Lugar], obj([persona-Persona, lugar-Lugar, resultado-bool(Valor)])) :-
    persona(Persona),
    booleano(tiene_acceso(Persona, Lugar), Valor).

respuesta([Predicado, Persona], obj([persona-Persona, resultado-bool(Valor)])) :-
    memberchk(Predicado, [tiene_coartada, tiene_contradiccion, posible_sospechoso]),
    persona(Persona),
    Consulta =.. [Predicado, Persona],
    booleano(Consulta, Valor).

respuesta([explicaciones, Persona], Explicaciones) :-
    persona(Persona),
    findall(Explicacion, explicaciones(Persona, Explicacion), Explicaciones).

respuesta([posibles_responsables], Responsables) :-
    posibles_responsables(Responsables).

respuesta([resolver_caso], obj([evento-Evento, responsables-Reportes])) :-
    respuesta([evento], Evento),
    posibles_responsables(Responsables),
    findall(Reporte,
        (member(Persona, Responsables), reporte_json(Persona, Reporte)),
        Reportes).

booleano(Consulta, true) :-
    call(Consulta),
    !.

booleano(_, false).

reporte_json(Persona, obj([
        persona-Persona,
        evidencias-EvidenciasJson,
        movimientos-MovimientosJson,
        accesos-Accesos,
        coartadas-CoartadasJson,
        contradicciones-ContradiccionesJson,
        explicaciones-Explicaciones,
        valida-bool(Valor)])) :-
    reporte(Persona, reporte(_, Evidencias, Movimientos, Accesos,
                             Coartadas, Contradicciones, Explicaciones, Valida)),
    findall(obj([evidencia-E, lugar-L, hora-H]),
        member(evidencia(E, L, H), Evidencias), EvidenciasJson),
    findall(obj([lugar-L, hora-H]),
        member(estuvo(L, H), Movimientos), MovimientosJson),
    findall(obj([lugar-L, hora-H]),
        member(testimonio(L, H), Coartadas), CoartadasJson),
    findall(obj([lugar_testimonio-L, hora_testimonio-H,
                 lugar_registro-L2, hora_registro-H2]),
        member(contradiccion(L, H, L2, H2), Contradicciones), ContradiccionesJson),
    (Valida == si -> Valor = true ; Valor = false).

% ---------- Serializacion JSON (sin librerias) ----------

json(Numero) :-
    number(Numero),
    !,
    write(Numero).

json(null) :-
    !,
    write(null).

json(bool(Valor)) :-
    !,
    write(Valor).

json(Lista) :-
    is_list(Lista),
    !,
    write('['),
    json_elementos(Lista),
    write(']').

json(obj(Pares)) :-
    !,
    write('{'),
    json_pares(Pares),
    write('}').

json(Texto) :-
    json_texto(Texto).

json_elementos([]).

json_elementos([Elemento]) :-
    !,
    json(Elemento).

json_elementos([Elemento | Resto]) :-
    json(Elemento),
    write(','),
    json_elementos(Resto).

json_pares([]).

json_pares([Clave-Valor]) :-
    !,
    json_texto(Clave),
    write(':'),
    json(Valor).

json_pares([Clave-Valor | Resto]) :-
    json_texto(Clave),
    write(':'),
    json(Valor),
    write(','),
    json_pares(Resto).

json_texto(Texto) :-
    atom_codes(Texto, Codigos),
    write('"'),
    forall(member(Codigo, Codigos), json_caracter(Codigo)),
    write('"').

json_caracter(0'") :- !, write('\\"').
json_caracter(0'\\) :- !, write('\\\\').
json_caracter(0'\n) :- !, write('\\n').
json_caracter(0'\r) :- !, write('\\r').
json_caracter(0'\t) :- !, write('\\t').
json_caracter(Codigo) :-
    Codigo < 32,
    !,
    format("\\u~|~`0t~16r~4+", [Codigo]).
json_caracter(Codigo) :-
    put_code(Codigo).
