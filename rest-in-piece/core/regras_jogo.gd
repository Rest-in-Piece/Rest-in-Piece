# valores de jogabilidade em vigor naquele momento. A Fase define os valores base, o
# GameManager cria este objeto a partir dela, as relíquias modificam e o tabuleiro e o
# próprio GameManager só consomem. Nunca é salvo nem editado no inspetor.

class_name RegrasJogo
extends RefCounted

var velocidade: float = 1.0
var total_etapas_fixacao: float = 100.0
var max_resets_fixacao: int = 15
# AQUI
var pecas_maximas: int = 50
var fichas_base_spin: int = 50
var multiplicador_base_spin: float = 1.0


static func criar_a_partir_da_fase(fase: Fase, velocidade_atual: float) -> RegrasJogo:
	var regras := RegrasJogo.new()
	regras.velocidade = velocidade_atual
	regras.total_etapas_fixacao = fase.total_etapas_fixacao
	regras.max_resets_fixacao = fase.max_resets_fixacao
	# AQUI
	regras.pecas_maximas = fase.pecas_maximas
	regras.fichas_base_spin = fase.fichas_base_spin
	regras.multiplicador_base_spin = fase.multiplicador_base_spin
	return regras
