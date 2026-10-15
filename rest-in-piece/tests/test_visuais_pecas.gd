extends SceneTree

var falhas: Array[String] = []


func _initialize():
	_executar.call_deferred()


func _executar():
	var jogo: Node = load("res://core/tetris.tscn").instantiate()
	jogo.reliquias_iniciais.clear()
	root.add_child(jogo)
	jogo.set_process(false)
	jogo.tabuleiro.set_process(false)
	var mapas: Array[TileMapLayer] = [
		jogo.tabuleiro, jogo.tabuleiro.camada_fantasma, jogo.tabuleiro.camada_projecao,
		jogo.hud.tile_map_proxima_peca, jogo.hud.tile_map_peca_armazenada,
	]
	var quantidade: int = 0
	for arquivo in DirAccess.get_files_at("res://entities/pecas"):
		if not arquivo.ends_with(".tres"):
			continue
		var recurso: Resource = load("res://entities/pecas/" + arquivo)
		if not recurso is Peca:
			continue
		quantidade += 1
		for mapa in mapas:
			_verificar_visual(recurso, mapa)
	if quantidade == 0:
		falhas.append("Nenhum recurso de peca foi encontrado para verificar.")
	jogo.free()
	if falhas.is_empty():
		print("VISUAIS: %d pecas verificadas em %d camadas; fontes, tiles e pixels visiveis validos." % [quantidade, mapas.size()])
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)


func _verificar_visual(peca: Peca, mapa: TileMapLayer):
	var contexto: String = "%s em %s" % [peca.nome, mapa.name]
	if not mapa.tile_set.has_source(peca.id_fonte_tiles):
		falhas.append("Fonte de tiles inexistente: " + contexto)
		return
	var fonte := mapa.tile_set.get_source(peca.id_fonte_tiles) as TileSetAtlasSource
	if fonte == null or not fonte.has_tile(peca.coords_no_atlas):
		falhas.append("Coordenada de atlas inexistente %s: %s" % [peca.coords_no_atlas, contexto])
		return
	if fonte.texture == null:
		falhas.append("Textura ausente: " + contexto)
		return
	var imagem: Image = fonte.texture.get_image()
	if imagem == null or imagem.is_empty():
		falhas.append("Imagem vazia: " + contexto)
		return
	if imagem.is_compressed() and imagem.decompress() != OK:
		falhas.append("Nao foi possivel ler os pixels da textura: " + contexto)
		return
	var regiao: Rect2i = fonte.get_tile_texture_region(peca.coords_no_atlas)
	if regiao.size.x <= 0 or regiao.size.y <= 0 or not Rect2i(Vector2i.ZERO, imagem.get_size()).encloses(regiao):
		falhas.append("O tile esta fora dos limites da imagem: " + contexto)
		return
	for y in range(regiao.position.y, regiao.end.y):
		for x in range(regiao.position.x, regiao.end.x):
			if imagem.get_pixel(x, y).a > 0.0:
				return
	falhas.append("O tile e completamente transparente: " + contexto)
