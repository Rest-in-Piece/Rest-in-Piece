

# guarda tudo que aconteceu na jogada (peça travada) e o valor parcial da pontuação.
# as relíquias leem as condições daqui e alteram pontos / multiplicador por aqui.

class_name ContextoPontuacao
extends RefCounted

var peca: Peca
var linhas_destruidas: int = 0
var tipo_spin: String = ""  # vazio quando não houve spin

var pontos: float = 0.0
var multiplicador: float = 1.0

# usado pelo gerenciador pra saber se a relíquia atual participou da pontuação
var ativou_reliquia: bool = false


func adicionar_pontos(valor: float):
	pontos += valor
	ativou_reliquia = true

func adicionar_multiplicador(valor: float):
	multiplicador += valor
	ativou_reliquia = true

func multiplicar_multiplicador(fator: float):
	multiplicador *= fator
	ativou_reliquia = true

func teve_spin() -> bool:
	return tipo_spin != ""

func obter_pontuacao_final() -> int:
	return int(round(pontos * multiplicador))
