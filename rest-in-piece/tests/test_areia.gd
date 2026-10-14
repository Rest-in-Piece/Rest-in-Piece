extends SceneTree

const AREIA: Peca = preload("res://entities/pecas/peca_areia.tres")
const PECA_L: Peca = preload("res://entities/pecas/peca_l.tres")
const PECA_O: Peca = preload("res://entities/pecas/peca_o.tres")
const BOMBA: Peca = preload("res://entities/pecas/peca_bomba.tres")
const FORMATOS: Array[Peca] = [
	preload("res://entities/pecas/peca_i.tres"), PECA_O,
	preload("res://entities/pecas/peca_t.tres"), PECA_L,
	preload("res://entities/pecas/peca_j.tres"),
	preload("res://entities/pecas/peca_s.tres"), preload("res://entities/pecas/peca_z.tres"),
]

var jogo: Node
var tabuleiro: TileMapLayer
var contextos: Array[ContextoPontuacao] = []
var falhas: Array[String] = []


func _initialize():
	_executar.call_deferred()


func _executar():
	root.get_node("AutoBus").jogada_resolvida.connect(func(contexto: ContextoPontuacao): contextos.append(contexto))
	var testes: Array[Callable] = [
		_teste_imagem, _teste_sem_buracos, _teste_colunas_livres, _teste_alturas_diferentes,
		_teste_obstaculo, _teste_peca_comum, _teste_gravidade_e_delay, _teste_hold_e_rotacao,
		_teste_bonus_hard_drop, _teste_dados_e_bonus, _teste_linha, _teste_duas_linhas,
		_teste_bordas, _teste_formatos, _teste_substituicao, _teste_bolsa_e_sprite,
		_teste_limite_da_fase, _teste_fantasma_com_areia, _teste_bomba_apos_areia,
	]
	for teste in testes:
		_preparar_jogo()
		teste.call()
		jogo.free()
	if falhas.is_empty():
		print("AREIA: %d testes passaram (incluindo 7 formatos e 4 rotacoes)." % testes.size())
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)


func _preparar_jogo():
	contextos.clear()
	var cena: PackedScene = load("res://core/tetris.tscn")
	jogo = cena.instantiate()
	jogo.reliquias_iniciais.clear()
	root.add_child(jogo)
	jogo.set_process(false)
	tabuleiro = jogo.tabuleiro
	tabuleiro.set_process(false)
	tabuleiro.limpar_peca()
	tabuleiro.limpar_grid()
	tabuleiro.peca_ativa = []
	tabuleiro.prox_peca = PECA_O.criar_copia()
	tabuleiro.prox_peca_atlas = PECA_O.coords_no_atlas


func _verificar(condicao: bool, mensagem: String):
	if not condicao:
		falhas.append(mensagem)


func _ativar(posicao: Vector2i, recurso: Peca = AREIA, rotacao: int = 0):
	tabuleiro.limpar_peca()
	tabuleiro.peca = recurso.criar_copia()
	tabuleiro.peca_atlas = recurso.coords_no_atlas
	tabuleiro.peca_ativa = tabuleiro.obter_rotacoes(recurso)[rotacao]
	tabuleiro.pos_atual = posicao
	tabuleiro.indice_rotacao = rotacao
	tabuleiro.ultima_acao_foi_rotacao = false
	tabuleiro.casas_descidas_hard_drop = 0
	tabuleiro.etapas_queda = 0.0
	tabuleiro.etapas_fixacao = 0.0
	tabuleiro.jogo_rodando = true
	tabuleiro.desenhar_peca(tabuleiro.peca_ativa, posicao, recurso.coords_no_atlas)


func _fixar(posicao: Vector2i) -> BlocoFixado:
	tabuleiro.set_cell(posicao, 0, PECA_O.coords_no_atlas)
	var bloco := BlocoFixado.new()
	bloco.tipo_peca = "O"
	tabuleiro.blocos_fixados[posicao] = bloco
	return bloco


func _versao_areia(formato: Peca) -> Peca:
	var copia := formato.criar_copia()
	copia.cai_em_blocos_ao_travar = true
	copia.id_fonte_tiles = AREIA.id_fonte_tiles
	copia.coords_no_atlas = AREIA.coords_no_atlas
	return copia


func _contexto() -> ContextoPontuacao:
	_verificar(contextos.size() == 1, "O assentamento deve resolver exatamente uma jogada.")
	return contextos.back() if not contextos.is_empty() else ContextoPontuacao.new()


func _posicoes_areia() -> Array[Vector2i]:
	var posicoes: Array[Vector2i] = []
	for posicao in tabuleiro.blocos_fixados:
		if tabuleiro.get_cell_source_id(posicao) == AREIA.id_fonte_tiles:
			posicoes.append(posicao)
	return posicoes


func _verificar_posicoes(esperadas: Array[Vector2i]):
	var atuais := _posicoes_areia()
	_verificar(atuais.size() == esperadas.size(), "Nenhum grao deve ser perdido ou duplicado. Esperados: %s; atuais: %s." % [esperadas, atuais])
	for posicao in esperadas:
		_verificar(atuais.has(posicao), "Um grao deve assentar em %s; atuais: %s." % [posicao, atuais])
	for posicao in atuais:
		_verificar(tabuleiro.posicao_esta_no_tabuleiro(posicao), "A Areia nao pode atravessar o fundo ou as paredes.")
		var abaixo := posicao + Vector2i.DOWN
		_verificar(not tabuleiro.posicao_esta_no_tabuleiro(abaixo) or tabuleiro.get_cell_source_id(abaixo) != -1, "Todo grao deve terminar apoiado em %s." % posicao)


func _preservar_originais(originais: Dictionary):
	for posicao in originais:
		_verificar(tabuleiro.blocos_fixados.get(posicao) == originais[posicao], "O bloco existente em %s deve manter seus dados." % posicao)
		_verificar(tabuleiro.get_cell_atlas_coords(posicao) == PECA_O.coords_no_atlas, "A Areia nao pode substituir o tile existente em %s." % posicao)


func _teste_imagem():
	for y in range(17, 21):
		for x in range(1, 11):
			if x not in [5, 10]:
				_fixar(Vector2i(x, y))
	var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
	_ativar(Vector2i(4, 16))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(3, 16), Vector2i(4, 16), Vector2i(5, 19), Vector2i(5, 20)])
	_preservar_originais(originais)
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 15)) == -1 and tabuleiro.get_cell_source_id(Vector2i(5, 16)) == -1, "Os dois graos sobre o buraco devem sair das posicoes antigas.")
	_verificar(jogo.pecas_posicionadas == 1 and jogo.pontuacao == 0, "Os graos encerram um unico turno, sem pontuar apenas por cair.")
	_contexto()


func _teste_sem_buracos():
	for x in range(3, 6):
		_fixar(Vector2i(x, 17))
	_ativar(Vector2i(4, 16))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(3, 16), Vector2i(4, 16), Vector2i(5, 16), Vector2i(5, 15)])


func _teste_colunas_livres():
	_ativar(Vector2i(4, 10))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(3, 20), Vector2i(4, 20), Vector2i(5, 20), Vector2i(5, 19)])
	_verificar(tabuleiro.blocos_fixados.size() == 4, "Os quatro graos devem se conservar mesmo quando todos caem.")


func _teste_alturas_diferentes():
	_fixar(Vector2i(3, 14))
	_fixar(Vector2i(4, 18))
	_ativar(Vector2i(4, 13))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(3, 13), Vector2i(4, 17), Vector2i(5, 20), Vector2i(5, 19)])


func _teste_obstaculo():
	_fixar(Vector2i(3, 17))
	var obstaculo := _fixar(Vector2i(5, 18))
	_ativar(Vector2i(4, 16))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(3, 16), Vector2i(4, 20), Vector2i(5, 17), Vector2i(5, 16)])
	_verificar(tabuleiro.blocos_fixados.get(Vector2i(5, 18)) == obstaculo, "O primeiro obstaculo abaixo deve bloquear a Areia.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 19)) == -1, "A Areia nao deve atravessar um bloco para entrar numa cavidade abaixo dele.")


func _teste_peca_comum():
	_fixar(Vector2i(3, 17))
	_ativar(Vector2i(4, 16), PECA_L)
	tabuleiro.travar_peca()
	for deslocamento in PECA_L.angulo_0:
		_verificar(tabuleiro.blocos_fixados.has(Vector2i(4, 16) + deslocamento), "O L comum deve permanecer inteiro sobre o apoio.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 20)) == -1, "Pecas comuns nao ganham a queda individual.")


func _teste_gravidade_e_delay():
	_fixar(Vector2i(5, 12))
	_ativar(Vector2i(4, 2))
	tabuleiro.etapas_queda = tabuleiro.total_etapas
	tabuleiro._process(1.0 / 60.0)
	_verificar(tabuleiro.pos_atual.y == 3, "Antes de travar, a gravidade deve mover a Areia inteira.")
	tabuleiro.cair_imediatamente(false)
	_verificar(tabuleiro.pos_atual.y == 11 and jogo.pecas_posicionadas == 0, "Hard drop deve parar no apoio e manter o delay existente.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(3, 20)) == -1, "Os graos nao devem se separar antes do travamento.")
	tabuleiro.etapas_fixacao = tabuleiro.total_etapas_fixacao
	tabuleiro._process(1.0 / 60.0)
	_verificar_posicoes([Vector2i(3, 20), Vector2i(4, 20), Vector2i(5, 11), Vector2i(5, 10)])
	_contexto()


func _teste_hold_e_rotacao():
	_ativar(Vector2i(4, 2))
	tabuleiro.rotacionar_peca(1)
	_verificar(tabuleiro.indice_rotacao == 1 and tabuleiro.blocos_fixados.is_empty(), "A Areia deve girar normalmente, sem se fixar.")
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca_armazenada.cai_em_blocos_ao_travar and jogo.pecas_posicionadas == 0, "Hold deve guardar o efeito sem assentar a Areia.")
	tabuleiro.pode_armazenar = true
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca.cai_em_blocos_ao_travar and tabuleiro.peca.id_fonte_tiles == 2, "A Areia deve voltar do hold com efeito e textura.")
	tabuleiro.cair_imediatamente(true)
	_verificar(_posicoes_areia().size() == 4 and jogo.pecas_posicionadas == 1, "O travamento imediato da Areia armazenada deve conservar os quatro graos.")


func _teste_bonus_hard_drop():
	jogo.adquirir_reliquia(ReliquiaBonusHardDrop.new())
	_fixar(Vector2i(5, 12))
	_ativar(Vector2i(4, 2))
	tabuleiro.cair_imediatamente(true)
	var contexto := _contexto()
	_verificar(contexto.casas_hard_drop == 9, "A queda individual extra nao deve inflar a distancia de hard drop da peca.")
	for posicao in _posicoes_areia():
		_verificar(tabuleiro.blocos_fixados[posicao].pontos == 19, "O bonus da reliquia deve acompanhar tanto os graos que caem quanto os apoiados.")


func _teste_dados_e_bonus():
	var recurso := AREIA.criar_copia()
	recurso.pontos_extras = 7
	recurso.multiplicador_extra = 0.5
	recurso.resistencia_ao_peso_por_bloco = 10
	tabuleiro.peca_travando.connect(func(travamento: TravamentoDePeca):
		travamento.adicionar_pontos_por_bloco(3)
		travamento.adicionar_multiplicador_por_bloco(0.25))
	_ativar(Vector2i(4, 10), recurso)
	tabuleiro.travar_peca()
	for posicao in _posicoes_areia():
		var bloco: BlocoFixado = tabuleiro.blocos_fixados[posicao]
		_verificar(bloco.pontos == 20 and bloco.multiplicador == 1.75 and bloco.resistencia == 10, "A movimentacao individual deve preservar todos os dados do bloco.")
	for deslocamento in recurso.angulo_0:
		_verificar(not tabuleiro.blocos_fixados.has(Vector2i(4, 10) + deslocamento), "Os metadados das posicoes antigas devem ser removidos.")


func _teste_linha():
	_testar_linhas(1)


func _teste_duas_linhas():
	_testar_linhas(2)


func _testar_linhas(quantidade: int):
	for y in range(21 - quantidade, 21):
		for x in range(1, 11):
			if x != 5:
				_fixar(Vector2i(x, y))
	_fixar(Vector2i(3, 17))
	_fixar(Vector2i(4, 17))
	_ativar(Vector2i(4, 16))
	tabuleiro.travar_peca()
	var contexto := _contexto()
	_verificar(contexto.linhas_destruidas == quantidade and jogo.pontuacao == quantidade * 100, "As linhas preenchidas pela Areia devem limpar e pontuar somente depois de todos os graos assentarem.")
	_verificar(_posicoes_areia().size() == 4 - quantidade, "Somente os graos das linhas completas devem desaparecer.")
	_verificar(tabuleiro.blocos_fixados.has(Vector2i(3, 16 + quantidade)), "Os dados dos graos apoiados devem acompanhar o deslocamento das linhas.")
	_verificar(jogo.linhas_pendentes.is_empty(), "A pontuacao deve ser consumida uma unica vez.")


func _teste_bordas():
	var borda: Dictionary[Vector2i, Vector2i] = {}
	for posicao in tabuleiro.get_used_cells():
		if not tabuleiro.posicao_esta_no_tabuleiro(posicao):
			borda[posicao] = tabuleiro.get_cell_atlas_coords(posicao)
	_ativar(Vector2i(2, 10), _versao_areia(PECA_O))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(1, 20), Vector2i(2, 20), Vector2i(1, 19), Vector2i(2, 19)])
	for posicao in borda:
		_verificar(tabuleiro.get_cell_atlas_coords(posicao) == borda[posicao], "A Areia deve preservar todas as paredes.")
	tabuleiro.limpar_peca()
	tabuleiro.limpar_grid()
	tabuleiro.peca_ativa = []
	tabuleiro.erase_cell(Vector2i(9, 21))
	tabuleiro.erase_cell(Vector2i(10, 21))
	_ativar(Vector2i(10, 10), _versao_areia(PECA_O))
	tabuleiro.travar_peca()
	_verificar_posicoes([Vector2i(9, 20), Vector2i(10, 20), Vector2i(9, 19), Vector2i(10, 19)])


func _teste_formatos():
	for formato in FORMATOS:
		for rotacao in range(4):
			tabuleiro.limpar_peca()
			tabuleiro.limpar_grid()
			tabuleiro.peca_ativa = []
			contextos.clear()
			for x in range(1, 11):
				_fixar(Vector2i(x, 14 + x % 4))
			var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
			_ativar(Vector2i(5, 10), _versao_areia(formato), rotacao)
			tabuleiro.cair_imediatamente(true)
			var posicoes := _posicoes_areia()
			_verificar(posicoes.size() == 4, "O formato %s na rotacao %d deve conservar quatro graos." % [formato.tipo_peca, rotacao])
			_verificar_posicoes(posicoes)
			_preservar_originais(originais)
			_contexto()


func _teste_substituicao():
	_ativar(Vector2i(4, 10), PECA_L)
	_verificar(tabuleiro.substituir_peca_atual(AREIA) and tabuleiro.peca.cai_em_blocos_ao_travar, "A substituicao por reliquia deve ativar o efeito da Areia.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(4, 10)) == 2, "A substituicao tambem deve atualizar a textura.")
	_verificar(tabuleiro.substituir_peca_atual(PECA_L) and not tabuleiro.peca.cai_em_blocos_ao_travar, "Trocar de volta por L comum deve remover o efeito.")
	_verificar(tabuleiro.blocos_fixados.is_empty(), "Substituir a peca ativa nao deve assentar graos prematuramente.")


func _teste_bolsa_e_sprite():
	var quantidade: int = 0
	for recurso in jogo.bolsa_de_pecas:
		if recurso.cai_em_blocos_ao_travar:
			quantidade += 1
	_verificar(quantidade == 1, "O saco inicial deve conter exatamente uma Areia.")
	var copia := AREIA.criar_copia()
	_verificar(copia != AREIA and copia.cai_em_blocos_ao_travar and copia.obter_tipo_tabela_srs() == "PADRAO", "Copias devem preservar o efeito e a tabela SRS do L.")
	var fonte: TileSetAtlasSource = tabuleiro.tile_set.get_source(2)
	var fonte_hud: TileSetAtlasSource = jogo.hud.tile_map_proxima_peca.tile_set.get_source(2)
	_verificar(fonte != fonte_hud and fonte.texture.get_image().get_size() == Vector2i(32, 32), "A grade e o HUD devem ter fontes independentes da textura de 32x32.")
	jogo.hud.atualizar_proxima_peca(AREIA, AREIA.coords_no_atlas)
	jogo.hud.atualizar_peca_armazenada(AREIA, AREIA.coords_no_atlas)
	_verificar(jogo.hud.tile_map_proxima_peca.get_cell_source_id(Vector2i.ZERO) == 2 and jogo.hud.tile_map_peca_armazenada.get_cell_source_id(Vector2i.ZERO) == 2, "Next e Hold devem usar o visual da Areia.")


func _teste_limite_da_fase():
	jogo.regras_atuais.pecas_maximas = 1
	_ativar(Vector2i(4, 10))
	var turno: int = tabuleiro.turno_atual
	tabuleiro.travar_peca()
	_verificar(_posicoes_areia().size() == 4 and jogo.pecas_posicionadas == 1, "Uma Areia consome uma peca, nao uma por grao.")
	_verificar(not tabuleiro.jogo_rodando and tabuleiro.turno_atual == turno, "O limite da fase deve ser respeitado depois do assentamento.")
	_contexto()


func _teste_fantasma_com_areia():
	for posicao in [Vector2i(4, 9), Vector2i(5, 9), Vector2i(4, 10)]:
		_fixar(posicao)
	var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
	var recurso := _versao_areia(PECA_O)
	recurso.atravessa_blocos = true
	_ativar(Vector2i(5, 10), recurso)
	tabuleiro.materializar_fantasma()
	_preservar_originais(originais)
	_verificar_posicoes([Vector2i(5, 20)])
	_verificar(tabuleiro.camada_fantasma.get_used_cells().is_empty(), "Mesmo combinando flags, somente os graos novos podem cair.")
	_contexto()


func _teste_bomba_apos_areia():
	_ativar(Vector2i(4, 10))
	tabuleiro.travar_peca()
	_ativar(Vector2i(4, 19), BOMBA)
	tabuleiro.travar_peca()
	_verificar(_posicoes_areia().is_empty() and jogo.pontuacao == 40, "Uma Bomba deve destruir e pontuar os quatro graos com seus dados nas posicoes finais.")
	_verificar(contextos.size() == 2 and contextos.back().linhas_destruidas == 0, "A explosao dos graos continua contando como linhas parciais.")
