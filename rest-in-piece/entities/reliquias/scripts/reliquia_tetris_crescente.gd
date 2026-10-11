

class_name ReliquiaTetrisCrescente
extends Reliquia

## um valor por nível: [nível 1, nível 2, nível 3]
@export var crescimento_por_tetris_por_nivel: Array[float] = [0.5, 1.0, 1.5]

var multiplicador_acumulado: float = 0.0

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas == 4:
		multiplicador_acumulado += escolher_por_nivel(crescimento_por_tetris_por_nivel)
	
	if contexto.linhas_destruidas > 0 and multiplicador_acumulado > 0.0:
		contexto.adicionar_multiplicador(multiplicador_acumulado)
