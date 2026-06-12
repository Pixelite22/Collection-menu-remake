extends TextureButton



@export var game_name : String
@export var month_made : int 
@export var year_made : int
@export var is_2D : bool

@onready var title: Label = $ColorRect/Title

func _ready() -> void:
	set_title()

#Function sets title for the game display
func set_title():
	var title_text : String
	
	title_text = game_name #Set the title text to the game's name
	
	#Set title text to the name, whether it is 2d or 3d, and the month and year it was made
	if month_made < 10:
		title_text += "\n" + is_game_2d() + " - 0" + str(month_made) + "/" + str(year_made)
	else:
		title_text += "\n" + is_game_2d() + " - " + str(month_made) + "/" + str(year_made)
	
	title.text = title_text

#Function simply returns the correct text based on if a game is 2d or 3d
func is_game_2d():
	if is_2D: #If the game is marked as 2D
		return "2D" #Return the 2D text
	if not is_2D: #If it isn't marked as 2D
		return "3D" #Return 3D text
