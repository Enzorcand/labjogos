extends Label

# Lista com as ações configuradas no seu Project Settings
@export var acoes: Array[String] = ["Pula", "Atira", "MovimentoEsquerda", "MovimentoDireita", "Trava"]

func _ready() -> void:
	atualizar_texto_controles()

func atualizar_texto_controles() -> void:
	var texto_final = "CONTROLES\n\n"
	
	# Percorre cada ação e pega a tecla atribuída
	for acao in acoes:
		var eventos = InputMap.action_get_events(acao)
		if eventos.size() > 0:
			# Pega o primeiro evento (tecla/botão) mapeado
			var evento = eventos[0]
			var nome_tecla = ""
			
			if evento is InputEventKey:
				nome_tecla = evento.as_text_physical_keycode()
			else:
				# Para controles (Gamepads)
				nome_tecla = evento.as_text()
				
			# Formata o texto final (Ex: Pular: ESPAÇO)
			texto_final += "%s: %s\n" % [acao.capitalize(), nome_tecla]
		else:
			texto_final += "%s: Nenhuma tecla\n" % acao.capitalize()
			
	# Atualiza a Label com os dados processados
	text = texto_final
