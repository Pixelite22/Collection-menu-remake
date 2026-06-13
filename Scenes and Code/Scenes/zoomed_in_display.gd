extends Control
class_name BeegDisplay

#signal display_created(display_node)
#signal play_button_pressed(game_starting)
signal quit_pressed


@onready var texture_rect: TextureRect = $TextureRect
@onready var color_rect: ColorRect = $ColorRect
@onready var title_text: RichTextLabel = $"ColorRect/Title Text"
@onready var explainer_text: RichTextLabel = $"ColorRect/Explainer Text"
@onready var play: Button = $ColorRect/Play
@onready var quit: Button = $ColorRect/Quit

@export var display : Texture
@export var game_name : String
@export var month_made : int 
@export var year_made : int
@export var is_2D : bool

#Simply fills in the display
func fill_display():
	#Set the texture to the image in display
	texture_rect.texture = display
	#Set the title text to whether it is 2d, the games name, and the date it was made
	title_text.text = is_2d() + " - " + game_name + " - " + date_formatting()
	#Set the correct explainer text
	#explainer_text.text = explainers[game_name]

#Make the date look correct with months less then 10 still have double digits
func date_formatting():
	if month_made < 10: #If the month it was made is less then 10
		return "0" + str(month_made) + "/" + str(year_made) #return the date, with the month returned with a 0 added in the front
	else: #otherwise
		return str(month_made) + "/" + str(year_made) #Just return the correct date

#Repeat of the is it 2d function
func is_2d():
	#If it is 2D
	if is_2D:
		#Return the correct text
		return "2D"
	else: #otherwise
		return "3D" #return the correct text


func _on_quit_pressed() -> void:
	print("Back to menu Button Pressed")
	var tween = create_tween() #create a tween
	
	#fade the display out
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)
	await tween.finished
	
	queue_free() #before deleting it
	quit_pressed.emit()
