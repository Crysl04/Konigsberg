extends Label

var full_text := "The Königsberg Challenge"
var speed := 0.05   # seconds per character
var index := 0

func _ready():
	text = ""
	reveal_next_letter()

func reveal_next_letter():
	if index < full_text.length():
		text += full_text[index]
		index += 1
		await get_tree().create_timer(speed).timeout
		reveal_next_letter()
	else:
		# Pause a little at the end
		await get_tree().create_timer(1.0).timeout
		# Reset for repeating
		text = ""
		index = 0
		reveal_next_letter()
