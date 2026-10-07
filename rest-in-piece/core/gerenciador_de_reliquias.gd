
# guarda as relíquias do jogador e repassa os eventos do jogo pra elas, na ordem
# em que foram adquiridas. Não sabe nada de tabuleiro nem de HUD.

class_name GerenciadorDeReliquias
extends RefCounted

signal reliquias_alteradas

const MAX_RELIQUIAS: int = 5

var reliquias: Array[Reliquia] = []


func adquirir(reliquia: Reliquia) -> bool:
	if reliquias.size() >= MAX_RELIQUIAS:
		return false
	
	# usa uma cópia pra que o estado da relíquia não vaze pro arquivo .tres
	reliquias.append(reliquia.duplicate() as Reliquia)
	reliquias_alteradas.emit()
	return true

func remover(reliquia: Reliquia):
	reliquias.erase(reliquia)
	reliquias_alteradas.emit()

func limpar():
	reliquias.clear()
	reliquias_alteradas.emit()


func aplicar_regras(regras: RegrasJogo):
	for reliquia in reliquias:
		reliquia.modificar_regras(regras)

func aplicar_pecas_sorteaveis(pecas: Array[Peca]):
	for reliquia in reliquias:
		reliquia.modificar_pecas_sorteaveis(pecas)

func processar_pontuacao(contexto: ContextoPontuacao):
	for reliquia in reliquias:
		contexto.ativou_reliquia = false
		reliquia.ao_pontuar(contexto)
		
		if contexto.ativou_reliquia:
			AutoBus.reliquia_ativada.emit(reliquia)
