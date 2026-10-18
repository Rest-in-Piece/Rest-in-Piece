# dados de UM quadradinho já fixado no tabuleiro. O tetris.gd guarda um por posição.
# Os valores são capturados quando a peça trava: buffs dados depois à peça não alteram
# quadradinhos que já estão no grid.

class_name BlocoFixado
extends RefCounted

var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0
# efeitos da peça que originou o bloco. Os que têm hooks de tabuleiro (areia, vidro...)
# continuam agindo sobre ele enquanto ele estiver no grid
var efeitos: Array[EfeitoDePeca] = []


static func criar_a_partir_da_peca(peca_origem: Peca, travamento: TravamentoDePeca) -> BlocoFixado:
	var bloco_fixado := BlocoFixado.new()
	bloco_fixado.tipo_peca = peca_origem.tipo_peca
	bloco_fixado.pontos = peca_origem.obter_pontos_por_bloco() + travamento.pontos_extras_por_bloco
	bloco_fixado.multiplicador = peca_origem.obter_multiplicador_por_bloco() + travamento.multiplicador_extra_por_bloco
	for efeito in peca_origem.efeitos:
		if efeito != null:
			bloco_fixado.efeitos.append(efeito)
	return bloco_fixado


# é exatamente este recurso (mesma instância)
func tem_efeito(efeito: EfeitoDePeca) -> bool:
	return efeitos.has(efeito)

# é um efeito do mesmo script (ex: qualquer vidro, mesmo de outro .tres)
func tem_efeito_do_mesmo_tipo(efeito: EfeitoDePeca) -> bool:
	for meu_efeito in efeitos:
		if meu_efeito.get_script() == efeito.get_script():
			return true
	return false
