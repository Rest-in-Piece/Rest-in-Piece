extends Control
class_name MenuIncial

@onready var tela_controles: Control = $TelaControles

func _ready() -> void:
	tela_controles.fechou.connect(_quando_controles_fechados)
	for _botao in $Menu/ContainerBotoes.get_children():
		if _botao is Button:
			_botao.pressed.connect(_quando_botao_menu_precionado.bind(_botao))


func _quando_botao_menu_precionado(_botao: Button) -> void:
	match _botao.name:
		"NovoJogo":
			get_tree().change_scene_to_file("res://core/tetris.tscn")
		"Inventario":
			pass
		"AbrirPacote":
			pass
		"Configuraçoes":
			pass
		"Controles":
			$Menu.hide()
			tela_controles.abrir()
		"Creditos":
			$Creditos.show()
			$Menu.hide()
		"Sair":
			get_tree().quit()


func _quando_botao_fechar_creditos_pressionado() -> void:
	$Creditos.hide()
	$Menu.show()


func _quando_controles_fechados() -> void:
	$Menu.show()
	$Menu/ContainerBotoes/Controles.grab_focus()
