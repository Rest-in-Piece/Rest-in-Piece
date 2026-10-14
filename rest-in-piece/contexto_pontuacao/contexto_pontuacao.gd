# guarda tudo que aconteceu na jogada (peça travada) e o valor parcial da pontuação.
# as relíquias leem as condições daqui e alteram fichas / multiplicador por aqui.

class_name ContextoPontuacao
extends RefCounted

var peca: Peca
var peca_armazenada: Peca  # a peça do hold no momento em que a peça travou (pode ser nula)
var linhas: Array[LinhaPontuada] = []
var tipo_spin: String = ""  # vazio quando não houve spin
var casas_hard_drop: int = 0  # casas que a peça desceu usando hard drop

var fichas: float = 0.0
var multiplicador: float = 1.0

# peças somadas ao limite da fase por efeitos desta jogada (o GameManager aplica)
var pecas_extras: int = 0

# uma jogada zerada ignora qualquer ganho posterior (como a LinhaPontuada)
var zerado: bool = false

# usado pelo gerenciador pra saber se a relíquia atual participou da pontuação
var ativou_reliquia: bool = false

var linhas_destruidas: int:
	get:
		var quantidade: int = 0
		for linha in linhas:
			if linha.completa:
				quantidade += 1
		return quantidade


func adicionar_fichas(valor: float):
	if zerado:
		return
	fichas += valor
	ativou_reliquia = true

func adicionar_multiplicador(valor: float):
	if zerado:
		return
	multiplicador += valor
	ativou_reliquia = true

func multiplicar_multiplicador(fator: float):
	if zerado:
		return
	multiplicador *= fator
	ativou_reliquia = true

func adicionar_pecas_extras(quantidade: int):
	pecas_extras += quantidade
	ativou_reliquia = true

func zerar():
	fichas = 0.0
	zerado = true
	ativou_reliquia = true

# pra relíquias que alteram outra coisa (ex: o buff permanente de uma peça)
func marcar_ativacao():
	ativou_reliquia = true

func teve_spin() -> bool:
	return tipo_spin != ""

# os pontos das linhas (já calculados quadradinho por quadradinho) viram as fichas
func somar_pontos_das_linhas():
	for linha in linhas:
		fichas += linha.pontos

func obter_pontuacao_final() -> int:
	return int(round(fichas * multiplicador))
