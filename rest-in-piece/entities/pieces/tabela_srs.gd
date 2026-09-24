
class_name SRS

# Tabela compartilhada para J, L, S, T, Z
# Os índices representam a transição. Ex: "0_90" é girar do ângulo 0 para 90.
const TABELA_PADRAO = {
	"0_90": [Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,-1), Vector2i(0,2), Vector2i(-1,2)],
	"90_0": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,-2), Vector2i(1,-2)],
	"90_180": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,-2), Vector2i(1,-2)],
	"180_90": [Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,-1), Vector2i(0,2), Vector2i(-1,2)],
	"180_270": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,-1), Vector2i(0,2), Vector2i(1,2)],
	"270_180": [Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,-2), Vector2i(-1,-2)],
	"270_0": [Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,-2), Vector2i(-1,-2)],
	"0_270": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,-1), Vector2i(0,2), Vector2i(1,2)],
}

# Tabela exclusiva para a peça I
const TABELA_I = {
	"0_90": [Vector2i(0,0), Vector2i(-2,0), Vector2i(1,0), Vector2i(-2,1), Vector2i(1,-2)],
	"90_0": [Vector2i(0,0), Vector2i(2,0), Vector2i(-1,0), Vector2i(2,-1), Vector2i(-1,2)],
	"90_180": [Vector2i(0,0), Vector2i(-1,0), Vector2i(2,0), Vector2i(-1,-2), Vector2i(2,1)],
	"180_90": [Vector2i(0,0), Vector2i(1,0), Vector2i(-2,0), Vector2i(1,2), Vector2i(-2,-1)],
	"180_270": [Vector2i(0,0), Vector2i(2,0), Vector2i(-1,0), Vector2i(2,-1), Vector2i(-1,2)],
	"270_180": [Vector2i(0,0), Vector2i(-2,0), Vector2i(1,0), Vector2i(-2,1), Vector2i(1,-2)],
	"270_0": [Vector2i(0,0), Vector2i(1,0), Vector2i(-2,0), Vector2i(1,2), Vector2i(-2,-1)],
	"0_270": [Vector2i(0,0), Vector2i(-1,0), Vector2i(2,0), Vector2i(-1,-2), Vector2i(2,1)],
}

static func obter_testes(tipo_tabela: String, rotacao_atual: int, proxima_rotacao: int) -> Array:
	# concatena as duas rotações, pra usar o formato "90_180", por exemplo
	var chave = str(rotacao_atual) + "_" + str(proxima_rotacao)
	
	if tipo_tabela == "PADRAO":
		return TABELA_PADRAO.get(chave, [Vector2i.ZERO])
	elif tipo_tabela == "I":
		return TABELA_I.get(chave, [Vector2i.ZERO])
	
	return [Vector2i.ZERO] # a peça O não tem rotação
