extends Container

var rankText: String
var playerNameText: String
var scorePointsText: String
var highlight: bool = false  # set this before add_child

@export var rank_label: Label
@export var name_label: Label
@export var score_label: Label
@export var highlight_color: Color = Color.YELLOW

func _ready():
	rank_label.text = rankText
	name_label.text = playerNameText
	score_label.text = scorePointsText
	if highlight:
		rank_label.add_theme_color_override("font_color", highlight_color)
		name_label.add_theme_color_override("font_color", highlight_color)
		score_label.add_theme_color_override("font_color", highlight_color)
