# efeito visual de UM bloco de vidro se quebrando: passa pelos frames rachados e some.
# Vive só enquanto toca e depois se apaga sozinho. Não participa da lógica: quando ele
# aparece, o bloco já foi removido do tabuleiro (a quebra é imediata, só o visual dura).

class_name EfeitoQuebraVidro
extends Sprite2D

## quanto tempo cada frame (inteiro, rachado, mais rachado...) fica na tela
const DURACAO_POR_FRAME: float = 0.07
## tempo do desaparecimento final
const DURACAO_SUMIR: float = 0.15


# cria o efeito sobre a célula "posicao_grid" do tabuleiro. "frames" são as coordenadas
# do atlas, em ordem; se vier vazio usa "atlas_atual" (o bloco só some)
static func tocar(tabuleiro: TileMapLayer, id_fonte: int, posicao_grid: Vector2i, frames: Array[Vector2i], atlas_atual: Vector2i) -> void:
	var fonte := tabuleiro.tile_set.get_source(id_fonte) as TileSetAtlasSource
	if fonte == null:
		return
	
	var frames_do_efeito: Array[Vector2i] = []
	if frames.is_empty():
		frames_do_efeito.append(atlas_atual)
	else:
		frames_do_efeito.append_array(frames)
	
	var efeito := EfeitoQuebraVidro.new()
	efeito.texture = fonte.texture
	efeito.region_enabled = true
	efeito.region_rect = fonte.get_tile_texture_region(frames_do_efeito[0])
	# map_to_local devolve o centro da célula, e o Sprite2D é centralizado
	efeito.position = tabuleiro.map_to_local(posicao_grid)
	tabuleiro.add_child(efeito)
	efeito._animar(fonte, frames_do_efeito)


func _animar(fonte: TileSetAtlasSource, frames: Array[Vector2i]) -> void:
	var tween := create_tween()
	
	# o primeiro frame já está na tela (bloco inteiro), então só espera; os outros trocam
	tween.tween_interval(DURACAO_POR_FRAME)
	for i in range(1, frames.size()):
		tween.tween_callback(_mostrar_frame.bind(fonte, frames[i]))
		tween.tween_interval(DURACAO_POR_FRAME)
	
	tween.tween_property(self, "modulate:a", 0.0, DURACAO_SUMIR)
	tween.tween_callback(queue_free)


func _mostrar_frame(fonte: TileSetAtlasSource, atlas: Vector2i) -> void:
	region_rect = fonte.get_tile_texture_region(atlas)
