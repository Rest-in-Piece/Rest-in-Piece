

# "quanto mais em cima do grid pontuar, maior o multiplicador"
class_name ReliquiaMultiplicadorPorAltura
extends Reliquia

## multiplicador somado por cada nível de altura da linha (1 = baixo, 20 = topo)
@export var multiplicador_por_altura_por_nivel: Array[float] = [0.05, 0.1, 0.15]

func ao_pontuar_linha(contexto: ContextoPontuacao, linha: LinhaPontuada) -> void:
	if linha.zerada:
		return
	
	var multiplicador_por_altura: float = escolher_por_nivel(multiplicador_por_altura_por_nivel)
	contexto.adicionar_multiplicador(multiplicador_por_altura * linha.altura)
