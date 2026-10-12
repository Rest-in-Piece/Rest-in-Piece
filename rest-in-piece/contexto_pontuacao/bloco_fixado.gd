

# dados de UM quadradinho já fixado no tabuleiro. O tetris.gd guarda um por posição.
# Os valores são capturados quando a peça trava: buffs dados depois à peça não alteram
# quadradinhos que já estão no grid.

class_name BlocoFixado
extends RefCounted

var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0
var durabilidade: int = -1  # -1 = não quebra
var durabilidade_inicial: int = -1
var atlas_por_estagio: Array[Vector2i] = []

# (-1, -1) = sem troca de visual, a mesma convenção do get_cell_atlas_coords
func obter_atlas_do_estagio() -> Vector2i:
	if atlas_por_estagio.is_empty() or durabilidade_inicial <= 0:
		return Vector2i(-1, -1)
	var progresso: float = float(durabilidade_inicial - durabilidade) / durabilidade_inicial
	var indice: int = clampi(int(progresso * atlas_por_estagio.size()), 0, atlas_por_estagio.size() - 1)
	return atlas_por_estagio[indice]
	
static func criar_a_partir_da_peca(peca_origem: Peca, travamento: TravamentoDePeca) -> BlocoFixado:
	var bloco_fixado := BlocoFixado.new()
	bloco_fixado.tipo_peca = peca_origem.tipo_peca
	bloco_fixado.pontos = peca_origem.obter_pontos_por_bloco() + travamento.pontos_extras_por_bloco
	bloco_fixado.multiplicador = peca_origem.obter_multiplicador_por_bloco() + travamento.multiplicador_extra_por_bloco
	if peca_origem.durabilidade_por_bloco > 0:
		bloco_fixado.durabilidade = peca_origem.durabilidade_por_bloco
		bloco_fixado.durabilidade_inicial = peca_origem.durabilidade_por_bloco
		bloco_fixado.atlas_por_estagio = peca_origem.atlas_por_estagio_de_dano
	return bloco_fixado
