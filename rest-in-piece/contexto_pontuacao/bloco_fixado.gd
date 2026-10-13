

# dados de UM quadradinho já fixado no tabuleiro. O tetris.gd guarda um por posição.
# Os valores são capturados quando a peça trava: buffs dados depois à peça não alteram
# quadradinhos que já estão no grid.

class_name BlocoFixado
extends RefCounted

var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0
var resistencia: int = -1  # -1 = não é frágil
var pressao: int = 0       # maior peso já sentido (as rachaduras não "se curam")
var atlas_por_estagio: Array[Vector2i] = []

func eh_fragil() -> bool:
	return resistencia > 0

func obter_atlas_do_estagio() -> Vector2i:
	if atlas_por_estagio.is_empty() or resistencia <= 0:
		return Vector2i(-1, -1)
	var progresso: float = float(pressao) / resistencia
	var indice: int = clampi(int(progresso * atlas_por_estagio.size()), 0, atlas_por_estagio.size() - 1)
	return atlas_por_estagio[indice]

static func criar_a_partir_da_peca(peca_origem: Peca, travamento: TravamentoDePeca) -> BlocoFixado:
	var bloco_fixado := BlocoFixado.new()
	bloco_fixado.tipo_peca = peca_origem.tipo_peca
	bloco_fixado.pontos = peca_origem.obter_pontos_por_bloco() + travamento.pontos_extras_por_bloco
	bloco_fixado.multiplicador = peca_origem.obter_multiplicador_por_bloco() + travamento.multiplicador_extra_por_bloco
	if peca_origem.resistencia_ao_peso_por_bloco > 0:
		bloco_fixado.resistencia = peca_origem.resistencia_ao_peso_por_bloco
		bloco_fixado.atlas_por_estagio = peca_origem.atlas_por_estagio_de_dano
	return bloco_fixado
