extends SceneTree

const BOMBA: Peca = preload("res://entities/pecas/peca_bomba.tres")
const PECA_O: Peca = preload("res://entities/pecas/peca_o.tres")

var jogo: Node
var tabuleiro: TileMapLayer
var contextos: Array[ContextoPontuacao] = []
var falhas: Array[String] = []


func _initialize():
	_executar.call_deferred()


func _executar():
	root.get_node("AutoBus").jogada_resolvida.connect(func(contexto: ContextoPontuacao): contextos.append(contexto))
	var testes: Array[Callable] = [
		_teste_centro, _teste_topo_esquerdo, _teste_topo_direito,
		_teste_fundo_esquerdo, _teste_fundo_direito, _teste_sem_alvos,
		_teste_bonus_dos_blocos, _teste_explosao_com_linha_completa,
		_teste_linha_normal, _teste_hard_drop_com_delay,
		_teste_hold_e_rotacao, _teste_bolsa, _teste_sprite,
	]
	for teste in testes:
		_preparar_jogo()
		teste.call()
		jogo.free()
	if falhas.is_empty():
		print("BOMBA: %d testes passaram." % testes.size())
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)


func _preparar_jogo():
	contextos.clear()
	var cena_jogo: PackedScene = load("res://core/tetris.tscn")
	jogo = cena_jogo.instantiate()
	jogo.reliquias_iniciais.clear()
	root.add_child(jogo)
	jogo.set_process(false)
	tabuleiro = jogo.tabuleiro
	tabuleiro.set_process(false)
	tabuleiro.limpar_grid()
	tabuleiro.peca_ativa = []
	tabuleiro.prox_peca = PECA_O.criar_copia()
	tabuleiro.prox_peca_atlas = PECA_O.coords_no_atlas


func _verificar(condicao: bool, mensagem: String):
	if not condicao:
		falhas.append(mensagem)


func _ativar_peca(posicao: Vector2i, recurso: Peca = BOMBA):
	tabuleiro.limpar_peca()
	tabuleiro.peca = recurso.criar_copia()
	tabuleiro.peca_atlas = recurso.coords_no_atlas
	tabuleiro.peca_ativa = recurso.angulo_0
	tabuleiro.pos_atual = posicao
	tabuleiro.indice_rotacao = 0
	tabuleiro.ultima_acao_foi_rotacao = false
	tabuleiro.casas_descidas_hard_drop = 0
	tabuleiro.etapas_fixacao = 0.0
	tabuleiro.desenhar_peca(tabuleiro.peca_ativa, posicao, recurso.coords_no_atlas)


func _fixar_bloco(posicao: Vector2i, pontos: int = 10, multiplicador: float = 1.0):
	tabuleiro.set_cell(posicao, 0, PECA_O.coords_no_atlas)
	var bloco := BlocoFixado.new()
	bloco.tipo_peca = "O"
	bloco.pontos = pontos
	bloco.multiplicador = multiplicador
	tabuleiro.blocos_fixados[posicao] = bloco


func _contexto() -> ContextoPontuacao:
	_verificar(contextos.size() == 1, "Cada travamento deve resolver exatamente uma jogada.")
	return contextos.back() if not contextos.is_empty() else ContextoPontuacao.new()


func _teste_centro():
	var centro := Vector2i(5, 10)
	for y in range(9, 12):
		for x in range(4, 7):
			if Vector2i(x, y) != centro:
				_fixar_bloco(Vector2i(x, y))
	_fixar_bloco(Vector2i(7, 10))
	_fixar_bloco(Vector2i(5, 8))
	_ativar_peca(centro)
	tabuleiro.travar_peca()
	var contexto := _contexto()
	_verificar(jogo.pontuacao == 80, "A explosao central deve pontuar apenas os oito vizinhos.")
	_verificar(contexto.linhas.size() == 3 and contexto.linhas_destruidas == 0, "Tres linhas parciais nao contam como linhas completas.")
	_verificar(is_equal_approx(jogo.velocidade_atual, jogo.fase.velocidade_inicial), "A explosao parcial nao deve acelerar o jogo.")
	for y in range(9, 12):
		for x in range(4, 7):
			var posicao := Vector2i(x, y)
			_verificar(tabuleiro.get_cell_source_id(posicao) == -1 and not tabuleiro.blocos_fixados.has(posicao), "A explosao deve apagar tiles e dados em %s." % posicao)
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(7, 10)), "O bloco fora do 3x3 deve sobreviver.")
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(5, 8)), "Os blocos acima do buraco nao devem cair individualmente.")
	_verificar(jogo.pecas_posicionadas == 1, "A bomba consome uma peca do limite da fase.")


func _teste_topo_esquerdo():
	_testar_borda(Vector2i(1, 1))


func _teste_topo_direito():
	_testar_borda(Vector2i(10, 1))


func _teste_fundo_esquerdo():
	_testar_borda(Vector2i(1, 20))


func _teste_fundo_direito():
	_testar_borda(Vector2i(10, 20))


func _testar_borda(centro: Vector2i):
	var borda: Dictionary[Vector2i, Vector2i] = {}
	for posicao in tabuleiro.get_used_cells():
		borda[posicao] = tabuleiro.get_cell_atlas_coords(posicao)
	for y in range(maxi(1, centro.y - 1), mini(20, centro.y + 1) + 1):
		for x in range(maxi(1, centro.x - 1), mini(10, centro.x + 1) + 1):
			if Vector2i(x, y) != centro:
				_fixar_bloco(Vector2i(x, y))
	_ativar_peca(centro)
	tabuleiro.travar_peca()
	_verificar(jogo.pontuacao == 30, "A bomba no canto %s deve destruir tres vizinhos." % centro)
	for posicao in borda:
		_verificar(tabuleiro.get_cell_atlas_coords(posicao) == borda[posicao], "A borda em %s deve continuar intacta." % posicao)
	_contexto()


func _teste_sem_alvos():
	_ativar_peca(Vector2i(5, 20))
	tabuleiro.travar_peca()
	_verificar(jogo.pontuacao == 0 and _contexto().linhas.is_empty(), "Uma bomba sem alvos nao concede pontos.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 20)) == -1, "A bomba desaparece mesmo sem alvos.")


func _teste_bonus_dos_blocos():
	var reliquia := ReliquiaFormatoDePeca.new()
	reliquia.formatos_aceitos = ["O"]
	jogo.adquirir_reliquia(reliquia)
	_fixar_bloco(Vector2i(4, 11), 10, 1.0)
	_fixar_bloco(Vector2i(5, 11), 20, 2.0)
	# Tiles desenhados sem metadados tambem pontuam, como nas linhas completas.
	tabuleiro.set_cell(Vector2i(6, 11), 0, PECA_O.coords_no_atlas)
	_ativar_peca(Vector2i(5, 10))
	tabuleiro.travar_peca()
	var contexto := _contexto()
	_verificar(jogo.pontuacao == 90, "A linha parcial deve aplicar bonus de formato e multiplicadores da esquerda para a direita.")
	_verificar(contexto.linhas[0].blocos[0].posicao.x == 4 and contexto.linhas[0].blocos[2].posicao.x == 6, "A ordem dos blocos deve ser esquerda para direita.")
	_verificar(contexto.linhas[0].altura == 10, "A linha parcial deve preservar a altura original.")


func _teste_explosao_com_linha_completa():
	_fixar_bloco(Vector2i(4, 10))
	for x in range(1, 11):
		_fixar_bloco(Vector2i(x, 20))
	_ativar_peca(Vector2i(5, 10))
	tabuleiro.travar_peca()
	var contexto := _contexto()
	_verificar(jogo.pontuacao == 110, "Explosao e linha completa na mesma jogada devem somar, sem perder nem duplicar pontos.")
	_verificar(contexto.linhas.size() == 2 and contexto.linhas_destruidas == 1, "Somente a linha completa deve entrar no contador.")
	_verificar(is_equal_approx(jogo.velocidade_atual, jogo.fase.velocidade_inicial + jogo.fase.aceleracao), "Somente a linha completa deve aumentar a velocidade.")
	_verificar(jogo.linhas_pendentes.is_empty(), "As linhas pendentes devem ser consumidas apos a jogada.")
	_ativar_peca(Vector2i(5, 20))
	tabuleiro.travar_peca()
	_verificar(jogo.pontuacao == 110, "A jogada seguinte nao deve pontuar a explosao anterior de novo.")


func _teste_linha_normal():
	for x in range(1, 11):
		if x not in [4, 5]:
			_fixar_bloco(Vector2i(x, 20))
	_ativar_peca(Vector2i(5, 20), PECA_O)
	tabuleiro.travar_peca()
	_verificar(jogo.pontuacao == 100 and _contexto().linhas_destruidas == 1, "Uma peca normal deve continuar limpando e pontuando uma linha completa.")
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(4, 20)), "Os blocos da peca normal acima da linha limpa devem descer.")


func _teste_hard_drop_com_delay():
	_fixar_bloco(Vector2i(5, 20))
	_ativar_peca(Vector2i(5, 2))
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.pos_atual == Vector2i(5, 19) and jogo.pontuacao == 0, "Hard drop com delay deve apenas posicionar a bomba.")
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(5, 20)), "A bomba nao deve explodir antes de travar.")
	tabuleiro.etapas_fixacao = tabuleiro.total_etapas_fixacao
	tabuleiro._process(1.0 / 60.0)
	_verificar(jogo.pontuacao == 10 and _contexto().casas_hard_drop == 17, "O travamento por tempo deve explodir e preservar a distancia do hard drop.")


func _teste_hold_e_rotacao():
	_ativar_peca(Vector2i(5, 2))
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca_armazenada.explode_ao_travar and jogo.pontuacao == 0, "Hold deve guardar o efeito da bomba sem explodir.")
	tabuleiro.pode_armazenar = true
	tabuleiro.armazenar_peca_atual()
	tabuleiro.rotacionar_peca(1)
	_verificar(tabuleiro.peca.tipo_peca == "BOMBA" and tabuleiro.pos_atual == Vector2i(5, 2), "A bomba deve voltar do hold e girar sem deslocamento SRS.")
	_verificar(tabuleiro.peca_ativa == [Vector2i.ZERO], "A bomba deve manter a forma de um bloco.")
	_fixar_bloco(Vector2i(5, 20))
	tabuleiro.cair_imediatamente(true)
	_verificar(jogo.pontuacao == 10 and not _contexto().teve_spin(), "A bomba do hold deve explodir no travamento imediato, sem bonus de spin.")


func _teste_bolsa():
	var quantidade: int = 0
	for peca_da_bolsa in jogo.bolsa_de_pecas:
		if peca_da_bolsa.explode_ao_travar:
			quantidade += 1
	_verificar(quantidade == 1, "A bolsa inicial deve conter uma bomba.")
	var copia := BOMBA.criar_copia()
	_verificar(copia.explode_ao_travar, "Copias da bomba devem manter o efeito.")
	var contexto := ContextoPontuacao.new()
	var parcial := LinhaPontuada.new()
	parcial.completa = false
	contexto.linhas.append(parcial)
	var reliquia := ReliquiaPecasMaximasPorLinhas.new()
	reliquia.ao_pontuar(contexto)
	_verificar(reliquia.linhas_acumuladas == 0, "A explosao parcial nao deve contar para a reliquia de pecas extras.")


func _teste_sprite():
	var fonte: TileSetAtlasSource = tabuleiro.tile_set.get_source(BOMBA.id_fonte_tiles)
	var fonte_previa: TileSetAtlasSource = jogo.hud.tile_map_proxima_peca.tile_set.get_source(BOMBA.id_fonte_tiles)
	_verificar(fonte != fonte_previa, "A grade e o HUD devem ter fontes independentes para renderizar a mesma textura.")
	var imagem: Image = fonte.texture.get_image()
	_verificar(imagem.get_size() == Vector2i(32, 32), "O sprite importado deve ocupar exatamente uma celula de 32x32.")
	_verificar(imagem.get_pixel(0, 0).a == 0.0, "O fundo do sprite deve ser transparente.")
	_verificar(imagem.get_pixel(16, 20).a > 0.0, "O corpo da bomba deve estar visivel na textura.")
	_ativar_peca(Vector2i(5, 10))
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 10)) == 1, "A bomba na grade deve usar a textura propria.")
	tabuleiro.mover_peca(Vector2i.RIGHT)
	_verificar(tabuleiro.get_cell_source_id(Vector2i(6, 10)) == 1 and tabuleiro.get_cell_source_id(Vector2i(5, 10)) == -1, "A movimentacao deve manter o sprite sem deixar o tile anterior.")
	jogo.hud.atualizar_proxima_peca(BOMBA, BOMBA.coords_no_atlas)
	jogo.hud.atualizar_peca_armazenada(BOMBA, BOMBA.coords_no_atlas)
	_verificar(jogo.hud.tile_map_proxima_peca.get_cell_source_id(Vector2i.ZERO) == 1, "A previa deve usar o sprite da bomba.")
	_verificar(jogo.hud.tile_map_peca_armazenada.get_cell_source_id(Vector2i.ZERO) == 1, "O hold deve usar o sprite da bomba.")
	_ativar_peca(Vector2i(5, 10), PECA_O)
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 10)) == 0, "As pecas normais devem continuar usando o atlas original.")
