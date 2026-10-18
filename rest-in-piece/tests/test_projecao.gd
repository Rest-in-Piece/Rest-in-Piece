extends SceneTree

const PECA_O: Peca = preload("res://entities/pecas/peca_o.tres")
const PECA_I: Peca = preload("res://entities/pecas/peca_i.tres")
const PECA_T: Peca = preload("res://entities/pecas/peca_t.tres")
const PECA_L: Peca = preload("res://entities/pecas/peca_l.tres")
const BOMBA: Peca = preload("res://entities/pecas/peca_bomba.tres")
const AREIA: Peca = preload("res://entities/pecas/peca_areia_l.tres")
const FANTASMA: Peca = preload("res://entities/pecas/peca_fantasma_t.tres")
const FANTASMA_O: Peca = preload("res://entities/pecas/peca_fantasma_o.tres")

var jogo: Node
var tabuleiro: TileMapLayer
var falhas: Array[String] = []


func _initialize():
	_executar.call_deferred()


func _executar():
	var testes: Array[Callable] = [
		_teste_camada_visual, _teste_formatos_e_rotacoes, _teste_sem_efeitos_colaterais,
		_teste_pilha_e_buracos, _teste_movimento_rotacao_e_gravidade, _teste_hold,
		_teste_substituicao, _teste_bomba, _teste_areia, _teste_formatos_areia,
		_teste_fantasma_parcial, _teste_fantasma_sem_espaco, _teste_reinicio_e_parada,
		_teste_game_over, _teste_limpeza_e_ausencia_de_peca,
		_teste_materializacao_manual, _teste_fantasma_com_buracos,
		_teste_fantasma_com_espaco_acima_do_fundo, _teste_areia_com_fantasma,
	]
	for teste in testes:
		_preparar_jogo()
		teste.call()
		jogo.free()
	if falhas.is_empty():
		print("PROJECAO: %d testes passaram (todos os formatos e rotacoes, colisoes, hold, Bomba, Areia e Fantasma)." % testes.size())
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)


func _preparar_jogo():
	jogo = load("res://core/tetris.tscn").instantiate()
	jogo.reliquias_iniciais.clear()
	jogo.pecas_sorteaveis.clear()
	jogo.pecas_sorteaveis_2.clear()
	jogo.pecas_sorteaveis_3.clear()
	jogo.peca_extra = null
	jogo.som_completar_linha.clear()
	jogo.som_passar_fase.clear()
	root.add_child(jogo)
	jogo.set_process(false)
	tabuleiro = jogo.tabuleiro
	tabuleiro.set_process(false)
	_limpar_cenario()


func _limpar_cenario():
	tabuleiro.limpar_peca()
	tabuleiro.limpar_grid()
	tabuleiro.peca_ativa = []
	tabuleiro.jogo_rodando = true
	tabuleiro.prox_peca = PECA_O.criar_copia()
	tabuleiro.prox_peca_atlas = PECA_O.coords_no_atlas


func _ativar(recurso: Peca, posicao := Vector2i(5, 3), rotacao: int = 0):
	tabuleiro.limpar_peca()
	tabuleiro.peca = recurso.criar_copia()
	tabuleiro.peca_atlas = recurso.coords_no_atlas
	tabuleiro.peca_ativa = tabuleiro.obter_rotacoes(recurso)[rotacao]
	tabuleiro.indice_rotacao = rotacao
	tabuleiro.pos_atual = posicao
	tabuleiro.ultima_acao_foi_rotacao = false
	tabuleiro.casas_descidas_hard_drop = 0
	tabuleiro.etapas_queda = 0.0
	tabuleiro.etapas_fixacao = 0.0
	tabuleiro.jogo_rodando = true
	tabuleiro.desenhar_peca(tabuleiro.peca_ativa, posicao, recurso.coords_no_atlas)


func _fixar(posicao: Vector2i):
	tabuleiro.set_cell(posicao, PECA_O.id_fonte_tiles, PECA_O.coords_no_atlas)
	var bloco := BlocoFixado.new()
	bloco.tipo_peca = "O"
	tabuleiro.blocos_fixados[posicao] = bloco


func _grid() -> Dictionary:
	var celulas: Dictionary = {}
	for posicao in tabuleiro.get_used_cells():
		celulas[posicao] = [tabuleiro.get_cell_source_id(posicao), tabuleiro.get_cell_atlas_coords(posicao), tabuleiro.get_cell_alternative_tile(posicao)]
	return celulas


func _verificar(condicao: bool, mensagem: String):
	if not condicao:
		falhas.append(mensagem)


func _verificar_posicoes(atuais: Array, esperadas: Array):
	_verificar(atuais.size() == esperadas.size(), "A projecao deve ter as celulas esperadas: %s; atuais: %s." % [esperadas, atuais])
	for posicao in esperadas:
		_verificar(posicao in atuais, "A projecao deve incluir %s; atuais: %s." % [posicao, atuais])


func _verificar_atualizada():
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), tabuleiro.obter_posicoes_da_projecao())
	for posicao in tabuleiro.camada_projecao.get_used_cells():
		_verificar(tabuleiro.posicao_esta_no_tabuleiro(posicao), "A projecao deve respeitar as bordas.")
		_verificar(tabuleiro.camada_projecao.get_cell_source_id(posicao) == tabuleiro.peca.id_fonte_tiles, "A projecao deve preservar a textura da peca atual.")
		_verificar(tabuleiro.camada_projecao.get_cell_atlas_coords(posicao) == tabuleiro.peca_atlas, "A projecao deve preservar a cor do atlas atual.")


func _teste_camada_visual():
	_ativar(PECA_T)
	_verificar(tabuleiro.camada_projecao != tabuleiro.camada_fantasma, "A projecao nao pode reutilizar a camada da peca especial Fantasma.")
	_verificar(tabuleiro.camada_projecao.tile_set == tabuleiro.tile_set, "A projecao deve usar os assets originais do tabuleiro.")
	_verificar(not tabuleiro.camada_projecao.collision_enabled and not tabuleiro.camada_projecao.navigation_enabled, "A projecao nao deve adicionar colisoes ou navegacao.")
	_verificar(tabuleiro.camada_projecao.z_index < 0 and is_equal_approx(tabuleiro.camada_projecao.modulate.a, 0.25), "A projecao deve aparecer transparente e atras da peca atual.")
	_verificar_atualizada()


func _teste_formatos_e_rotacoes():
	for recurso in tabuleiro.pecas:
		for rotacao in range(4):
			_limpar_cenario()
			_ativar(recurso, Vector2i(5, 3), rotacao)
			var maior_y: int = -100
			for bloco in tabuleiro.peca_ativa:
				maior_y = maxi(maior_y, bloco.y)
			var destino := Vector2i(5, tabuleiro.LINHAS - maior_y)
			_verificar(tabuleiro.obter_posicao_de_aterrissagem() == destino, "Todo formato deve projetar a mesma posicao que a queda ate o fundo.")
			_verificar_atualizada()
			while tabuleiro.pode_mover(Vector2i.DOWN):
				tabuleiro.mover_peca(Vector2i.DOWN)
			_verificar(tabuleiro.pos_atual == destino, "A projecao deve coincidir com a queda real em todas as rotacoes.")


func _teste_sem_efeitos_colaterais():
	_fixar(Vector2i(5, 17))
	_ativar(PECA_T)
	var grid: Dictionary = _grid()
	var dados: Dictionary = tabuleiro.blocos_fixados.duplicate()
	var posicao: Vector2i = tabuleiro.pos_atual
	tabuleiro.ultima_acao_foi_rotacao = true
	tabuleiro.casas_descidas_hard_drop = 7
	tabuleiro.etapas_queda = 9.0
	tabuleiro.etapas_fixacao = 3.0
	for i in range(10):
		tabuleiro.atualizar_projecao()
	_verificar(_grid() == grid and tabuleiro.blocos_fixados == dados, "Desenhar a projecao nao pode modificar tiles fixos ou seus dados.")
	_verificar(tabuleiro.pos_atual == posicao and tabuleiro.indice_rotacao == 0 and tabuleiro.ultima_acao_foi_rotacao, "A projecao nao pode mover, girar ou invalidar um spin.")
	_verificar(tabuleiro.casas_descidas_hard_drop == 7 and tabuleiro.etapas_queda == 9.0 and tabuleiro.etapas_fixacao == 3.0, "A projecao nao pode alterar os temporizadores ou a distancia de hard drop.")
	_verificar(jogo.pontuacao == 0 and jogo.pecas_posicionadas == 0, "A projecao nao pode pontuar nem consumir um turno.")


func _teste_pilha_e_buracos():
	_fixar(Vector2i(4, 15))
	_ativar(PECA_O)
	_verificar(tabuleiro.obter_posicao_de_aterrissagem() == Vector2i(5, 14), "A projecao de uma peca comum deve parar sobre o primeiro apoio, sem atravessar buracos.")
	var projetadas: Array[Vector2i] = tabuleiro.obter_posicoes_da_projecao()
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.pos_atual == Vector2i(5, 14) and jogo.pecas_posicionadas == 0, "O hard drop deve preservar seu delay e coincidir com a projecao.")
	var reais: Array[Vector2i] = []
	for bloco in tabuleiro.peca_ativa:
		reais.append(tabuleiro.pos_atual + bloco)
	_verificar_posicoes(projetadas, reais)


func _teste_movimento_rotacao_e_gravidade():
	_ativar(PECA_I)
	var antes: Array[Vector2i] = tabuleiro.camada_projecao.get_used_cells()
	tabuleiro.mover_peca(Vector2i.LEFT)
	_verificar(tabuleiro.camada_projecao.get_used_cells() != antes, "Mover a peca deve mover sua projecao imediatamente.")
	_verificar_atualizada()
	tabuleiro.rotacionar_peca(1)
	_verificar(tabuleiro.indice_rotacao == 1, "A rotacao original deve continuar funcionando.")
	_verificar_atualizada()
	var altura: int = tabuleiro.pos_atual.y
	tabuleiro.etapas_queda = tabuleiro.total_etapas
	tabuleiro._process(1.0 / 60.0)
	_verificar(tabuleiro.pos_atual.y == altura + 1, "A gravidade deve continuar funcionando.")
	_verificar_atualizada()
	while tabuleiro.pode_mover(Vector2i.LEFT):
		tabuleiro.mover_peca(Vector2i.LEFT)
	antes = tabuleiro.camada_projecao.get_used_cells()
	tabuleiro.mover_peca(Vector2i.LEFT)
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), antes)
	_verificar_atualizada()


func _teste_hold():
	_ativar(BOMBA)
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca.tipo_peca == "O" and tabuleiro.camada_projecao.get_used_cells().size() == 4, "Guardar a Bomba deve mostrar a projecao da nova peca O.")
	_verificar_atualizada()
	tabuleiro.pode_armazenar = true
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca.tem_efeito(EfeitoExplosao) and tabuleiro.camada_projecao.get_used_cells().size() == 1, "Retirar a Bomba da reserva deve atualizar formato e textura da projecao.")
	_verificar_atualizada()


func _teste_substituicao():
	_fixar(Vector2i(5, 14))
	_ativar(PECA_L)
	_verificar(tabuleiro.substituir_peca_atual(FANTASMA), "A substituicao pela Fantasma deve continuar funcionando.")
	_verificar(tabuleiro.obter_posicao_de_aterrissagem().y == 20, "A projecao da Fantasma deve ignorar a pilha enquanto houver espaco vazio, assim como sua queda.")
	_verificar_atualizada()
	_verificar(tabuleiro.substituir_peca_atual(BOMBA), "A substituicao pela Bomba deve continuar funcionando.")
	_verificar(tabuleiro.camada_fantasma.get_used_cells().is_empty(), "Substituir a Fantasma deve limpar somente sua camada ativa.")
	_verificar_atualizada()


func _teste_bomba():
	_fixar(Vector2i(5, 16))
	_ativar(BOMBA)
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), [Vector2i(5, 15)])
	_verificar(tabuleiro.blocos_fixados.size() == 1 and jogo.pontuacao == 0, "A projecao nao pode detonar uma Bomba.")
	tabuleiro.cair_imediatamente(true)
	_verificar(tabuleiro.blocos_fixados.is_empty() and jogo.pontuacao == 10, "A Bomba real deve manter a explosao e a pontuacao originais.")
	_verificar(tabuleiro.peca.tipo_peca == "O", "Depois de travar deve surgir a proxima peca.")
	_verificar_atualizada()


func _teste_areia():
	for y in range(17, 21):
		for x in range(1, 11):
			if x not in [5, 10]:
				_fixar(Vector2i(x, y))
	_ativar(AREIA, Vector2i(4, 3))
	var esperadas: Array[Vector2i] = [Vector2i(3, 16), Vector2i(4, 16), Vector2i(5, 19), Vector2i(5, 20)]
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), esperadas)
	var grid: Dictionary = _grid()
	tabuleiro.atualizar_projecao()
	_verificar(_grid() == grid, "Prever a queda individual da Areia nao pode modificar a pilha.")
	tabuleiro.cair_imediatamente(true)
	for posicao in esperadas:
		_verificar(tabuleiro.get_cell_source_id(posicao) == AREIA.id_fonte_tiles and tabuleiro.blocos_fixados.has(posicao), "A Areia real deve assentar nas mesmas posicoes da projecao.")
	_verificar(jogo.pecas_posicionadas == 1, "A projecao da Areia nao pode consumir turnos extras.")


func _teste_formatos_areia():
	for recurso in tabuleiro.pecas:
		if not recurso.tem_efeito(EfeitoAreia):
			continue
		for rotacao in range(4):
			_limpar_cenario()
			for x in range(1, 11):
				_fixar(Vector2i(x, 14 + x % 4))
			var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
			_ativar(recurso, Vector2i(5, 3), rotacao)
			var previstas: Array[Vector2i] = tabuleiro.camada_projecao.get_used_cells()
			tabuleiro.cair_imediatamente(true)
			var novas: Array[Vector2i] = []
			for posicao in tabuleiro.blocos_fixados:
				if not originais.has(posicao):
					novas.append(posicao)
			_verificar_posicoes(previstas, novas)
			for posicao in originais:
				_verificar(tabuleiro.blocos_fixados.get(posicao) == originais[posicao], "A Areia e sua projecao devem preservar os blocos anteriores.")


func _teste_fantasma_parcial():
	for posicao in [Vector2i(4, 20), Vector2i(5, 20), Vector2i(5, 19), Vector2i(5, 12)]:
		_fixar(posicao)
	var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
	_ativar(FANTASMA)
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), [Vector2i(6, 20)])
	_verificar(tabuleiro.camada_fantasma.get_used_cells().size() == 4, "A projecao deve coexistir com a camada da peca especial Fantasma.")
	_verificar(tabuleiro.camada_projecao.modulate.a < tabuleiro.camada_fantasma.modulate.a, "A projecao deve ser mais transparente que a Fantasma ativa.")
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.blocos_fixados.size() == originais.size() + 1 and tabuleiro.blocos_fixados.has(Vector2i(6, 20)), "A materializacao deve preencher exatamente o vazio projetado.")
	for posicao in originais:
		_verificar(tabuleiro.blocos_fixados.get(posicao) == originais[posicao], "A projecao nao pode substituir blocos ocupados na materializacao.")
	_verificar_atualizada()


func _teste_fantasma_sem_espaco():
	# colunas 4, 5 e 6 totalmente cheias: nao existe celula vazia para a Fantasma preencher
	for y in range(1, 21):
		for x in [4, 5, 6]:
			_fixar(Vector2i(x, y))
	_ativar(FANTASMA)
	_verificar(tabuleiro.camada_projecao.get_used_cells().is_empty(), "Se nenhuma celula puder materializar, nao deve haver uma projecao sobre os blocos existentes.")
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.blocos_fixados.size() == 60 and jogo.pecas_posicionadas == 1, "Uma materializacao vazia deve continuar encerrando somente um turno.")


func _teste_reinicio_e_parada():
	_ativar(PECA_T)
	tabuleiro.parar_jogo()
	tabuleiro.atualizar_projecao()
	_verificar(tabuleiro.camada_projecao.get_used_cells().is_empty(), "Parar o jogo deve remover a projecao.")
	jogo.iniciar_novo_jogo()
	_verificar(tabuleiro.jogo_rodando and not tabuleiro.camada_projecao.get_used_cells().is_empty(), "Reiniciar deve desenhar novamente a projecao da peca atual.")
	_verificar_atualizada()
	jogo.regras_atuais.pecas_maximas = 1
	_ativar(PECA_O)
	tabuleiro.cair_imediatamente(true)
	_verificar(not tabuleiro.jogo_rodando and tabuleiro.camada_projecao.get_used_cells().is_empty(), "Encerrar uma fase deve limpar a projecao sem criar outra peca.")


func _teste_game_over():
	for y in range(1, 4):
		for x in range(1, 11):
			_fixar(Vector2i(x, y))
	tabuleiro.peca = PECA_O.criar_copia()
	tabuleiro.peca_atlas = PECA_O.coords_no_atlas
	tabuleiro.criar_peca()
	_verificar(not tabuleiro.jogo_rodando and tabuleiro.camada_projecao.get_used_cells().is_empty(), "Um spawn bloqueado nao pode deixar uma projecao antiga na tela.")


func _teste_limpeza_e_ausencia_de_peca():
	_ativar(PECA_T)
	tabuleiro.limpar_peca()
	_verificar(tabuleiro.camada_projecao.get_used_cells().is_empty(), "Limpar a peca deve apagar sua projecao.")
	_ativar(FANTASMA)
	tabuleiro.limpar_peca()
	_verificar(tabuleiro.camada_projecao.get_used_cells().is_empty() and tabuleiro.camada_fantasma.get_used_cells().is_empty(), "Limpar a Fantasma deve apagar as duas camadas visuais.")
	_ativar(PECA_T)
	tabuleiro.limpar_grid()
	_verificar(tabuleiro.camada_projecao.get_used_cells().is_empty(), "Limpar o grid deve remover a projecao.")
	tabuleiro.peca = null
	tabuleiro.peca_ativa = []
	tabuleiro.atualizar_projecao()
	_verificar(tabuleiro.obter_posicoes_da_projecao().is_empty() and tabuleiro.obter_posicao_de_aterrissagem() == tabuleiro.pos_atual, "Nao pode haver loop de queda ou desenho quando nao existir uma peca ativa.")


func _teste_materializacao_manual():
	_fixar(Vector2i(5, 5))
	var original: BlocoFixado = tabuleiro.blocos_fixados[Vector2i(5, 5)]
	_ativar(FANTASMA, Vector2i(5, 6))
	_verificar(tabuleiro.camada_projecao.get_used_cells().size() == 4, "A projecao da Fantasma deve prever seu destino automatico no fundo.")
	tabuleiro.fixar_manualmente()
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.blocos_fixados.size() == 4, "A materializacao manual deve usar a posicao atual, nao a projecao. Turnos: %d; blocos: %s." % [jogo.pecas_posicionadas, tabuleiro.blocos_fixados.keys()])
	_verificar(tabuleiro.blocos_fixados.get(Vector2i(5, 5)) == original and tabuleiro.blocos_fixados.has(Vector2i(6, 6)), "A materializacao manual deve preservar os blocos existentes e preencher os vazios.")
	_verificar(not tabuleiro.blocos_fixados.has(Vector2i(5, 20)), "Os blocos da projecao nao podem se tornar permanentes ao materializar manualmente.")
	_verificar_atualizada()


# --- nova regra de queda da Fantasma ---

func _teste_fantasma_com_buracos():
	# colunas 4 e 5 cheias, com um buraco em (4,15) e outro em (5,18)
	for y in range(12, 21):
		for x in [4, 5]:
			if Vector2i(x, y) not in [Vector2i(4, 15), Vector2i(5, 18)]:
				_fixar(Vector2i(x, y))
	_ativar(FANTASMA_O, Vector2i(5, 2))
	var projetadas: Array[Vector2i] = tabuleiro.obter_posicoes_da_projecao()
	_verificar_posicoes(projetadas, [Vector2i(5, 18)])
	_verificar(tabuleiro.obter_posicao_de_aterrissagem() == Vector2i(5, 19), "A peca inteira desce ate o bloco mais fundo alcancar o buraco mais profundo.")
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(5, 18)) and not tabuleiro.blocos_fixados.has(Vector2i(4, 15)), "A materializacao real preenche exatamente o que a projecao mostrou.")
	_verificar_atualizada()


func _teste_fantasma_com_espaco_acima_do_fundo():
	# o fundo esta ocupado, mas as colunas ainda tem espaco logo acima dele
	for posicao in [Vector2i(4, 20), Vector2i(5, 20), Vector2i(5, 19), Vector2i(6, 20)]:
		_fixar(posicao)
	_ativar(FANTASMA)
	_verificar_posicoes(tabuleiro.camada_projecao.get_used_cells(), [Vector2i(4, 19), Vector2i(5, 18), Vector2i(6, 19)])
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.blocos_fixados.size() == 7 and jogo.pecas_posicionadas == 1, "A Fantasma fixa onde ainda ha espaco vazio, nao precisa chegar ao fundo.")


func _teste_areia_com_fantasma():
	# efeitos combinados: a projecao filtra as celulas ocupadas E depois assenta os graos
	var combinada := FANTASMA_O.criar_copia()
	combinada.efeitos.append(AREIA.efeitos[0])
	for posicao in [Vector2i(4, 20), Vector2i(4, 19)]:
		_fixar(posicao)
	_ativar(combinada, Vector2i(5, 3))
	var projetadas: Array[Vector2i] = tabuleiro.obter_posicoes_da_projecao()
	tabuleiro.cair_imediatamente(false)
	var novas: Array[Vector2i] = []
	for posicao in tabuleiro.blocos_fixados:
		if posicao.x == 5:
			novas.append(posicao)
	_verificar_posicoes(projetadas, novas)
	_verificar(novas.size() == 2 and tabuleiro.blocos_fixados.has(Vector2i(5, 20)) and tabuleiro.blocos_fixados.has(Vector2i(5, 19)), "Os dois graos livres da coluna 5 caem ate o fundo. Novas: %s" % [novas])
