# Migra os .tres de Peca do formato ANTIGO (flags booleanas) para o NOVO (lista de efeitos).
#
# Uso (a partir da raiz do projeto, com tudo commitado antes):
#   godot --headless --path . --script res://tools/migrar_pecas.gd -- --simular   (só relata)
#   godot --headless --path . --script res://tools/migrar_pecas.gd                (migra)
#
# O que faz, em cada .tres de Peca dentro de res://entities/pecas (não recursivo):
#   cai_em_blocos_ao_travar = true  ->  efeitos += efeito_areia.tres
#   explode_ao_travar       = true  ->  efeitos += efeito_explosao.tres  (+ tabela_srs = "O" se tipo BOMBA)
#   atravessa_blocos        = true  ->  efeitos += efeito_fantasma.tres
#   eh_fragil               = true  ->  efeitos += efeito_vidro.tres
# Remove as propriedades antigas (inclusive atlas_por_estagio_de_dano e
# resistencia_ao_peso_por_bloco, que não existem mais). É idempotente: arquivos já
# migrados e peças comuns são ignorados. UIDs, formas e demais campos são preservados.

extends SceneTree

const PASTA: String = "res://entities/pecas"
const PASTA_EFEITOS: String = "res://entities/pecas/efeitos"
const FLAGS: Dictionary = {
	"cai_em_blocos_ao_travar": "efeito_areia.tres",
	"explode_ao_travar": "efeito_explosao.tres",
	"atravessa_blocos": "efeito_fantasma.tres",
	"eh_fragil": "efeito_vidro.tres",
}
const OBSOLETAS: Array[String] = ["atlas_por_estagio_de_dano", "resistencia_ao_peso_por_bloco"]
# nomes que sugerem um efeito (para avisar quando a flag correspondente não existe)
const PREFIXOS_SUSPEITOS: Dictionary = {
	"vidro": "efeito_vidro.tres", "areia": "efeito_areia.tres",
	"fantasma": "efeito_fantasma.tres", "bomba": "efeito_explosao.tres",
}


func _initialize():
	var simular: bool = "--simular" in OS.get_cmdline_user_args()
	var migradas: int = 0
	var avisos: int = 0
	
	for arquivo in DirAccess.get_files_at(PASTA):
		if not arquivo.ends_with(".tres"):
			continue
		var caminho: String = PASTA + "/" + arquivo
		var relatorio: Dictionary = _migrar(caminho, simular)
		if relatorio.is_empty():
			continue
		print("%-34s %s" % [arquivo, relatorio["status"]])
		for aviso in relatorio["avisos"]:
			print("    AVISO: " + aviso)
			avisos += 1
		if relatorio["migrada"]:
			migradas += 1
	
	print("--- %d arquivo(s) %s, %d aviso(s)%s" % [migradas, "a migrar" if simular else "migrado(s)", avisos, " (simulacao: nada foi gravado)" if simular else ""])
	quit(0)


# devolve {} se o arquivo nao e uma Peca
func _migrar(caminho: String, simular: bool) -> Dictionary:
	var texto: String = FileAccess.get_file_as_string(caminho)
	if not 'script_class="Peca"' in texto:
		return {}
	
	var avisos: Array[String] = []
	if "\nefeitos = " in texto:
		return {"status": "ja migrada", "avisos": avisos, "migrada": false}
	
	var efeitos: Array[String] = []
	var saida: PackedStringArray = []
	var removidas: int = 0
	var nome: String = ""
	var tipo: String = ""
	var tem_tabela_srs: bool = false
	var removeu_frames: bool = false
	
	for linha in texto.split("\n"):
		var chave: String = linha.get_slice(" = ", 0).strip_edges() if " = " in linha else ""
		var valor: String = linha.substr(linha.find(" = ") + 3).strip_edges() if " = " in linha else ""
		
		if FLAGS.has(chave):
			removidas += 1
			if valor == "true":
				efeitos.append(FLAGS[chave])
			continue
		if chave in OBSOLETAS:
			removidas += 1
			if chave == "atlas_por_estagio_de_dano":
				removeu_frames = true
			continue
		
		match chave:
			"nome": nome = valor.trim_prefix('"').trim_suffix('"')
			"tipo_peca": tipo = valor.trim_prefix('"').trim_suffix('"')
			"tabela_srs": tem_tabela_srs = true
		saida.append(linha)
	
	# a heuristica de nome so avisa, nunca altera
	for prefixo in PREFIXOS_SUSPEITOS:
		var arquivo_efeito: String = PREFIXOS_SUSPEITOS[prefixo]
		if nome.to_lower().begins_with(prefixo) or caminho.get_file().to_lower().contains(prefixo):
			if not arquivo_efeito in efeitos:
				avisos.append("o nome sugere %s, mas nao havia a flag correspondente. Se for um engano, adicione o efeito pelo inspetor." % arquivo_efeito)
	if removeu_frames:
		avisos.append("atlas_por_estagio_de_dano foi removido: os frames de rachadura agora ficam em efeitos/efeito_vidro.tres (compartilhados).")
	
	if removidas == 0:
		return {"status": "peca comum, nada a fazer", "avisos": avisos, "migrada": false}
	
	for arquivo_efeito in efeitos:
		if not FileAccess.file_exists(PASTA_EFEITOS + "/" + arquivo_efeito):
			return {"status": "ERRO: falta %s/%s" % [PASTA_EFEITOS, arquivo_efeito], "avisos": avisos, "migrada": false}
	
	if not efeitos.is_empty():
		_inserir_efeitos(saida, efeitos, tipo == "BOMBA" and not tem_tabela_srs)
	
	if not simular:
		var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
		arquivo.store_string("\n".join(saida))
		arquivo.close()
	
	var nomes: Array[String] = []
	for e in efeitos:
		nomes.append(e.get_basename())
	return {"status": "migrada -> [%s]" % ", ".join(nomes), "avisos": avisos, "migrada": true}


func _inserir_efeitos(linhas: PackedStringArray, efeitos: Array[String], definir_tabela_o: bool) -> void:
	var ultimo_ext: int = -1
	var indice_script: int = -1
	for i in range(linhas.size()):
		if linhas[i].begins_with("[ext_resource"):
			ultimo_ext = i
		if linhas[i].begins_with("script = ExtResource"):
			indice_script = i
	
	var ids: PackedStringArray = []
	var novas_ext: PackedStringArray = ['[ext_resource type="Script" path="%s/efeito_de_peca.gd" id="efeito_base"]' % PASTA_EFEITOS]
	for i in range(efeitos.size()):
		novas_ext.append('[ext_resource type="Resource" path="%s/%s" id="efeito_%d"]' % [PASTA_EFEITOS, efeitos[i], i + 1])
		ids.append('ExtResource("efeito_%d")' % (i + 1))
	
	# propriedades primeiro (indice maior), pra nao deslocar o indice das ext_resource
	var propriedades: PackedStringArray = ['efeitos = Array[ExtResource("efeito_base")]([%s])' % ", ".join(ids)]
	if definir_tabela_o:
		propriedades.append('tabela_srs = "O"')
	for j in range(propriedades.size() - 1, -1, -1):
		linhas.insert(indice_script + 1, propriedades[j])
	
	for j in range(novas_ext.size() - 1, -1, -1):
		linhas.insert(ultimo_ext + 1, novas_ext[j])
