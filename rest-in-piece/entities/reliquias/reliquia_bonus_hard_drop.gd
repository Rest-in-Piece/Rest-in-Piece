

# "ao usar o hard drop, concede pontos a mais para cada tile que a peça desceu"
class_name ReliquiaBonusHardDrop
extends Reliquia

@export var fichas_por_casa_por_nivel: Array[int] = [2, 4, 6]

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.casas_hard_drop <= 0:
		return
	
	var fichas_por_casa: int = escolher_por_nivel(fichas_por_casa_por_nivel)
	contexto.adicionar_fichas(fichas_por_casa * contexto.casas_hard_drop)
