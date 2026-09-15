
extends CanvasLayer

@onready var label_pontuacao: Label = %LabelPontuação

func atualizar_pontuacao(pontuacao: int):
	label_pontuacao.text = str("PONTUAÇÃO: " + str(pontuacao))
