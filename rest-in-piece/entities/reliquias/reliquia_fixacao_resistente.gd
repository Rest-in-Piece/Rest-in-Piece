

class_name ReliquiaFixacaoResistente
extends Reliquia

## um valor por nível: [nível 1, nível 2, nível 3]
@export var resets_extras_por_nivel: Array[int] = [10, 15, 20]
## em etapas (50 etapas = o tempo de uma queda), um valor por nível
@export var etapas_extras_fixacao_por_nivel: Array[float] = [25.0, 40.0, 60.0]

func modificar_regras(regras: RegrasJogo) -> void:
	regras.max_resets_fixacao += escolher_por_nivel(resets_extras_por_nivel)
	regras.total_etapas_fixacao += escolher_por_nivel(etapas_extras_fixacao_por_nivel)
