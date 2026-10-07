

# essa relíquia melhora toda vez que realiza um TETRIS

class_name ReliquiaTetrisCrescente
extends Reliquia

@export var crescimento_por_tetris: float = 0.5

# estado da relíquia (sem @export, então cada cópia começa zerada)
var multiplicador_acumulado: float = 0.0

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas == 4:
		multiplicador_acumulado += crescimento_por_tetris
	
	if contexto.linhas_destruidas > 0 and multiplicador_acumulado > 0.0:
		contexto.adicionar_multiplicador(multiplicador_acumulado)
