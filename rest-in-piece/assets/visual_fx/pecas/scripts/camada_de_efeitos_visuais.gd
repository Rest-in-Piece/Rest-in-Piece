
# desenha os EfeitoVisual das peças em cima do tabuleiro. É criada por código (instalar) como
# filho do tabuleiro e só reage aos signals dele; não participa da lógica.
# Efeitos de uma peça = os da própria Peca + os das relíquias (via "obter_efeitos_das_reliquias").
#   queda:    uma célula por quadradinho da peça em jogo + um nó pra peça inteira
#   fixação:  uma vez, quando a peça trava (por célula e pela peça inteira)
#   fixos:    uma célula por BlocoFixado, que acompanha o bloco quando ele muda de lugar

class_name CamadaDeEfeitosVisuais
extends Node2D

class Celula:
	var no: Node2D
	var assinatura: Array = []  # lados expostos por efeito; se mudar, a célula é refeita

var _tabuleiro: TileMapLayer
var _obter_efeitos_das_reliquias: Callable
var _celulas_em_queda: Array[Celula] = []
var _no_da_peca: Node2D
var _assinatura_da_queda: Array = []
var _celulas_fixas: Dictionary = {}  # BlocoFixado -> Celula


static func instalar(tabuleiro: TileMapLayer, obter_efeitos_das_reliquias: Callable) -> CamadaDeEfeitosVisuais:
	var camada := CamadaDeEfeitosVisuais.new()
	camada.name = "EfeitosVisuaisDePeca"
	camada.z_index = 5
	camada._tabuleiro = tabuleiro
	camada._obter_efeitos_das_reliquias = obter_efeitos_das_reliquias
	tabuleiro.add_child(camada)
	return camada


func _ready() -> void:
	_tabuleiro.peca_em_jogo_desenhada.connect(_on_peca_em_jogo_desenhada)
	_tabuleiro.peca_travada.connect(_on_peca_travada)
	_tabuleiro.blocos_fixados_alterados.connect(_sincronizar_blocos_fixos)
	_tabuleiro.jogo_iniciado.connect(_limpar_tudo)


# ---------- queda ----------

func _on_peca_em_jogo_desenhada(peca: Peca, posicoes: Array[Vector2i]) -> void:
	var efeitos: Array[EfeitoVisual] = _filtrar(_efeitos_da_peca(peca), &"ativo_na_queda")
	if efeitos.is_empty() or posicoes.is_empty():
		_liberar_queda()
		return
	
	var pertence := func(p: Vector2i, _efeito: EfeitoVisual) -> bool: return posicoes.has(p)
	var bordas_por_celula: Array = []
	for posicao in posicoes:
		bordas_por_celula.append(_bordas_da_celula(posicao, efeitos, pertence))
	
	var assinatura: Array = [peca, bordas_por_celula]
	if assinatura != _assinatura_da_queda:
		_liberar_queda()
		_assinatura_da_queda = assinatura
		for i in range(posicoes.size()):
			_celulas_em_queda.append(_criar_celula(posicoes[i], efeitos, bordas_por_celula[i]))
		_criar_no_da_peca(posicoes, efeitos)
		return
	
	for i in range(posicoes.size()):
		var celula: Celula = _celulas_em_queda[i]
		var destino: Vector2 = _centro(posicoes[i])
		if celula.no.position == destino:
			continue
		var origem: Vector2 = celula.no.position
		celula.no.position = destino
		for efeito in efeitos:
			efeito.ao_celula_movida(_novo_contexto(destino, 0.0, 0), origem)
	
	_no_da_peca.position = _retangulo(posicoes).get_center()


func _criar_no_da_peca(posicoes: Array[Vector2i], efeitos: Array[EfeitoVisual]) -> void:
	var retangulo: Rect2 = _retangulo(posicoes)
	_no_da_peca = Node2D.new()
	_no_da_peca.position = retangulo.get_center()
	add_child(_no_da_peca)
	
	var contexto := _novo_contexto(retangulo.get_center(), 0.0, 0)
	contexto.retangulo = retangulo
	for efeito in efeitos:
		efeito.ao_criar_peca(_no_da_peca, contexto)


func _liberar_queda() -> void:
	for celula in _celulas_em_queda:
		celula.no.queue_free()
	_celulas_em_queda.clear()
	if _no_da_peca != null:
		_no_da_peca.queue_free()
		_no_da_peca = null
	_assinatura_da_queda = []


# ---------- fixação ----------

func _on_peca_travada(peca: Peca, _casas_hard_drop: int) -> void:
	_liberar_queda()
	
	var efeitos: Array[EfeitoVisual] = _filtrar(_efeitos_da_peca(peca), &"ativo_na_fixacao")
	var posicoes: Array[Vector2i] = _tabuleiro.posicoes_ultima_peca
	if efeitos.is_empty() or posicoes.is_empty():
		return
	
	var pertence := func(p: Vector2i, _efeito: EfeitoVisual) -> bool: return posicoes.has(p)
	for posicao in posicoes:
		var fase: float = randf()
		for efeito in efeitos:
			var bordas: int = 0
			if efeito.usa_bordas():
				bordas = _calcular_bordas(posicao, pertence.bind(efeito))
			efeito.ao_fixar_celula(_novo_contexto(_centro(posicao), fase, bordas))
	
	var retangulo: Rect2 = _retangulo(posicoes)
	var contexto := _novo_contexto(retangulo.get_center(), 0.0, 0)
	contexto.retangulo = retangulo
	for efeito in efeitos:
		efeito.ao_fixar_peca(contexto)


# ---------- blocos fixos ----------

func _sincronizar_blocos_fixos() -> void:
	var blocos: Dictionary[Vector2i, BlocoFixado] = _tabuleiro.blocos_fixados
	var pertence := func(p: Vector2i, efeito: EfeitoVisual) -> bool:
		var vizinho: BlocoFixado = blocos.get(p)
		return vizinho != null and vizinho.efeitos_visuais.has(efeito)
	
	var vivos: Dictionary = {}
	for posicao in blocos:
		var bloco: BlocoFixado = blocos[posicao]
		var efeitos: Array[EfeitoVisual] = _filtrar(bloco.efeitos_visuais, &"permanece_fixo")
		if efeitos.is_empty():
			continue
		vivos[bloco] = true
		
		var bordas: Array[int] = _bordas_da_celula(posicao, efeitos, pertence)
		var celula: Celula = _celulas_fixas.get(bloco)
		if celula != null and celula.assinatura == bordas:
			celula.no.position = _centro(posicao)
			continue
		if celula != null:
			celula.no.queue_free()
		_celulas_fixas[bloco] = _criar_celula(posicao, efeitos, bordas)
	
	for bloco in _celulas_fixas.keys():
		if not vivos.has(bloco):
			_celulas_fixas[bloco].no.queue_free()
			_celulas_fixas.erase(bloco)


func _limpar_tudo() -> void:
	_liberar_queda()
	for celula in _celulas_fixas.values():
		celula.no.queue_free()
	_celulas_fixas.clear()


# ---------- auxiliares ----------

func _efeitos_da_peca(peca: Peca) -> Array[EfeitoVisual]:
	var das_reliquias: Array[EfeitoVisual] = []
	if _obter_efeitos_das_reliquias.is_valid():
		das_reliquias = _obter_efeitos_das_reliquias.call(peca)
	return EfeitoVisual.combinar(peca.efeitos_visuais, das_reliquias)


func _filtrar(efeitos: Array[EfeitoVisual], consulta: StringName) -> Array[EfeitoVisual]:
	var filtrados: Array[EfeitoVisual] = []
	for efeito in efeitos:
		if efeito.call(consulta):
			filtrados.append(efeito)
	return filtrados


func _criar_celula(posicao: Vector2i, efeitos: Array[EfeitoVisual], bordas: Array[int]) -> Celula:
	var celula := Celula.new()
	celula.assinatura = bordas
	celula.no = Node2D.new()
	celula.no.position = _centro(posicao)
	add_child(celula.no)
	
	var fase: float = randf()
	for i in range(efeitos.size()):
		efeitos[i].ao_criar_celula(celula.no, _novo_contexto(celula.no.position, fase, bordas[i]))
	return celula


# um valor por efeito (0 pra quem não usa bordas)
func _bordas_da_celula(posicao: Vector2i, efeitos: Array[EfeitoVisual], pertence: Callable) -> Array[int]:
	var lista: Array[int] = []
	for efeito in efeitos:
		var bordas: int = 0
		if efeito.usa_bordas():
			bordas = _calcular_bordas(posicao, pertence.bind(efeito))
		lista.append(bordas)
	return lista


# "pertence" diz se a posição vizinha faz parte do mesmo grupo
func _calcular_bordas(posicao: Vector2i, pertence: Callable) -> int:
	var bordas: int = 0
	if not pertence.call(posicao + Vector2i.UP):
		bordas |= ContextoVisual.TOPO
	if not pertence.call(posicao + Vector2i.RIGHT):
		bordas |= ContextoVisual.DIREITA
	if not pertence.call(posicao + Vector2i.DOWN):
		bordas |= ContextoVisual.BAIXO
	if not pertence.call(posicao + Vector2i.LEFT):
		bordas |= ContextoVisual.ESQUERDA
	return bordas


func _novo_contexto(posicao: Vector2, fase: float, bordas: int) -> ContextoVisual:
	var contexto := ContextoVisual.new()
	contexto.camada = self
	contexto.tamanho = Vector2(_tabuleiro.tile_set.tile_size)
	contexto.posicao = posicao
	contexto.fase = fase
	contexto.bordas_expostas = bordas
	return contexto


func _centro(posicao: Vector2i) -> Vector2:
	return _tabuleiro.map_to_local(posicao)


# retângulo que envolve todas as células, no espaço da camada
func _retangulo(posicoes: Array[Vector2i]) -> Rect2:
	var tamanho := Vector2(_tabuleiro.tile_set.tile_size)
	var retangulo := Rect2(_centro(posicoes[0]) - tamanho / 2.0, tamanho)
	for posicao in posicoes:
		retangulo = retangulo.merge(Rect2(_centro(posicao) - tamanho / 2.0, tamanho))
	return retangulo
