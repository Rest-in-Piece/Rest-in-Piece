

# aumenta o multiplicador quando realiza um spin específico
class_name ReliquiaMultiplicadorSpin
extends Reliquia

@export var multiplicador_adicional_por_nivel: Array[float] = [2.0, 3.0, 4.0]

## deixe vazio pra aceitar qualquer spin. Ex: ["T-Spin"]
@export var spins_aceitos: Array[String] = []

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if not contexto.teve_spin():
		return
	
	if spins_aceitos.is_empty() or contexto.tipo_spin in spins_aceitos:
		var multiplicador_adicional: float = escolher_por_nivel(multiplicador_adicional_por_nivel)
		contexto.adicionar_multiplicador(multiplicador_adicional)
