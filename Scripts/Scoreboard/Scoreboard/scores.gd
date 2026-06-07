extends Control

@export var Scoretext: PackedScene


func _ready() -> void:
	load_scores()


func load_scores() -> void:
	if Scoretext == null:
		print("score text scene is missing :(")
		return

	var file := FileAccess.open("user://scores.dat", FileAccess.READ)
	if file == null:
		print("couldnt read scores :(")
		return

	var lines := file.get_as_text().split("\n")
	if lines.size() % 2 != 1:
		print("scores is weird, assuming empty file :(")
		lines = [""]

	var scores := []
	for i in range(int(lines.size() / 2.0)):
		scores.append([lines[2 * i], lines[2 * i + 1]])

	scores.sort_custom(_sort_scores)

	for i in range(scores.size()):
		var instance = Scoretext.instantiate()
		instance.rankText = _ordinal(i + 1)
		instance.playerNameText = scores[i][0]
		instance.scorePointsText = scores[i][1]
		add_child(instance)


func _sort_scores(score1, score2) -> bool:
	return score1[1].to_int() > score2[1].to_int()


func _ordinal(n: int) -> String:
	if n == 11 or n == 12 or n == 13:
		return str(n) + "th"

	match n % 10:
		1:
			return str(n) + "st"
		2:
			return str(n) + "nd"
		3:
			return str(n) + "rd"
		_:
			return str(n) + "th"
