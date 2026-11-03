# =============================================================================
# musica_dinamica.gd
# Toca a música da fase e a modifica conforme a "tensão" do tabuleiro (0..1),
# calculada a partir da altura da pilha e/ou da densidade de blocos.
#
# ESTRUTURA (cada módulo é independente e pode ser removido):
#   [NÚCLEO]  tensão, fade de entrada/saída, bus de áudio. NÃO remover.
#   [MÓDULO PITCH]    altera a velocidade/tom da música
#   [MÓDULO LOWPASS]  abafa os agudos
#   [MÓDULO VOLUME]   altera o volume
#   [MÓDULO REVERB]   adiciona reverberação
# Para remover um módulo: apague as 3 partes marcadas com o nome dele
# (exports, função _preparar_xxx/_aplicar_xxx e a linha em _ready/_process).
# =============================================================================
class_name MusicaDinamica
extends AudioStreamPlayer

const NOME_BUS: String = "MusicaDinamica"
const CUTOFF_ABERTO_HZ: float = 20500.0  # low-pass "desligado"

enum FonteTensao { ALTURA, DENSIDADE, MAIOR_DOS_DOIS }


# ===================== [NÚCLEO] EXPORTS =====================
@export_category("Geral")
## volume da música sem nenhum efeito (use ESTE em vez do volume_db do nó)
@export var volume_base_db: float = -6.0
## duração do fade in / fade out ao iniciar ou pausar a música
@export_range(0.0, 10.0, 0.1, "suffix:s") var tempo_transicao: float = 1.5

@export_category("Tensão")
## o que define a tensão: altura da pilha, densidade de blocos ou o maior dos dois
@export var fonte_tensao: FonteTensao = FonteTensao.ALTURA
## altura (em linhas) em que a tensão chega a 1
@export_range(1, 20) var altura_maxima_linhas: int = 16
## altura (em linhas) abaixo da qual a tensão por altura fica em 0
@export_range(0, 19) var altura_minima_linhas: int = 4
## fração do tabuleiro preenchida (0..1) em que a tensão chega a 1
@export_range(0.05, 1.0, 0.05) var densidade_maxima: float = 0.6
## tempo para a tensão acompanhar mudanças (evita saltos bruscos no som)
@export_range(0.0, 10.0, 0.1, "suffix:s") var suavizacao_tensao: float = 1.5

# ===================== [MÓDULO PITCH] EXPORTS =====================
@export_category("Pitch")
## variação do pitch com tensão 1 (0.1 = +10%, negativo = fica mais grave). 0 = desligado
@export_range(-0.5, 0.5, 0.01) var intensidade_pitch: float = 0.08

# ===================== [MÓDULO LOWPASS] EXPORTS =====================
@export_category("Low-pass")
## 0 = desligado, 1 = abafa até o cutoff mínimo com tensão 1
@export_range(0.0, 1.0, 0.05) var intensidade_lowpass: float = 0.5  # 1
## frequência de corte com abafamento total (Hz)
@export_range(100.0, 20000.0, 50.0, "suffix:Hz") var cutoff_minimo_hz: float = 600.0  # 400

# ===================== [MÓDULO VOLUME] EXPORTS =====================
@export_category("Volume")
## dB somados com tensão 1 (positivo = mais alto, negativo = mais baixo). 0 = desligado
@export_range(-20.0, 20.0, 0.5, "suffix:dB") var intensidade_volume_db: float = 2.0

# ===================== [MÓDULO REVERB] EXPORTS =====================
@export_category("Reverb")
## quantidade de reverb (wet) com tensão 1. 0 = desligado
@export_range(0.0, 1.0, 0.05) var intensidade_reverb: float = 0.0


# ===================== [NÚCLEO] ESTADO =====================
@onready var _tabuleiro: TileMapLayer = $"../TabuleiroTileMap"

var _tensao_alvo: float = 0.0   # valor "real" do tabuleiro
var _tensao: float = 0.0        # valor suavizado, usado pelos módulos
var _fade: float = 0.0          # 0..1 (linear), animado pelo tween
var _db_extra_tensao: float = 0.0  # preenchido pelo módulo de volume
var _posicao_salva: float = 0.0
var _tween: Tween

# referências dos efeitos (só existem se o módulo estiver ligado)
var _filtro_lowpass: AudioEffectLowPassFilter  # [MÓDULO LOWPASS]
var _reverb: AudioEffectReverb                 # [MÓDULO REVERB]


func _ready() -> void:
	_criar_bus()
	_preparar_lowpass()   # [MÓDULO LOWPASS] remova esta linha junto com o módulo
	_preparar_reverb()    # [MÓDULO REVERB]  remova esta linha junto com o módulo
	
	_tabuleiro.jogo_iniciado.connect(iniciar)
	_tabuleiro.blocos_fixados_alterados.connect(_atualizar_tensao_alvo)
	# fase concluída = tela de recompensas (ou vitória final); derrota também para a música
	AutoBus.fase_concluida.connect(_on_fim_de_fase)
	AutoBus.partida_perdida.connect(_on_fim_de_fase)


func _exit_tree() -> void:
	var indice: int = AudioServer.get_bus_index(NOME_BUS)
	if indice != -1:
		AudioServer.remove_bus(indice)


func _process(delta: float) -> void:
	if not playing:
		return
	
	# suavização exponencial da tensão
	var passo: float = 1.0 - exp(-delta / maxf(suavizacao_tensao, 0.001))
	_tensao = lerpf(_tensao, _tensao_alvo, passo)
	
	_aplicar_pitch(_tensao)           # [MÓDULO PITCH]
	_aplicar_lowpass(_tensao)         # [MÓDULO LOWPASS]
	_aplicar_volume_dinamico(_tensao) # [MÓDULO VOLUME]
	_aplicar_reverb(_tensao)          # [MÓDULO REVERB]
	
	# volume final = base + fade + (opcional) variação por tensão
	volume_db = volume_base_db + linear_to_db(maxf(_fade, 0.0001)) + _db_extra_tensao


# ===================== [NÚCLEO] INICIAR / PAUSAR COM FADE =====================
func iniciar() -> void:
	_matar_tween()
	if not playing:
		play(_posicao_salva)  # retoma de onde parou
	_tween = create_tween()
	_tween.tween_property(self, "_fade", 1.0, tempo_transicao)


func pausar() -> void:
	if not playing:
		return
	_matar_tween()
	_tween = create_tween()
	_tween.tween_property(self, "_fade", 0.0, tempo_transicao)
	_tween.tween_callback(_parar_guardando_posicao)


func _parar_guardando_posicao() -> void:
	_posicao_salva = get_playback_position()
	stop()


func _on_fim_de_fase(_pontuacao: int) -> void:
	pausar()


func _matar_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


# ===================== [NÚCLEO] TENSÃO DO TABULEIRO =====================
func _atualizar_tensao_alvo() -> void:
	var blocos: Dictionary = _tabuleiro.blocos_fixados
	var altura: float = 0.0
	var densidade: float = 0.0
	
	if not blocos.is_empty():
		var linha_mais_alta: int = _tabuleiro.LINHAS
		for posicao in blocos:
			linha_mais_alta = mini(linha_mais_alta, posicao.y)
		var altura_em_linhas: int = _tabuleiro.LINHAS - linha_mais_alta + 1
		var faixa: float = maxf(float(altura_maxima_linhas - altura_minima_linhas), 1.0)
		altura = clampf(float(altura_em_linhas - altura_minima_linhas) / faixa, 0.0, 1.0)
		densidade = clampf(float(blocos.size()) / (_tabuleiro.COLUNAS * _tabuleiro.LINHAS) / densidade_maxima, 0.0, 1.0)
	
	match fonte_tensao:
		FonteTensao.ALTURA: _tensao_alvo = altura
		FonteTensao.DENSIDADE: _tensao_alvo = densidade
		FonteTensao.MAIOR_DOS_DOIS: _tensao_alvo = maxf(altura, densidade)


# ===================== [NÚCLEO] BUS DE ÁUDIO (criado por código) =====================
func _criar_bus() -> void:
	if AudioServer.get_bus_index(NOME_BUS) == -1:
		var indice: int = AudioServer.bus_count
		AudioServer.add_bus(indice)
		AudioServer.set_bus_name(indice, NOME_BUS)
		AudioServer.set_bus_send(indice, "Master")
	bus = NOME_BUS


func _adicionar_efeito_ao_bus(efeito: AudioEffect) -> void:
	AudioServer.add_bus_effect(AudioServer.get_bus_index(NOME_BUS), efeito)


# ===================== [MÓDULO PITCH] =====================
func _aplicar_pitch(tensao: float) -> void:
	if is_zero_approx(intensidade_pitch):
		return
	pitch_scale = maxf(1.0 + intensidade_pitch * tensao, 0.1)


# ===================== [MÓDULO LOWPASS] =====================
func _preparar_lowpass() -> void:
	if is_zero_approx(intensidade_lowpass):
		return
	_filtro_lowpass = AudioEffectLowPassFilter.new()
	_filtro_lowpass.cutoff_hz = CUTOFF_ABERTO_HZ
	_adicionar_efeito_ao_bus(_filtro_lowpass)

func _aplicar_lowpass(tensao: float) -> void:
	if _filtro_lowpass == null:
		return
	var quanto: float = clampf(intensidade_lowpass, 0.0, 1.0) * tensao
	# interpolação em escala logarítmica: soa mais natural que linear em Hz
	_filtro_lowpass.cutoff_hz = exp(lerpf(log(CUTOFF_ABERTO_HZ), log(cutoff_minimo_hz), quanto))


# ===================== [MÓDULO VOLUME] =====================
func _aplicar_volume_dinamico(tensao: float) -> void:
	if is_zero_approx(intensidade_volume_db):
		return
	_db_extra_tensao = intensidade_volume_db * tensao


# ===================== [MÓDULO REVERB] =====================
func _preparar_reverb() -> void:
	if is_zero_approx(intensidade_reverb):
		return
	_reverb = AudioEffectReverb.new()
	_reverb.dry = 1.0
	_reverb.wet = 0.0
	_adicionar_efeito_ao_bus(_reverb)

func _aplicar_reverb(tensao: float) -> void:
	if _reverb == null:
		return
	_reverb.wet = clampf(intensidade_reverb, 0.0, 1.0) * tensao
