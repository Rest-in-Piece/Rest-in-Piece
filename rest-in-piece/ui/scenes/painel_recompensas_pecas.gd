

# tela de recompensa de peças: N menus (páginas) com troca animada, e um Confirmar que
# só habilita quando todos os menus têm escolha (peça ou pular). Não sabe o que a escolha
# faz: só entrega as peças confirmadas.

class_name PainelRecompensasPecas
extends Control

signal confirmado(pecas_escolhidas: Array[Peca])

const DURACAO_ENTRADA: float = 0.4
const DURACAO_SAIDA: float = 0.25
const DURACAO_TROCA: float = 0.35
const ESCALA_INICIAL: Vector2 = Vector2(0.85, 0.85)

@onready var area_paginas: Control = %AreaPaginas
@onready var label_titulo: Label = %LabelTitulo
@onready var botao_anterior: Button = %BotaoAnterior
@onready var botao_proximo: Button = %BotaoProximo
@onready var botao_confirmar: Button = %BotaoConfirmar

var paginas: Array[PaginaRecompensaPecas] = []
var indice_atual: int = 0
var _trocando: bool = false


func _ready() -> void:
	for filho in area_paginas.get_children():
		var pagina := filho as PaginaRecompensaPecas
		if pagina == null:
			continue
		paginas.append(pagina)
		pagina.selecao_alterada.connect(_atualizar_botoes)
	
	botao_anterior.pressed.connect(_navegar.bind(-1))
	botao_proximo.pressed.connect(_navegar.bind(1))
	botao_confirmar.pressed.connect(_on_confirmar_pressionado)
	hide()


# ofertas[i] = peças do menu i
func exibir(ofertas: Array[Array], tile_set: TileSet) -> void:
	indice_atual = 0
	_trocando = false
	for i in range(paginas.size()):
		paginas[i].position.x = 0.0
		paginas[i].visible = (i == 0)
		paginas[i].exibir(ofertas[i] if i < ofertas.size() else [], tile_set)
	_atualizar_botoes()
	
	modulate.a = 0.0
	scale = ESCALA_INICIAL
	show()
	pivot_offset = size / 2.0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, DURACAO_ENTRADA)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, DURACAO_ENTRADA) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	for pagina in paginas:
		pagina.habilitar()


func ocultar_com_animacao() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURACAO_SAIDA)
	await tween.finished
	hide()


func esconder() -> void:
	hide()


func _navegar(passo: int) -> void:
	var novo_indice: int = indice_atual + passo
	if _trocando or novo_indice < 0 or novo_indice >= paginas.size():
		return
	_trocando = true
	
	var saindo: PaginaRecompensaPecas = paginas[indice_atual]
	var entrando: PaginaRecompensaPecas = paginas[novo_indice]
	# avançar: a página atual sai pela esquerda e a nova entra pela direita (voltar inverte)
	var largura: float = area_paginas.size.x * signf(passo)
	
	entrando.position.x = largura
	entrando.show()
	
	var tween := create_tween().set_parallel(true) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(saindo, "position:x", -largura, DURACAO_TROCA)
	tween.tween_property(entrando, "position:x", 0.0, DURACAO_TROCA)
	await tween.finished
	
	saindo.hide()
	saindo.position.x = 0.0
	indice_atual = novo_indice
	_trocando = false
	_atualizar_botoes()


func _atualizar_botoes() -> void:
	var tem_anterior: bool = indice_atual > 0
	var tem_proxima: bool = indice_atual < paginas.size() - 1
	botao_anterior.disabled = not tem_anterior
	botao_anterior.modulate.a = 1.0 if tem_anterior else 0.25
	botao_proximo.disabled = not tem_proxima
	botao_proximo.modulate.a = 1.0 if tem_proxima else 0.25
	label_titulo.text = "RECOMPENSA DE PEÇA %d / %d" % [indice_atual + 1, paginas.size()]
	
	var todas_escolhidas: bool = true
	for pagina in paginas:
		if not pagina.tem_selecao():
			todas_escolhidas = false
	botao_confirmar.disabled = not todas_escolhidas


func _on_confirmar_pressionado() -> void:
	botao_confirmar.disabled = true
	var escolhidas: Array[Peca] = []
	for pagina in paginas:
		var peca: Peca = pagina.obter_peca_escolhida()
		if peca != null:
			escolhidas.append(peca)
	confirmado.emit(escolhidas)
