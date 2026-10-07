

# aumenta a quantidade de pontos recebidos por completar uma linha

class_name ReliquiaPontosPorLinha
extends Reliquia

@export var pontos_por_linha: int = 50

func ao_pontuar(contexto: ContextoPontuacao) -> void:
	if contexto.linhas_destruidas > 0:
		contexto.adicionar_pontos(pontos_por_linha * contexto.linhas_destruidas)
