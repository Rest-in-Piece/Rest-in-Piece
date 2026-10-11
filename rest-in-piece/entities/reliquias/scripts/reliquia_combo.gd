

# "a cada peça consecutiva que destrói linhas, acumula multiplicador. Uma peça que não
# destrói linhas zera o combo"
class_name ReliquiaCombo
extends Reliquia

## multiplicador somado por cada peça do combo (a 3ª peça seguida soma 3x este valor)
@export var multiplicador_por_combo_por_nivel: Array[float] = [0.25, 0.5, 1.0]

var combo_atual: int = 0

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas == 0:
		combo_atual = 0
		return
	
	var multiplicador_por_combo: float = escolher_por_nivel(multiplicador_por_combo_por_nivel)
	contexto.adicionar_multiplicador(multiplicador_por_combo * combo_atual)
	combo_atual += 1
