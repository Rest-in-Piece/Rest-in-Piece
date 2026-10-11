

# dados do momento em que uma peça trava, ANTES de os quadradinhos dela serem registrados
# no tabuleiro. As relíquias acrescentam bônus aqui, e esses bônus ficam guardados em
# cada quadradinho da peça (valem quando ele pontuar, mesmo em jogadas futuras).

class_name TravamentoDePeca
extends RefCounted

var peca: Peca
var casas_hard_drop: int = 0  # casas que a peça desceu usando hard drop

# bônus somados aos valores que cada quadradinho recebe da peça
var pontos_extras_por_bloco: int = 0
var multiplicador_extra_por_bloco: float = 0.0

# usado pelo gerenciador pra saber se a relíquia atual participou
var ativou_reliquia: bool = false


func adicionar_pontos_por_bloco(valor: int):
	pontos_extras_por_bloco += valor
	ativou_reliquia = true

func adicionar_multiplicador_por_bloco(valor: float):
	multiplicador_extra_por_bloco += valor
	ativou_reliquia = true
