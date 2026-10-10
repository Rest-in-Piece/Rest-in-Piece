

# uma linha completa no momento em que é destruída. O tetris.gd preenche os fatos
# (posição e quadradinhos); os pontos são calculados durante a pontuação.

class_name LinhaPontuada
extends RefCounted

var indice_linha: int = 0  # posição no grid (1 = topo)
var altura: int = 1  # 1 = linha de baixo, 20 = linha do topo
var blocos: Array[BlocoPontuado] = []  # da esquerda pra direita
var pontos: float = 0.0
var zerada: bool = false


# soma os pontos do quadradinho e DEPOIS aplica o multiplicador dele em cima de tudo
# que já foi acumulado na linha
func acumular_bloco(bloco: BlocoPontuado):
	if zerada:
		return
	pontos += bloco.pontos
	pontos *= bloco.multiplicador

func adicionar_pontos(valor: float):
	if zerada:
		return
	pontos += valor

func multiplicar_pontos(fator: float):
	pontos *= fator

# uma linha zerada ignora qualquer ganho posterior
func zerar():
	pontos = 0.0
	zerada = true
