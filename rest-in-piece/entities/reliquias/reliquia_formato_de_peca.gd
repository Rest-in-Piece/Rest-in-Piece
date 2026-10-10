

# "pontuar utilizando um formato de peça específico concede buff"
class_name ReliquiaFormatoDePeca
extends Reliquia

## formatos que recebem o buff. Ex: ["T", "O"]
@export var formatos_aceitos: Array[String] = []
@export var pontos_extras_por_nivel: Array[int] = [5, 10, 20]

func ao_pontuar_bloco(_contexto: ContextoPontuacao, _linha: LinhaPontuada, bloco: BlocoPontuado) -> void:
	if bloco.tipo_peca in formatos_aceitos:
		var pontos_extras: int = escolher_por_nivel(pontos_extras_por_nivel)
		bloco.pontos += pontos_extras
