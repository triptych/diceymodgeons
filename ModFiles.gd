extends Node

enum Origin {
	GAME,
	MOD
}

var game_root_path = ""
var mod_root_path = ""

func _init():
	game_root_path = "res://test"
	mod_root_path = "mods/garfield"

func get_file_list():
	pass
	
func get_file_as_text(file_path:String):
	var file = _get_file(file_path)
	if file:
		var result = file.file.get_as_text()
		file.file.close()
		return {"text": result, "path": file.path, "origin": file.origin}
	
	return null
	
func _get_file(file_path:String):
	var mod_path = '%s/%s/%s' % [game_root_path, mod_root_path, file_path]
	var game_path = '%s/%s' % [game_root_path, file_path]
	
	var file := File.new()
	if file.open(mod_path, File.READ) == OK:
		return {"file": file, "path": mod_path, "origin": Origin.MOD}
	elif file.open(game_path, File.READ) == OK:
		return {"file": file, "path": game_path, "origin": Origin.GAME}
	
	return null