extends SceneTree

const FANTASMA: Peca = preload("res://entities/pecas/peca_fantasma.tres")
const PECA_O: Peca = preload("res://entities/pecas/peca_o.tres")
const PECA_I: Peca = preload("res://entities/pecas/peca_i.tres")
const FORMATOS: Array[Peca] = [
	PECA_I, PECA_O, preload("res://entities/pecas/peca_t.tres"),
	preload("res://entities/pecas/peca_l.tres"), preload("res://entities/pecas/peca_j.tres"),
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
		_teste_travessia, _teste_rotacao, _teste_formatos_e_bordas, _teste_spawn,
		_teste_gravidade, _teste_materializacao_parcial, _teste_materializacao_vazia,
		_teste_materializacao_total_e_bonus, _teste_fora_dos_limites, _teste_linha,
		_teste_tecla_f, _teste_tecla_f_normal, _teste_queda_imediata, _teste_materializacao_no_fundo,
		_teste_rotacao_atingindo_fundo, _teste_hold, _teste_substituicao, _teste_bolsa_e_regras,
		_teste_limite_de_pecas, _teste_visual, _teste_reinicio,
		_teste_queda_imediata_direta, _teste_inputs_na_proxima_peca,
		_teste_fundo_parcial_automatico, _teste_fundo_vazio_automatico,
	]
	for teste in testes:
		_preparar_jogo()
		await process_frame
		teste.call()
		jogo.free()
	if falhas.is_empty():
		print("FANTASMA: %d testes passaram (incluindo 7 formatos e 4 rotacoes)." % testes.size())
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


func _versao_fantasma(formato: Peca) -> Peca:
	var copia := formato.criar_copia()
	copia.atravessa_blocos = true
	copia.coords_no_atlas = FANTASMA.coords_no_atlas
	return copia


func _ativar(posicao: Vector2i, recurso: Peca = FANTASMA, rotacao: int = 0):
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
	tabuleiro.resets_fixacao = 0
	tabuleiro.jogo_rodando = true
	tabuleiro.desenhar_peca(tabuleiro.peca_ativa, posicao, recurso.coords_no_atlas)


func _fixar(posicao: Vector2i) -> BlocoFixado:
	tabuleiro.set_cell(posicao, 0, PECA_O.coords_no_atlas)
	var bloco := BlocoFixado.new()
	bloco.tipo_peca = "O"
	bloco.pontos = 23
	bloco.multiplicador = 2.0
	tabuleiro.blocos_fixados[posicao] = bloco
	return bloco


func _contexto() -> ContextoPontuacao:
	_verificar(contextos.size() == 1, "A materializacao deve resolver exatamente uma jogada.")
	return contextos.back() if not contextos.is_empty() else ContextoPontuacao.new()


func _preservado(posicao: Vector2i, original: BlocoFixado):
	_verificar(tabuleiro.get_cell_atlas_coords(posicao) == PECA_O.coords_no_atlas, "O tile original em %s deve sobreviver." % posicao)
	_verificar(tabuleiro.blocos_fixados.get(posicao) == original, "Os dados originais em %s nao podem ser substituidos." % posicao)
	_verificar(original.pontos == 23 and original.multiplicador == 2.0, "Os bonus do bloco original devem ser preservados.")


func _teste_travessia():
	var posicao := Vector2i(5, 10)
	var original := _fixar(posicao)
	_ativar(posicao, _versao_fantasma(PECA_O))
	_verificar(tabuleiro.camada_fantasma.get_used_cells().size() == 4, "A Fantasma deve desenhar quatro celulas na camada separada.")
	tabuleiro.mover_peca(Vector2i.RIGHT)
	tabuleiro.mover_peca(Vector2i.LEFT)
	tabuleiro.mover_peca(Vector2i.DOWN)
	_verificar(tabuleiro.pos_atual == Vector2i(5, 11), "A Fantasma deve atravessar o bloco fixo.")
	tabuleiro.limpar_peca()
	_preservado(posicao, original)
	_verificar(tabuleiro.camada_fantasma.get_used_cells().is_empty(), "Limpar a Fantasma deve apagar somente a sobreposicao.")


func _teste_rotacao():
	var originais: Dictionary[Vector2i, BlocoFixado] = {}
	for y in range(8, 13):
		for x in range(3, 8):
			var posicao := Vector2i(x, y)
			originais[posicao] = _fixar(posicao)
	_ativar(Vector2i(5, 10))
	tabuleiro.rotacionar_peca(1)
	_verificar(tabuleiro.indice_rotacao == 1 and tabuleiro.pos_atual == Vector2i(5, 10), "A Fantasma deve girar dentro de blocos sem precisar de deslocamento SRS.")
	tabuleiro.rotacionar_peca(-1)
	_verificar(tabuleiro.indice_rotacao == 0, "A rotacao anti-horaria tambem deve funcionar.")
	for posicao in originais:
		_preservado(posicao, originais[posicao])


func _teste_formatos_e_bordas():
	# Os limites sao geometricos, nao dependem de tiles desenhados como paredes.
	tabuleiro.clear()
	for formato in FORMATOS:
		var fantasma := _versao_fantasma(formato)
		for rotacao in range(4):
			_ativar(Vector2i(5, 10), fantasma, rotacao)
			_verificar(tabuleiro.pode_rotacionar(tabuleiro.peca_ativa, Vector2i.ZERO), "O formato %s deve suportar a rotacao %d." % [formato.tipo_peca, rotacao])
			var direcoes := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			for direcao in direcoes:
				_ativar(Vector2i(5, 10), fantasma, rotacao)
				for tentativa in range(30):
					tabuleiro.mover_peca(direcao)
				_verificar(not tabuleiro.pode_mover(direcao), "A Fantasma %s deve parar no limite %s." % [formato.tipo_peca, direcao])
				for deslocamento in tabuleiro.peca_ativa:
					_verificar(tabuleiro.posicao_esta_no_tabuleiro(tabuleiro.pos_atual + deslocamento), "Nenhuma celula pode atravessar os limites.")
				tabuleiro.rotacionar_peca(1)
				for deslocamento in tabuleiro.peca_ativa:
					_verificar(tabuleiro.posicao_esta_no_tabuleiro(tabuleiro.pos_atual + deslocamento), "SRS tambem deve respeitar as bordas para Fantasmas.")


func _teste_spawn():
	var originais: Dictionary[Vector2i, BlocoFixado] = {}
	for deslocamento in PECA_O.angulo_0:
		var posicao: Vector2i = tabuleiro.pos_inicial + deslocamento
		originais[posicao] = _fixar(posicao)
	_ativar(tabuleiro.pos_inicial, _versao_fantasma(PECA_O))
	_verificar(tabuleiro.pode_criar_peca(), "A Fantasma pode nascer sobre blocos fixos.")
	tabuleiro.criar_peca()
	_verificar(tabuleiro.jogo_rodando, "O spawn da Fantasma nao deve causar derrota por sobreposicao.")
	for posicao in originais:
		_preservado(posicao, originais[posicao])
	tabuleiro.peca = PECA_O.criar_copia()
	_verificar(not tabuleiro.pode_criar_peca(), "Uma peca comum continua bloqueada no spawn ocupado.")


func _teste_gravidade():
	var original := _fixar(Vector2i(5, 11))
	_ativar(Vector2i(5, 10), _versao_fantasma(PECA_O))
	tabuleiro.etapas_queda = tabuleiro.total_etapas
	tabuleiro.etapas_fixacao = tabuleiro.total_etapas_fixacao
	tabuleiro._process(1.0 / 60.0)
	_verificar(tabuleiro.pos_atual == Vector2i(5, 11) and jogo.pecas_posicionadas == 0, "A gravidade deve atravessar a pilha sem travar.")
	_verificar(contextos.is_empty(), "Tocar blocos fixos nao materializa a Fantasma.")
	_preservado(Vector2i(5, 11), original)
	_ativar(Vector2i(5, 19), _versao_fantasma(PECA_O))
	tabuleiro.etapas_queda = tabuleiro.total_etapas
	tabuleiro._process(1.0 / 60.0)
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.blocos_fixados.has(Vector2i(5, 20)), "A gravidade deve materializar a Fantasma no mesmo quadro em que chega ao fundo.")
	_verificar(tabuleiro.pos_atual == tabuleiro.pos_inicial and tabuleiro.etapas_queda == 0.0, "A proxima peca nao deve receber a gravidade do turno anterior.")
	_contexto()


func _teste_materializacao_parcial():
	var originais: Dictionary[Vector2i, BlocoFixado] = {}
	for posicao in [Vector2i(4, 9), Vector2i(5, 9), Vector2i(4, 10)]:
		originais[posicao] = _fixar(posicao)
	_ativar(Vector2i(5, 10), _versao_fantasma(PECA_O))
	tabuleiro.materializar_fantasma()
	for posicao in originais:
		_preservado(posicao, originais[posicao])
	_verificar(tabuleiro.blocos_fixados.size() == 4 and tabuleiro.blocos_fixados.has(Vector2i(5, 10)), "No exemplo ##/#., somente a celula vazia deve ser materializada.")
	_verificar(tabuleiro.blocos_fixados[Vector2i(5, 10)].pontos == 10, "O bloco materializado deve receber os valores da Fantasma.")
	_verificar(jogo.pecas_posicionadas == 1 and not tabuleiro.peca.atravessa_blocos, "Materializar deve encerrar o turno e criar a proxima peca.")
	_verificar(tabuleiro.camada_fantasma.get_used_cells().is_empty() and _contexto().linhas.is_empty(), "A sobreposicao deve desaparecer sem pontuar celulas descartadas.")


func _teste_materializacao_vazia():
	for x in range(1, 11):
		_fixar(Vector2i(x, 12))
	for deslocamento in PECA_O.angulo_0:
		_fixar(Vector2i(5, 10) + deslocamento)
	var fragil := _fixar(Vector2i(8, 15))
	fragil.resistencia = 1
	_fixar(Vector2i(8, 14))
	var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
	_ativar(Vector2i(5, 10), _versao_fantasma(PECA_O))
	tabuleiro.materializar_fantasma()
	_verificar(tabuleiro.blocos_fixados == originais and fragil.pressao == 0, "Sem celulas livres, o tabuleiro deve ficar intacto, incluindo linhas e vidro.")
	_verificar(jogo.pontuacao == 0 and _contexto().linhas.is_empty(), "Descartar toda a Fantasma nao limpa linhas nem concede pontos base.")
	_verificar(jogo.pecas_posicionadas == 1, "Mesmo uma materializacao vazia consome o turno.")


func _teste_materializacao_total_e_bonus():
	var fantasma := _versao_fantasma(PECA_O)
	fantasma.pontos_extras = 7
	fantasma.multiplicador_extra = 0.5
	tabuleiro.peca_travando.connect(func(travamento: TravamentoDePeca):
		travamento.adicionar_pontos_por_bloco(3)
		travamento.adicionar_multiplicador_por_bloco(0.25))
	_ativar(Vector2i(5, 10), fantasma)
	tabuleiro.materializar_fantasma()
	_verificar(tabuleiro.blocos_fixados.size() == 4, "Em uma area vazia, as quatro celulas devem se fixar.")
	for deslocamento in fantasma.angulo_0:
		var bloco: BlocoFixado = tabuleiro.blocos_fixados.get(Vector2i(5, 10) + deslocamento)
		_verificar(bloco != null and bloco.pontos == 20 and bloco.multiplicador == 1.75, "A Fantasma materializada deve preservar buffs e bonus do travamento.")
	_contexto()


func _teste_fora_dos_limites():
	var borda: Dictionary[Vector2i, Vector2i] = {}
	for posicao in tabuleiro.get_used_cells():
		if not tabuleiro.posicao_esta_no_tabuleiro(posicao):
			borda[posicao] = tabuleiro.get_cell_atlas_coords(posicao)
	_ativar(Vector2i(1, 1), _versao_fantasma(PECA_O))
	tabuleiro.materializar_fantasma()
	_verificar(tabuleiro.blocos_fixados.size() == 1 and tabuleiro.blocos_fixados.has(Vector2i(1, 1)), "Celulas invalidas sao descartadas individualmente.")
	for posicao in borda:
		_verificar(tabuleiro.get_cell_atlas_coords(posicao) == borda[posicao], "A materializacao nao pode escrever sobre a borda.")
	_ativar(Vector2i(-5, -5), _versao_fantasma(PECA_O))
	tabuleiro.materializar_fantasma()
	_verificar(tabuleiro.blocos_fixados.size() == 1 and jogo.pecas_posicionadas == 2, "Uma Fantasma totalmente fora da grade apenas encerra o turno.")


func _teste_linha():
	for x in range(1, 11):
		if x != 5:
			_fixar(Vector2i(x, 20))
	_ativar(Vector2i(5, 20), _versao_fantasma(PECA_O))
	tabuleiro.materializar_fantasma()
	var contexto := _contexto()
	_verificar(contexto.linhas_destruidas == 1 and contexto.linhas[0].blocos.size() == 10, "A materializacao parcial deve completar e pontuar linhas normalmente.")
	_verificar(jogo.pontuacao > 0 and jogo.linhas_pendentes.is_empty(), "O GameManager deve consumir a pontuacao da linha sem duplicacao.")
	_verificar(tabuleiro.blocos_fixados.size() == 2 and tabuleiro.blocos_fixados.has(Vector2i(5, 20)), "As celulas acima da linha limpa devem descer com os metadados.")


func _teste_tecla_f():
	_ativar(Vector2i(5, 10))
	var evento := InputEventKey.new()
	evento.physical_keycode = KEY_F
	evento.pressed = true
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	_verificar(Input.is_action_just_pressed("materializar_fantasma"), "A tecla fisica F deve acionar a materializacao.")
	tabuleiro._process(0.1)
	var liberacao := evento.duplicate() as InputEventKey
	liberacao.pressed = false
	Input.parse_input_event(liberacao)
	Input.flush_buffered_events()
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.pos_atual == tabuleiro.pos_inicial, "F deve materializar uma vez sem mover a proxima peca no mesmo quadro.")
	_verificar(tabuleiro.etapas_queda == 0.0, "O turno novo nao deve receber gravidade do quadro anterior.")
	_contexto()


func _teste_tecla_f_normal():
	_ativar(Vector2i(5, 10), PECA_O)
	Input.action_press("materializar_fantasma")
	tabuleiro._process(0.0)
	Input.action_release("materializar_fantasma")
	_verificar(jogo.pecas_posicionadas == 0 and tabuleiro.blocos_fixados.is_empty(), "F nao deve fixar uma peca comum.")


func _teste_queda_imediata():
	var original := _fixar(Vector2i(5, 19))
	_ativar(Vector2i(5, 2), _versao_fantasma(PECA_O))
	Input.action_press("cair_imediatamente")
	tabuleiro._process(0.0)
	Input.action_release("cair_imediatamente")
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.pos_atual == tabuleiro.pos_inicial, "Space/E deve atravessar a pilha e materializar no fundo sem F.")
	_verificar(_contexto().casas_hard_drop == 18, "A distancia de hard drop deve ser registrada antes de criar a proxima peca.")
	_verificar(tabuleiro.blocos_fixados.size() == 4, "Somente as tres celulas livres devem ser acrescentadas ao bloco existente.")
	_preservado(Vector2i(5, 19), original)


func _teste_materializacao_no_fundo():
	_ativar(Vector2i(5, 20), _versao_fantasma(PECA_O))
	tabuleiro._process(0.0)
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.blocos_fixados.size() == 4, "A Fantasma no fundo deve materializar imediatamente, sem F ou espera.")
	_verificar(tabuleiro.camada_fantasma.get_used_cells().is_empty(), "A camada da Fantasma deve sumir depois de materializar.")
	_contexto()


func _teste_rotacao_atingindo_fundo():
	_ativar(Vector2i(5, 19))
	Input.action_press("rotacionar_sentido_horario")
	tabuleiro._process(0.0)
	Input.action_release("rotacionar_sentido_horario")
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.blocos_fixados.has(Vector2i(5, 20)), "Uma rotacao que toque o fundo deve materializar no mesmo quadro.")
	_contexto()


func _teste_hold():
	var original := _fixar(Vector2i(5, 10))
	_ativar(Vector2i(5, 10))
	tabuleiro.armazenar_peca_atual()
	_preservado(Vector2i(5, 10), original)
	_verificar(tabuleiro.peca_armazenada.atravessa_blocos and jogo.pecas_posicionadas == 0, "Hold deve preservar o efeito sem materializar nem consumir uma peca.")
	tabuleiro.pode_armazenar = true
	tabuleiro.armazenar_peca_atual()
	_verificar(tabuleiro.peca.atravessa_blocos and tabuleiro.pos_atual == tabuleiro.pos_inicial, "A Fantasma deve voltar do hold com o efeito ativo.")
	_verificar(tabuleiro.camada_fantasma.get_used_cells().size() == 4, "O retorno do hold deve redesenhar a Fantasma sem materializar no topo.")


func _teste_substituicao():
	for y in range(8, 12):
		for x in range(1, 11):
			_fixar(Vector2i(x, y))
	_ativar(Vector2i(5, 10))
	_verificar(not tabuleiro.substituir_peca_atual(PECA_O), "Uma reliquia nao pode trocar Fantasma por peca comum dentro de blocos fixos.")
	_verificar(tabuleiro.peca.atravessa_blocos and tabuleiro.blocos_fixados.size() == 40, "Uma troca impossivel nao altera a Fantasma nem os blocos existentes.")
	tabuleiro.limpar_peca()
	tabuleiro.limpar_grid()
	tabuleiro.peca_ativa = []
	_ativar(Vector2i(5, 10), PECA_O)
	_verificar(tabuleiro.substituir_peca_atual(FANTASMA), "Uma peca comum pode ser substituida por Fantasma.")
	_verificar(tabuleiro.get_cell_source_id(Vector2i(5, 10)) == -1 and tabuleiro.camada_fantasma.get_used_cells().size() == 4, "A troca deve migrar o desenho da grade para a camada transparente.")
	_verificar(tabuleiro.substituir_peca_atual(PECA_O) and tabuleiro.camada_fantasma.get_used_cells().is_empty(), "Trocar de volta em area livre deve remover a sobreposicao.")


func _teste_bolsa_e_regras():
	var quantidade: int = 0
	for recurso in jogo.bolsa_de_pecas:
		if recurso.atravessa_blocos:
			quantidade += 1
	_verificar(quantidade == 1, "A bolsa inicial deve conter uma Fantasma.")
	var copia := FANTASMA.criar_copia()
	_verificar(copia != FANTASMA and copia.atravessa_blocos and copia.tipo_peca == "T", "A Fantasma inicial deve ser uma copia independente no formato T.")
	var fase: Fase = jogo.fase.duplicate()
	fase.total_etapas_fixacao = 100000.0
	var regras := RegrasJogo.criar_a_partir_da_fase(fase, fase.velocidade_inicial)
	tabuleiro.aplicar_regras(regras)
	_ativar(Vector2i(5, 20))
	tabuleiro._process(0.0)
	_verificar(jogo.pecas_posicionadas == 1, "O delay de fixacao das pecas comuns nao deve atrasar a Fantasma no fundo.")


func _teste_limite_de_pecas():
	jogo.regras_atuais.pecas_maximas = 1
	for deslocamento in PECA_O.angulo_0:
		_fixar(Vector2i(5, 20) + deslocamento)
	_ativar(Vector2i(5, 20), _versao_fantasma(PECA_O))
	var turno: int = tabuleiro.turno_atual
	tabuleiro._process(0.0)
	_verificar(jogo.pecas_posicionadas == 1 and not tabuleiro.jogo_rodando, "Uma materializacao vazia deve respeitar o limite de pecas da fase.")
	_verificar(tabuleiro.turno_atual == turno and tabuleiro.camada_fantasma.get_used_cells().is_empty(), "O fim da partida nao deve sortear outra peca nem deixar a Fantasma desenhada.")
	_contexto()


func _teste_visual():
	_ativar(Vector2i(5, 10))
	_verificar(tabuleiro.camada_fantasma.modulate.a > 0.0 and tabuleiro.camada_fantasma.modulate.a < 1.0, "A Fantasma ativa deve ser translucida.")
	jogo.hud.atualizar_proxima_peca(FANTASMA, FANTASMA.coords_no_atlas)
	jogo.hud.atualizar_peca_armazenada(FANTASMA, FANTASMA.coords_no_atlas)
	_verificar(jogo.hud.tile_map_proxima_peca.modulate.a < 1.0 and jogo.hud.tile_map_peca_armazenada.modulate.a < 1.0, "Next e Hold devem manter a aparencia Fantasma.")
	jogo.hud.atualizar_proxima_peca(PECA_O, PECA_O.coords_no_atlas)
	jogo.hud.atualizar_peca_armazenada(PECA_O, PECA_O.coords_no_atlas)
	_verificar(jogo.hud.tile_map_proxima_peca.modulate == Color.WHITE and jogo.hud.tile_map_peca_armazenada.modulate == Color.WHITE, "Pecas comuns nao devem herdar a transparencia da Fantasma.")


func _teste_reinicio():
	_ativar(Vector2i(5, 10), _versao_fantasma(PECA_O))
	jogo.iniciar_novo_jogo()
	_verificar(jogo.pecas_posicionadas == 0, "Reiniciar nao deve materializar a Fantasma que estava no ar.")
	for posicao in tabuleiro.camada_fantasma.get_used_cells():
		_verificar(posicao.y <= 3, "O reinicio nao deve deixar celulas da Fantasma anterior no tabuleiro.")


func _teste_queda_imediata_direta():
	for posicionar in [false, true]:
		tabuleiro.limpar_peca()
		tabuleiro.limpar_grid()
		tabuleiro.peca_ativa = []
		contextos.clear()
		var antes: int = jogo.pecas_posicionadas
		_ativar(Vector2i(5, 2), _versao_fantasma(PECA_O))
		tabuleiro.cair_imediatamente(posicionar)
		_verificar(jogo.pecas_posicionadas == antes + 1 and tabuleiro.blocos_fixados.size() == 4, "Ambos os tipos de hard drop devem materializar uma unica Fantasma.")
		_verificar(_contexto().casas_hard_drop == 18, "O hard drop direto deve preservar a distancia total.")
		_verificar(tabuleiro.pos_atual == tabuleiro.pos_inicial, "A funcao de hard drop nao pode continuar descendo a proxima peca.")


func _teste_inputs_na_proxima_peca():
	_ativar(Vector2i(5, 2))
	var proxima: Peca = tabuleiro.prox_peca
	var acoes := ["cair_imediatamente", "rotacionar_sentido_horario", "armazenar_peca"]
	for acao in acoes:
		Input.action_press(acao)
	tabuleiro._process(0.1)
	for acao in acoes:
		Input.action_release(acao)
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.peca == proxima, "Inputs simultaneos ao hard drop nao podem trocar a proxima peca.")
	_verificar(tabuleiro.indice_rotacao == 0 and tabuleiro.peca_armazenada == null, "A proxima peca nao deve girar nem entrar no hold no quadro anterior.")
	_verificar(tabuleiro.etapas_queda == 0.0 and tabuleiro.pos_atual == tabuleiro.pos_inicial, "A proxima peca nao deve receber movimento ou gravidade depois da materializacao.")
	_contexto()


func _teste_fundo_parcial_automatico():
	var originais: Dictionary[Vector2i, BlocoFixado] = {}
	for posicao in [Vector2i(4, 19), Vector2i(5, 19), Vector2i(4, 20)]:
		originais[posicao] = _fixar(posicao)
	_ativar(Vector2i(5, 20), _versao_fantasma(PECA_O))
	tabuleiro._process(0.0)
	for posicao in originais:
		_preservado(posicao, originais[posicao])
	_verificar(tabuleiro.blocos_fixados.size() == 4 and tabuleiro.blocos_fixados[Vector2i(5, 20)].pontos == 10, "Materializar automaticamente deve aproveitar somente a celula livre.")
	_verificar(jogo.pecas_posicionadas == 1, "A materializacao parcial automatica encerra um turno.")
	_contexto()


func _teste_fundo_vazio_automatico():
	for x in range(1, 11):
		_fixar(Vector2i(x, 20))
	_fixar(Vector2i(4, 19))
	_fixar(Vector2i(5, 19))
	var originais: Dictionary = tabuleiro.blocos_fixados.duplicate()
	_ativar(Vector2i(5, 20), _versao_fantasma(PECA_O))
	tabuleiro._process(0.0)
	_verificar(tabuleiro.blocos_fixados == originais and jogo.pontuacao == 0, "Uma Fantasma sem celulas livres deve desaparecer sem alterar o tabuleiro, mesmo automaticamente.")
	_verificar(jogo.pecas_posicionadas == 1 and tabuleiro.jogo_rodando, "Uma materializacao vazia no fundo deve continuar para a proxima peca.")
	_verificar(_contexto().linhas.is_empty(), "Uma materializacao vazia nao deve limpar linhas que ja existiam.")
