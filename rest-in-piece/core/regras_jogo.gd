
# valores de jogabilidade em vigor naquele momento. A Fase define os valores base, o
# GameManager cria este objeto a partir dela, as relíquias modificam e o tabuleiro só
# consome (tetris.aplicar_regras). Nunca é salvo nem editado no inspetor.

class_name RegrasJogo
extends RefCounted

var velocidade: float = 1.0
var total_etapas_fixacao: float = 100.0
var max_resets_fixacao: int = 15


static func criar_a_partir_da_fase(fase: Fase, velocidade_atual: float) -> RegrasJogo:
	var regras := RegrasJogo.new()
	regras.velocidade = velocidade_atual
	regras.total_etapas_fixacao = fase.total_etapas_fixacao
	regras.max_resets_fixacao = fase.max_resets_fixacao
	return regras
