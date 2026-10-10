

# "após o primeiro hold, a peça armazenada ganha pontos permanentemente a cada peça que
# cai. No segundo hold, para de incrementar"
class_name ReliquiaBuffPecaArmazenada
extends Reliquia

@export var pontos_por_peca_por_nivel: Array[int] = [1, 2, 3]

var armazenamentos_realizados: int = 0

func ao_armazenar_peca(_peca_armazenada: Peca) -> void:
	armazenamentos_realizados += 1

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if armazenamentos_realizados != 1 or contexto.peca_armazenada == null:
		return
	
	var pontos_por_peca: int = escolher_por_nivel(pontos_por_peca_por_nivel)
	contexto.peca_armazenada.pontos_extras += pontos_por_peca
	contexto.marcar_ativacao()
