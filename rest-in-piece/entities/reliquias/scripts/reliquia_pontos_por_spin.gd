

# "realizar um Spin concede pontos instantâneos", mesmo sem linhas destruídas
class_name ReliquiaPontosPorSpin
extends Reliquia

@export var fichas_por_spin_por_nivel: Array[int] = [50, 100, 200]

## deixe vazio pra aceitar qualquer spin. Ex: ["T-Spin"]
@export var spins_aceitos: Array[String] = []

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if not contexto.teve_spin():
		return
	
	if spins_aceitos.is_empty() or contexto.tipo_spin in spins_aceitos:
		var fichas_por_spin: int = escolher_por_nivel(fichas_por_spin_por_nivel)
		contexto.adicionar_fichas(fichas_por_spin)
