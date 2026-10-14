extends Control
class_name MenuIncial

func _ready() -> void:
	for _botao in $Menu/ContainerBotoes.get_children():
		if _botao is Button:
			_botao.pressed.connect(_quando_botao_menu_precionado.bind(_botao))


func _quando_botao_menu_precionado(_botao: Button) -> void:
	match _botao.name:
		"NovoJogo":
			pass
		"Inventario":
			pass
		"AbrirPacote":
			pass
		"Configuraçoes":
			pass
		"Creditos":
			$Creditos.show()
			$Menu.hide()
		"Sair":
			get_tree().quit()


func _quando_botao_fechar_creditos_pressionado() -> void:
	$Creditos.hide()
	$Menu.show()
