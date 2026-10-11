

# "pontuar 4 linhas recebe um buff muito grande. Pontuar menos linhas concede zero pontos"
class_name ReliquiaSoTetris
extends Reliquia

const LINHAS_NECESSARIAS: int = 4

@export var multiplicador_tetris_por_nivel: Array[float] = [1.5, 2.0, 3.0]

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas == 0:
		return
	
	if contexto.linhas_destruidas < LINHAS_NECESSARIAS:
		contexto.zerar()
		return
	
	var multiplicador_tetris: float = escolher_por_nivel(multiplicador_tetris_por_nivel)
	contexto.adicionar_multiplicador(multiplicador_tetris)
