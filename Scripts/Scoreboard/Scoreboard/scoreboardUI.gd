extends Node2D

@export var leaderboardControl : Control
@export var leaderboardVBox : Container
@export var scoreText: PackedScene

@export var nameMenu: NameMenu

var score := 0
signal go_to_menu

var highlightName: String

func _ready():
	leaderboardControl.hide()
	nameMenu.show()
	
	nameMenu.set_score(score)
	nameMenu.name_entered.connect(_on_name_entered)

func _on_name_entered():
	highlightName = nameMenu.nameLine.text
	nameMenu.hide()
	leaderboardControl.show()
	
	load_scores()

func load_scores():
	var file: FileAccess = FileAccess.open("user://scores.dat", FileAccess.READ)
	if file == null:
		print("couldnt read scores :(")
		return
	
	var text: String = file.get_as_text()
	var lines: PackedStringArray = text.split("\n")
	if lines.size() % 2 != 1:
		print("scores is weird, assuming empty file :(")
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
	
	for i in range(0, scores.size()):
		var instance = scoreText.instantiate()
		
		instance.rankText = ordinal(i + 1)
		instance.playerNameText = scores[i][0]
		instance.highlight = scores[i][0] == highlightName
		instance.scorePointsText = scores[i][1]
		
		leaderboardVBox.add_child(instance)

func sort(score1, score2):
	return score1[1].to_int() > score2[1].to_int()

func _on_home_button_pressed() -> void:
	go_to_menu.emit()

func ordinal(n: int) -> String:
	if n == 11 or n == 12 or n == 13:
		return str(n) + "th"  # special cases: 11th, 12th, 13th
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
		_: return str(n) + "th"

func _on_name_submit_button_pressed() -> void:
	nameMenu._on_name_submitted(nameMenu.nameLine.text)
