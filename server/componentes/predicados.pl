% Hechos del caso: se declaran dinamicos para que un hechos.pl de reemplazo
% que omita alguno no provoque errores de existencia.
:- dynamic persona/1, lugar/2, objeto/1, ubicado/2,
    acceso/2, accesoPorObjeto/2, estuvo/3, evento/3,
    evidencia/3, corresponde/2, testimonio/3.

:- consult('hechos.pl').

hora_a_segundos(HoraFormato, Segundos) :-
    atomic_list_concat([H, M], ':', HoraFormato),
    atom_number(H, Horas),
    atom_number(M, Minutos),
    Segundos is Horas * 3600 + Minutos * 60.

tiene_acceso(Persona, Lugar) :-
    acceso(Persona, Lugar).

tiene_acceso(Persona, Lugar) :-
    accesoPorObjeto(Lugar, Objeto),
    estuvo(Persona, Lugar, _).

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
