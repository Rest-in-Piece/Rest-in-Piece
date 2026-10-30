
# escuta o AutoBus e toca os efeitos PECA_* da relíquia nos quadradinhos que ela afetou.
# É criado por código (EfeitosDeReliquiaNoTabuleiro.instalar) como filho do tabuleiro, então
# as posições do grid viram posições na tela com o próprio map_to_local do tabuleiro, igual
# ao EfeitoQuebraVidro. Não participa da lógica: os quadradinhos podem até já ter sido
# destruídos quando o efeito aparece, ele só marca ONDE a relíquia agiu.
#
# Os quadradinhos de uma mesma relíquia entram em sequência (um pequeno atraso entre eles),
# o que cria uma "onda" da esquerda pra direita, na ordem em que a pontuação é calculada.

class_name EfeitosDeReliquiaNoTabuleiro
extends Node

## atraso entre um quadradinho e o seguinte da mesma relíquia
const INTERVALO_ESCALONAMENTO: float = 0.035
## teto do atraso, pra uma jogada grande não demorar a mostrar os últimos efeitos
const ATRASO_MAXIMO: float = 0.5

var _tabuleiro: TileMapLayer
# Reliquia -> quantos quadradinhos já foram agendados neste quadro
var _ordem_no_quadro: Dictionary = {}
# evita tocar o mesmo efeito, na mesma célula, pela mesma relíquia, duas vezes no quadro
var _ja_tocados: Dictionary = {}
var _limpeza_agendada: bool = false


static func instalar(tabuleiro: TileMapLayer) -> EfeitosDeReliquiaNoTabuleiro:
	var ouvinte := EfeitosDeReliquiaNoTabuleiro.new()
	ouvinte.name = "EfeitosDeReliquia"
	ouvinte._tabuleiro = tabuleiro
	tabuleiro.add_child(ouvinte)
	return ouvinte


func _ready() -> void:
	AutoBus.reliquia_afetou_blocos.connect(_on_reliquia_afetou_blocos)


func _on_reliquia_afetou_blocos(reliquia: Reliquia, posicoes: Array[Vector2i]) -> void:
	var efeitos: Array[Reliquia.EfeitoDeAtivacao] = reliquia.obter_efeitos_na_peca()
	if efeitos.is_empty():
		return
	
	var ordem: int = _ordem_no_quadro.get(reliquia, 0)
	for posicao in posicoes:
		var tocou_algum: bool = false
		
		for efeito in efeitos:
			var chave: String = "%d|%d,%d|%d" % [reliquia.get_instance_id(), posicao.x, posicao.y, efeito]
			if _ja_tocados.has(chave):
				continue
			_ja_tocados[chave] = true
			tocou_algum = true
			
			var atraso: float = minf(ordem * INTERVALO_ESCALONAMENTO, ATRASO_MAXIMO)
			_tocar_na_celula(efeito, posicao, atraso, reliquia.cor_dos_efeitos)
		
		if tocou_algum:
			ordem += 1
	
	_ordem_no_quadro[reliquia] = ordem
	_agendar_limpeza()


func _tocar_na_celula(efeito: Reliquia.EfeitoDeAtivacao, posicao: Vector2i, atraso: float, cor: Color) -> void:
	var caixa := Vector2(_tabuleiro.tile_set.tile_size)
	var centro: Vector2 = _tabuleiro.map_to_local(posicao)
	
	match efeito:
		Reliquia.EfeitoDeAtivacao.PECA_CONTORNO:
			OverlaysDeEfeito.contorno(_tabuleiro, centro, caixa, atraso, cor)
		Reliquia.EfeitoDeAtivacao.PECA_GLOW:
			OverlaysDeEfeito.glow(_tabuleiro, centro, caixa, atraso, cor)
		Reliquia.EfeitoDeAtivacao.PECA_BRILHO_VARREDURA:
			OverlaysDeEfeito.brilho_varredura(_tabuleiro, centro, caixa, atraso)
		Reliquia.EfeitoDeAtivacao.PECA_ONDA:
			OverlaysDeEfeito.onda(_tabuleiro, centro, caixa, atraso, cor)
		Reliquia.EfeitoDeAtivacao.PECA_FAISCAS:
			OverlaysDeEfeito.faiscas(_tabuleiro, centro, caixa, atraso, cor)
		_:
			pass  # efeitos RELIQUIA_* são do ReliquiaSlot


# a contagem e a trava de duplicados valem por quadro: limpa tudo no quadro seguinte
func _agendar_limpeza() -> void:
	if _limpeza_agendada:
		return
	_limpeza_agendada = true
	get_tree().process_frame.connect(_limpar_controle_do_quadro, CONNECT_ONE_SHOT)


func _limpar_controle_do_quadro() -> void:
	_ordem_no_quadro.clear()
	_ja_tocados.clear()
	_limpeza_agendada = false
