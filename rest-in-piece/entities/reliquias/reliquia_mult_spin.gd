

# aumenta o multiplicador quando realiza um spin específico

class_name ReliquiaMultiplicadorSpin
extends Reliquia

@export var multiplicador_adicional: float = 2.0

## deixe vazio pra aceitar qualquer spin. Ex: ["T-Spin"]
@export var spins_aceitos: Array[String] = []

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if not contexto.teve_spin():
		return
	
	if spins_aceitos.is_empty() or contexto.tipo_spin in spins_aceitos:
		contexto.adicionar_multiplicador(multiplicador_adicional)
