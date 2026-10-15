extends SceneTree

const PECA_I: Peca = preload("res://entities/pecas/peca_i.tres")
const PECA_O: Peca = preload("res://entities/pecas/peca_o.tres")
const PECA_T: Peca = preload("res://entities/pecas/peca_t.tres")
const PECA_L: Peca = preload("res://entities/pecas/peca_l.tres")
const BOMBA: Peca = preload("res://entities/pecas/peca_bomba.tres")
const FANTASMA: Peca = preload("res://entities/pecas/peca_fantasma_t.tres")

var jogo: Node
var quantidade_base: int
var falhas: Array[String] = []


func _initialize():
	_executar.call_deferred()


func _executar():
	var testes: Array[Callable] = [
		_teste_grupos_nao_configurados, _teste_uma_de_cada_grupo,
		_teste_sorteio_limitado_aos_grupos, _teste_listas_vazias_e_nulos,
		_teste_copias_independentes, _teste_funcao_atualiza_saco,
		_teste_extra_na_primeira_vitoria, _teste_extra_ausente,
		_teste_sem_extra_na_derrota, _teste_reinicio,
		_teste_primeira_fase_unica, _teste_iniciar_fase_nao_sorteia_novamente,
		_teste_evento_de_vitoria_recebe_bolsa_atualizada,
	]
	for teste in testes:
		_preparar_jogo()
		teste.call()
		jogo.free()
	if falhas.is_empty():
		print("SACO: %d testes passaram (3 grupos, copias, reinicio e peca extra apos a primeira fase)." % testes.size())
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)


func _preparar_jogo():
	jogo = load("res://core/tetris.tscn").instantiate()
	jogo.reliquias_iniciais.clear()
	jogo.som_completar_linha.clear()
	jogo.som_passar_fase.clear()
	jogo.pecas_sorteaveis.clear()
	jogo.pecas_sorteaveis_2.clear()
	jogo.pecas_sorteaveis_3.clear()
	jogo.peca_extra = null
	root.add_child(jogo)
	jogo.set_process(false)
	jogo.tabuleiro.set_process(false)
	quantidade_base = jogo.tabuleiro.pecas.size()


func _configurar_tres_grupos():
	jogo.pecas_sorteaveis.assign([PECA_O])
	jogo.pecas_sorteaveis_2.assign([PECA_T])
	jogo.pecas_sorteaveis_3.assign([PECA_L])


func _verificar(condicao: bool, mensagem: String):
	if not condicao:
		falhas.append(mensagem)


func _verificar_tamanho(esperado: int):
	_verificar(jogo.bolsa_de_pecas.size() == esperado, "A bolsa deve conter %d pecas, sem perdas ou duplicacoes." % esperado)
	_verificar(jogo.pecas_do_saco_atual.size() == esperado, "O saco modificado deve acompanhar a bolsa.")
	_verificar(jogo.tabuleiro.pecas_do_saco.size() == esperado, "O tabuleiro deve receber as pecas adicionadas.")


func _teste_grupos_nao_configurados():
	_verificar_tamanho(quantidade_base)
	for i in range(quantidade_base):
		_verificar(jogo.bolsa_de_pecas[i] != jogo.tabuleiro.pecas[i], "As pecas iniciais devem continuar sendo copias independentes.")


func _teste_uma_de_cada_grupo():
	_configurar_tres_grupos()
	jogo.peca_extra = BOMBA
	jogo.iniciar_novo_jogo()
	_verificar_tamanho(quantidade_base + 3)
	for i in range(3):
		var esperada: Peca = [PECA_O, PECA_T, PECA_L][i]
		var sorteada: Peca = jogo.bolsa_de_pecas[quantidade_base + i]
		_verificar(sorteada.tipo_peca == esperada.tipo_peca and sorteada != esperada, "Cada grupo deve adicionar uma copia de sua candidata.")
	_verificar(jogo.tabuleiro.saco_atual.size() == quantidade_base + 1, "As tres pecas devem entrar no saco antes do sorteio da atual e da proxima.")


func _teste_sorteio_limitado_aos_grupos():
	jogo.pecas_sorteaveis.assign([PECA_I, PECA_O])
	jogo.pecas_sorteaveis_2.assign([PECA_T, PECA_L])
	jogo.pecas_sorteaveis_3.assign([BOMBA, FANTASMA])
	var grupos: Array = [jogo.pecas_sorteaveis, jogo.pecas_sorteaveis_2, jogo.pecas_sorteaveis_3]
	var vistos: Array[Dictionary] = [{}, {}, {}]
	seed(4321)
	for tentativa in range(64):
		jogo.iniciar_novo_jogo()
		_verificar_tamanho(quantidade_base + 3)
		for i in range(3):
			var sorteada: Peca = jogo.bolsa_de_pecas[quantidade_base + i]
			var nomes: Array[String] = []
			for candidata in grupos[i]:
				nomes.append(candidata.nome)
			_verificar(sorteada.nome in nomes, "Uma peca sorteada deve pertencer ao seu respectivo export.")
			vistos[i][sorteada.nome] = true
	for grupo_visto in vistos:
		_verificar(grupo_visto.size() == 2, "O sorteio deve permitir selecionar as diferentes candidatas de cada grupo.")


func _teste_listas_vazias_e_nulos():
	jogo.pecas_sorteaveis.assign([null, PECA_O])
	jogo.pecas_sorteaveis_3.assign([null, null])
	jogo.iniciar_novo_jogo()
	_verificar_tamanho(quantidade_base + 1)
	_verificar(jogo.bolsa_de_pecas.back().tipo_peca == "O", "Itens nulos devem ser ignorados sem descartar candidatas validas.")
	for peca in jogo.bolsa_de_pecas:
		_verificar(peca != null, "A bolsa nao deve receber recursos nulos.")


func _teste_copias_independentes():
	var original: Peca = FANTASMA.criar_copia()
	original.pontos_extras = 7
	original.multiplicador_extra = 0.5
	jogo.pecas_sorteaveis.assign([original])
	jogo.pecas_sorteaveis_2.assign([original])
	jogo.pecas_sorteaveis_3.assign([original])
	jogo.iniciar_novo_jogo()
	_verificar_tamanho(quantidade_base + 3)
	var primeira: Peca = jogo.bolsa_de_pecas[quantidade_base]
	var segunda: Peca = jogo.bolsa_de_pecas[quantidade_base + 1]
	var terceira: Peca = jogo.bolsa_de_pecas[quantidade_base + 2]
	_verificar(primeira != original and primeira != segunda and segunda != terceira and primeira != terceira, "Candidatas repetidas devem gerar copias independentes em cada grupo.")
	for copia in [primeira, segunda, terceira]:
		_verificar(copia.atravessa_blocos and copia.pontos_extras == 7 and copia.multiplicador_extra == 0.5, "Copias devem preservar habilidades e bonus do recurso sorteado.")
	primeira.pontos_extras = 99
	_verificar(original.pontos_extras == 7 and segunda.pontos_extras == 7 and terceira.pontos_extras == 7, "Alterar uma copia nao pode modificar o recurso exportado nem outras copias.")


func _teste_funcao_atualiza_saco():
	_configurar_tres_grupos()
	jogo.adicionar_pecas_aleatorias_ao_saco()
	_verificar_tamanho(quantidade_base + 3)
	_verificar(jogo.tabuleiro.pecas.size() == quantidade_base, "Adicionar pecas nao pode modificar os recursos iniciais do tabuleiro.")


func _teste_extra_na_primeira_vitoria():
	_configurar_tres_grupos()
	jogo.peca_extra = BOMBA
	jogo.iniciar_novo_jogo()
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 4)
	var extra: Peca = jogo.bolsa_de_pecas.back()
	_verificar(extra != BOMBA and extra.explode_ao_travar, "A primeira vitoria deve adicionar uma copia da peca extra com seu efeito.")
	_verificar(not jogo.tabuleiro.jogo_rodando, "A peca extra nao deve retomar o jogo durante a recompensa.")
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 4)
	jogo._avancar_para_proxima_fase()
	_verificar(jogo.indice_fase == 1 and jogo.bolsa_de_pecas.back() == extra, "A peca extra deve continuar no saco da segunda fase.")
	_verificar(jogo.tabuleiro.saco_atual.size() == quantidade_base + 2, "A peca extra deve entrar no saco da fase seguinte antes das duas primeiras selecoes.")
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 4)


func _teste_extra_ausente():
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base)
	_verificar(not jogo.tabuleiro.jogo_rodando, "A vitoria deve continuar funcionando quando peca_extra nao estiver configurada.")


func _teste_sem_extra_na_derrota():
	jogo.peca_extra = BOMBA
	jogo._perder_partida()
	_verificar_tamanho(quantidade_base)
	_verificar(jogo.hud.label_perdeu.visible, "A derrota deve continuar exibindo a tela original, sem conceder a peca extra.")


func _teste_reinicio():
	_configurar_tres_grupos()
	jogo.peca_extra = BOMBA
	jogo.iniciar_novo_jogo()
	var anterior: Peca = jogo.bolsa_de_pecas[quantidade_base]
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 4)
	jogo.iniciar_novo_jogo()
	_verificar_tamanho(quantidade_base + 3)
	_verificar(jogo.indice_fase == 0 and jogo.bolsa_de_pecas[quantidade_base] != anterior, "Reiniciar deve zerar a progressao e recriar as pecas sorteadas.")
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 4)


func _teste_primeira_fase_unica():
	var unica_fase: Array[Fase] = [jogo.fases[0]]
	jogo.fases = unica_fase
	jogo.peca_extra = BOMBA
	jogo.iniciar_novo_jogo()
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 1)
	_verificar(jogo.indice_fase == 0, "Uma partida com apenas uma fase deve conceder a peca sem avancar para uma fase inexistente.")


func _teste_iniciar_fase_nao_sorteia_novamente():
	_configurar_tres_grupos()
	jogo.peca_extra = BOMBA
	jogo.iniciar_novo_jogo()
	var primeira: Peca = jogo.bolsa_de_pecas[quantidade_base]
	jogo._iniciar_fase()
	_verificar_tamanho(quantidade_base + 3)
	_verificar(jogo.bolsa_de_pecas[quantidade_base] == primeira, "Reiniciar somente a fase deve preservar as pecas ja sorteadas.")
	jogo._avancar_para_proxima_fase()
	_verificar_tamanho(quantidade_base + 3)
	jogo._concluir_fase()
	_verificar_tamanho(quantidade_base + 3)


func _teste_evento_de_vitoria_recebe_bolsa_atualizada():
	jogo.peca_extra = BOMBA
	var tamanhos: Array[int] = []
	var ao_concluir: Callable = func(_pontuacao: int): tamanhos.append(jogo.bolsa_de_pecas.size())
	var auto_bus: Node = root.get_node("AutoBus")
	auto_bus.fase_concluida.connect(ao_concluir)
	jogo._concluir_fase()
	auto_bus.fase_concluida.disconnect(ao_concluir)
	_verificar(tamanhos.size() == 1 and tamanhos[0] == quantidade_base + 1, "O evento de vitoria deve notificar os outros sistemas depois de inserir a peca extra.")
