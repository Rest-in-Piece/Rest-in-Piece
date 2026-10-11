

# "ao usar o hard drop, cada quadradinho da peça posicionada guarda pontos a mais por cada
# casa que a peça desceu. Os pontos só são recebidos quando o quadradinho pontuar"
class_name ReliquiaBonusHardDrop
extends Reliquia

## pontos guardados em CADA um dos 4 quadradinhos, por casa descida. Um valor por nível
@export var pontos_por_casa_por_nivel: Array[int] = [1, 2, 3]

func ao_travar_peca(travamento: TravamentoDePeca) -> void:
	if travamento.casas_hard_drop <= 0:
		return
	
	var pontos_por_casa: int = escolher_por_nivel(pontos_por_casa_por_nivel)
	travamento.adicionar_pontos_por_bloco(pontos_por_casa * travamento.casas_hard_drop)
