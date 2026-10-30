
# dados de UMA célula entregues a um EfeitoVisual (posição, tamanho e lados expostos)

class_name ContextoVisual
extends RefCounted

const TOPO: int = 1
const DIREITA: int = 2
const BAIXO: int = 4
const ESQUERDA: int = 8

var camada: Node2D  # onde entram nós soltos, que não seguem a célula (flash, poeira, rastro)
var tamanho: Vector2
var posicao: Vector2  # centro da célula, no espaço da camada
var fase: float = 0.0  # 0..1, fixa por célula (evita todas brilharem juntas)
var bordas_expostas: int = 0  # lados sem vizinho com o mesmo efeito
var retangulo: Rect2  # só nos hooks de peça inteira: retângulo que envolve a peça


func tem_borda(borda: int) -> bool:
	return (bordas_expostas & borda) != 0
