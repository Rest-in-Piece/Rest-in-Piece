

# "as linhas de baixo não concedem pontos, mas a partir de uma certa altura o
# multiplicador é muito maior"
class_name ReliquiaTorreAlta
extends Reliquia

## linhas de baixo que NÃO pontuam (altura 1 até este valor). Um valor por nível
@export var linhas_zeradas_por_nivel: Array[int] = [3, 2, 1]
## a partir desta altura (1 = baixo, 20 = topo) a linha concede o multiplicador extra
@export var altura_minima_bonus_por_nivel: Array[int] = [8, 7, 6]
## multiplicador somado por linha que atinge a altura mínima
@export var multiplicador_bonus_por_nivel: Array[float] = [3.0, 4.0, 5.0]

func ao_pontuar_linha(contexto: ContextoPontuacao, linha: LinhaPontuada) -> void:
	if linha.zerada:
		return
	
	var linhas_zeradas: int = escolher_por_nivel(linhas_zeradas_por_nivel)
	if linha.altura <= linhas_zeradas:
		linha.zerar()
		return
	
	var altura_minima_bonus: int = escolher_por_nivel(altura_minima_bonus_por_nivel)
	if linha.altura >= altura_minima_bonus:
		var multiplicador_bonus: float = escolher_por_nivel(multiplicador_bonus_por_nivel)
		contexto.adicionar_multiplicador(multiplicador_bonus)
