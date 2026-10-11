

# "a cada x linhas destruídas, +1 peça no limite da fase"
class_name ReliquiaPecasMaximasPorLinhas
extends Reliquia

## a cada quantas linhas destruídas a relíquia concede +1 peça. Um valor por nível
@export var linhas_por_peca_por_nivel: Array[int] = [6, 4, 2]

# estado da relíquia: linhas contadas que ainda não viraram peça
var linhas_acumuladas: int = 0

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas == 0:
		return
	
	linhas_acumuladas += contexto.linhas_destruidas
	var linhas_por_peca: int = escolher_por_nivel(linhas_por_peca_por_nivel)
	linhas_por_peca = maxi(linhas_por_peca, 1)
	
	while linhas_acumuladas >= linhas_por_peca:
		linhas_acumuladas -= linhas_por_peca
		contexto.adicionar_pecas_extras(1)
