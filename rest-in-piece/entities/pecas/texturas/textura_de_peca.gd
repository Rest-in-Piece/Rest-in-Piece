

# gera a imagem de UMA peça (ângulo 0) juntando os tiles dela do atlas. Usada pelos cards
# de recompensa e pela tela de remover peça. Só desenha; não sabe nada de lógica de jogo.

class_name TexturaDePeca
extends RefCounted


static func criar(peca_alvo: Peca, tile_set: TileSet) -> Texture2D:
	var fonte := tile_set.get_source(peca_alvo.id_fonte_tiles) as TileSetAtlasSource
	if fonte == null or peca_alvo.angulo_0.is_empty():
		return null
	
	var atlas: Image = fonte.texture.get_image()
	if atlas.is_compressed():
		atlas.decompress()
	var regiao: Rect2i = fonte.get_tile_texture_region(peca_alvo.coords_no_atlas)
	
	var minimo: Vector2i = peca_alvo.angulo_0[0]
	var maximo: Vector2i = peca_alvo.angulo_0[0]
	for celula in peca_alvo.angulo_0:
		minimo = Vector2i(mini(minimo.x, celula.x), mini(minimo.y, celula.y))
		maximo = Vector2i(maxi(maximo.x, celula.x), maxi(maximo.y, celula.y))
	var tamanho_em_celulas: Vector2i = maximo - minimo + Vector2i.ONE
	
	var imagem := Image.create(tamanho_em_celulas.x * regiao.size.x,
			tamanho_em_celulas.y * regiao.size.y, false, atlas.get_format())
	for celula in peca_alvo.angulo_0:
		imagem.blit_rect(atlas, regiao, (celula - minimo) * regiao.size)
	return ImageTexture.create_from_image(imagem)
