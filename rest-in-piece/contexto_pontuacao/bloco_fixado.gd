

# dados de UM quadradinho já fixado no tabuleiro. O tetris.gd guarda um por posição.
# Os valores são capturados quando a peça trava: buffs dados depois à peça não alteram
# quadradinhos que já estão no grid.

class_name BlocoFixado
extends RefCounted

var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0


static func criar_a_partir_da_peca(peca_origem: Peca) -> BlocoFixado:
	var bloco_fixado := BlocoFixado.new()
	bloco_fixado.tipo_peca = peca_origem.tipo_peca
	bloco_fixado.pontos = peca_origem.obter_pontos_por_bloco()
	bloco_fixado.multiplicador = peca_origem.obter_multiplicador_por_bloco()
	return bloco_fixado
