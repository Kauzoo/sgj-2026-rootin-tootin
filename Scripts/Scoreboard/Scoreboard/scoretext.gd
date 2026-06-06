extends Container

var rankText: String
var playerNameText: String
var scorePointsText: String

@export var rank_label: Label
@export var name_label: Label
@export var score_label: Label

func _ready():
	rank_label.text = rankText
	name_label.text = playerNameText
	score_label.text = scorePointsText
