
class_name ReliquiaFixacaoResistente
extends Reliquia

@export var resets_extras: int = 10
## em etapas (50 etapas = o tempo de uma queda). Aceita valores negativos!
@export var etapas_extras_fixacao: float = 25.0

func modificar_regras(regras: RegrasJogo) -> void:
	regras.max_resets_fixacao += resets_extras
	regras.total_etapas_fixacao += etapas_extras_fixacao
