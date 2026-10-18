
# classe base de todo efeito de peça especial. Cada efeito só sobrescreve os hooks que
# precisa; os que não forem sobrescritos não fazem nada (mesma ideia da Reliquia).
#
# REGRAS
# - Efeitos são SEM ESTADO: o mesmo recurso (.tres) é compartilhado por várias peças e
#   por vários blocos do tabuleiro. Estado de execução vive na Peca (buffs) ou no
#   BlocoFixado, nunca aqui.
# - Efeitos não sabem de pontuação nem de HUD. Só consultam/alteram o tabuleiro
#   (tetris.gd) pelos métodos públicos dele.
# - O tabuleiro nunca pergunta "é areia?" ou "é bomba?": ele só chama os hooks.
# - O parâmetro "tabuleiro" é o tetris.gd (TileMapLayer).

class_name EfeitoDePeca
extends Resource

@export var nome: String = ""
@export_multiline var descricao: String = ""


# ---------- regras de movimento (consultas; a Peca combina as respostas) ----------

# a peça ignora os blocos fixos ao se mover e é desenhada numa camada separada
func atravessa_blocos() -> bool:
	return false

# a peça fixa sozinha, sem o atraso de fixação, assim que não consegue mais descer.
# O hard drop também fixa na hora
func fixa_ao_apoiar() -> bool:
	return false

# o jogador pode fixar a peça quando quiser (tecla "materializar_fantasma")
func permite_fixar_manualmente() -> bool:
	return false

# veto extra para DESCER. "forma" são os deslocamentos da peça e "posicao" é onde ela
# ficaria depois de descer. Só é consultado em movimentos para baixo
func permite_descer(_tabuleiro: TileMapLayer, _forma: Array, _posicao: Vector2i) -> bool:
	return true

# multiplicada pelas cores dos outros efeitos (peça, próxima peça, hold e projeção)
func cor_visual() -> Color:
	return Color.WHITE


# ---------- ciclo da peça ----------

# chamado quando a peça vai ser registrada no tabuleiro (e na projeção). Devolve só as
# posições que de fato recebem bloco
func filtrar_posicoes_para_registro(_tabuleiro: TileMapLayer, posicoes: Array[Vector2i]) -> Array[Vector2i]:
	return posicoes

# chamado logo depois de os blocos da peça serem registrados. "posicoes" são os blocos
# que realmente entraram no tabuleiro
func ao_travar(_tabuleiro: TileMapLayer, _posicoes: Array[Vector2i]) -> void:
	pass

# chamado ao calcular a projeção (sombra). Devolve onde os blocos acabariam. "ignoradas"
# são células ocupadas pela própria peça, que devem ser tratadas como vazias
func ao_projetar(_tabuleiro: TileMapLayer, posicoes: Array[Vector2i], _ignoradas: Array[Vector2i]) -> Array[Vector2i]:
	return posicoes


# ---------- ciclo do tabuleiro (agem sobre os BLOCOS que carregam este efeito) ----------

# FÍSICA: mover blocos (gravidade). Roda ANTES de checar as linhas completas. Devolve true
# se algo mudou
func ao_assentar_tabuleiro(_tabuleiro: TileMapLayer) -> bool:
	return false

# REGRAS: remover/transformar blocos. Roda DEPOIS de as linhas completas serem limpas.
# Devolve true se algo mudou
func ao_resolver_tabuleiro(_tabuleiro: TileMapLayer) -> bool:
	return false
