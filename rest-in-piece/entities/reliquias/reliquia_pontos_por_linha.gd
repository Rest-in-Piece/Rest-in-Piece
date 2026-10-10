

class_name ReliquiaFichasPorLinha
extends Reliquia

## um valor por nível: [nível 1, nível 2, nível 3]
@export var fichas_por_linha_por_nivel: Array[int] = [50, 100, 150]

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas > 0:
		var fichas_por_linha: int = escolher_por_nivel(fichas_por_linha_por_nivel)
		contexto.adicionar_fichas(fichas_por_linha * contexto.linhas_destruidas)
