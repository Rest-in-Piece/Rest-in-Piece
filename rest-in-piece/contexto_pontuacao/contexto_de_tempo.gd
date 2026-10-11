

# informações de um quadro de jogo entregues às relíquias que reagem ao TEMPO. A relíquia
# lê o que precisa e, se quiser mudar algo, pede pelos métodos (quem aplica é o GameManager).

class_name ContextoDeTempo
extends RefCounted

# para LER
var delta: float = 0.0  # segundos reais desde o último quadro
var peca_atual: Peca
var pecas_do_saco: Array[Peca] = []

# pedidos (o GameManager aplica depois dos hooks)
var candidatas_substituicao: Array[Peca] = []
var reliquia_proponente: Reliquia

# usado pelo gerenciador pra saber se a relíquia atual participou
var ativou_reliquia: bool = false


# a relíquia propõe candidatas em ordem de preferência. O GameManager tenta uma por uma
# até alguma caber no tabuleiro, e só então registra a ativação da relíquia
func propor_substituicao(candidatas: Array[Peca], proponente: Reliquia):
	candidatas_substituicao = candidatas
	reliquia_proponente = proponente
