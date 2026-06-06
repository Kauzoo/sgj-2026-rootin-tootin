class_name Scores extends Control

@export var Scoretext: PackedScene

func _ready():
	var file: FileAccess = FileAccess.open("user://scores.dat", FileAccess.READ)
	if file == null:
		print("couldnt read scores :(")
	
	var text: String = file.get_as_text()
	var lines: PackedStringArray = text.split("\n")
	if lines.size() % 2 != 1:
		print("scores is wierd, assuming empty file :(")
		lines = [""]

	var scores = []
	for i in range(floor(lines.size() / 2.)):
		scores.append([lines[2 * i], lines[2 * i + 1]])
	print(scores)
	print(scores[scores.size() - 2][1].to_int())
	print(scores[scores.size() - 1][1].to_int())
	scores.sort_custom(sort)
	print("SORTED:")
	print(scores)
	var instance: Node = Scoretext.instantiate()
	instance.text = "RANK 		NAME 		SCORE"
	add_child(instance)
	for i in range(0, scores.size()):
		instance = Scoretext.instantiate()
		instance.text = scores[i][0] + " with score " + scores[i][1]
		instance.position.y = i * 30 + 30
		add_child(instance)

func sort(score1, score2):
	return score1[1].to_int() > score2[1].to_int()
