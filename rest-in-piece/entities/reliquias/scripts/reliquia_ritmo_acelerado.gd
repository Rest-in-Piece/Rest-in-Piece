

# "aumenta a velocidade, mas concede um buff": multiplicador extra nas jogadas com linhas
class_name ReliquiaRitmoAcelerado
extends Reliquia

## fator aplicado à velocidade de queda (1.2 = 20% mais rápida). Um valor por nível
@export var fator_velocidade_por_nivel: Array[float] = [2.0, 2.5, 3.0]
## multiplicador somado em toda jogada que destrói linhas. Um valor por nível
@export var multiplicador_adicional_por_nivel: Array[float] = [1.5, 2.5, 4.0]

func modificar_regras(regras: RegrasJogo) -> void:
	var fator_velocidade: float = escolher_por_nivel(fator_velocidade_por_nivel)
	regras.velocidade *= fator_velocidade

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas > 0:
		var multiplicador_adicional: float = escolher_por_nivel(multiplicador_adicional_por_nivel)
		contexto.adicionar_multiplicador(multiplicador_adicional)
