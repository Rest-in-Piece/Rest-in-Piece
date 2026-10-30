
# "a peça deixa imagens residuais que apagam atrás dela enquanto se move"
class_name EfeitoVisualRastro
extends EfeitoVisual

@export var duracao: float = 0.3


func ao_celula_movida(contexto: ContextoVisual, origem: Vector2) -> void:
	var cor_inicial := Color(cor.r, cor.g, cor.b, intensidade * 0.35)
	soltar_flash(contexto.camada, origem, contexto.tamanho - Vector2(6.0, 6.0), cor_inicial, duracao)
