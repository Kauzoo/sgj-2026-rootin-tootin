class_name NameMenu extends Node2D

#set before added as child
var score: int

signal name_entered()

func _ready():
	$NameLine.text_submitted.connect(_on_name_submitted)

func set_score(score_set):
	score = score_set
	$ScoreLabel.text = "you got a score of " + String.num_uint64(score) + " HURRAY!!!!(now give us your name)"

func _on_name_submitted(submittedName: String):
#always fails for some reason...
#if not ResourceLoader.exists("user://scores.dat") :
# #makes empty file ?
#FileAccess.open("user://scores.dat", FileAccess.WRITE).close()
#print("it does not exist")


	var file: FileAccess = FileAccess.open("user://scores.dat", FileAccess.READ)
	if file == null:
		if FileAccess.get_open_error() == ERR_FILE_NOT_FOUND:
			FileAccess.open("user://scores.dat", FileAccess.WRITE).close()
			file = FileAccess.open("user://scores.dat", FileAccess.READ)
		else:
			print("couldnt save name :(")
			name_entered.emit()
			return

	var string: String = file.get_as_text()
	var lines: PackedStringArray = string.split("\n")
	if lines.size() % 2 != 1:
		print("scores is wierd, assuming empty file :(")
		lines = [""]

	var scores: Dictionary[String, String] = {}
	for i in range(floor(lines.size() / 2.)):
		scores.set(lines[2 * i], lines[2 * i + 1])

	if scores.has(submittedName) && scores[submittedName].to_int() > score:
		file.close()
		return

	scores.set(submittedName, str(score))

	var resultString: String = ""
	for scoreName in scores:
		resultString += scoreName + "\n" + scores[scoreName] + "\n"

	file.close()
	file = FileAccess.open("user://scores.dat", FileAccess.WRITE)
	file.store_string(resultString)
	file.close()

	name_entered.emit()
