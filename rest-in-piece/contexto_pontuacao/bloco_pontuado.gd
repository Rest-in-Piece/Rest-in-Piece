

# cópia de um quadradinho no momento de pontuar. As relíquias podem alterar pontos e
# multiplicador à vontade sem afetar os dados do bloco no tabuleiro.

class_name BlocoPontuado
extends RefCounted

var posicao: Vector2i
var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0


# o bloco_fixado pode ser nulo (tile sem dados); nesse caso usa os valores padrão
static func criar_a_partir_do_bloco_fixado(posicao_no_grid: Vector2i, bloco_fixado: BlocoFixado) -> BlocoPontuado:
	var bloco_pontuado := BlocoPontuado.new()
	bloco_pontuado.posicao = posicao_no_grid
	
	if bloco_fixado != null:
		bloco_pontuado.tipo_peca = bloco_fixado.tipo_peca
		bloco_pontuado.pontos = bloco_fixado.pontos
		bloco_pontuado.multiplicador = bloco_fixado.multiplicador
	
	return bloco_pontuado
