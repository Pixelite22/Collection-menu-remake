extends Node3D
class_name GameDisplay3D

signal game_clicked(Node3D)
signal display_freed

@export var game_name : String = "default"
@export var month_made : int = 9
@export var year_made : int = 1998
@export var is_2D : bool = true
@export var thumbnail : Texture2D
@export var explainer : String
var is_big_display = false

@onready var sub_viewport: SubViewport = $SubViewport
@onready var control: Control = $SubViewport/Control
@onready var game_display: TextureButton = $"SubViewport/Control/Game Display"

var game_path

func _ready() -> void:
	pass
	if game_name != "":
		setup()

func setup():
	#Check if the display is a big display and 
	if is_big_display: #if it is
		change_game_display() #run the change display function
	else: #if it isn't
		#pass the needed info
		print(game_display.get_script())
		game_display.game_name = game_name
		game_display.month_made = month_made
		game_display.year_made = year_made
		game_display.is_2D = is_2D
		game_display.texture_normal = thumbnail
		print("Game path (via setup is): " + game_path)
		game_display.game_path = game_path
		#set the info and make it float
		game_display.set_title()
		floating_in_space()

func change_game_display():
	control.queue_free() #delete the control node within the subviewport
	
	var big_game_display_load = load("res://Scenes and Code/Scenes/zoomed_in_display.tscn") #load in the big display
	
	#instantiate it and pass the info
	var big_game_display = big_game_display_load.instantiate()
	big_game_display.game_name = game_name
	big_game_display.month_made = month_made
	big_game_display.year_made = year_made
	big_game_display.is_2D = is_2D
	big_game_display.explainer = explainer
	big_game_display.display = thumbnail
	print("Game path (via vhange_game_display is): " + game_path)
	big_game_display.game_path = game_path
	
	#change the input handling so it works and the size so it displays correctly
	sub_viewport.handle_input_locally = true
	sub_viewport.size = Vector2(1152, 648)
	#add the child to the viewport
	sub_viewport.add_child(big_game_display)
	#and fill the display
	big_game_display.fill_display()
	
	
	#then connect the signals to the functions as necissary
	big_game_display.play.pressed.connect(_play_button_pressed)
	big_game_display.quit.pressed.connect(_quit_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#Function to emulate the movement of floating in space
func floating_in_space():
	var tween = create_tween()
	
	#Set the top and bottom possible heights the cards can float between
	var top_float = position + Vector3(0.0, 0.05, 0.0)
	var bottom_float = position - Vector3(0.0, 0.05, 0.0)
	
	tween.bind_node(self) #Bind the node to the game cards so if they are cleared then the tween ends
	tween.set_loops(0) #Set the tweens to loop for infinity
	tween.tween_property(self, "position", top_float, randf_range(2.5, 3.5)) #Tween the card to the top positino, over a random period of 2 and a half to 3 and a half seconds
	tween.tween_property(self, "position", bottom_float, randf_range(2.5, 3.5)) #Tween the card to the bottom positino, over a random period of 2 and a half to 3 and a half seconds

#Handles clicks on the card
func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	sub_viewport.push_input(event)
	if (event is InputEventMouseButton and event.pressed) and not is_big_display: #if a card is clicked on
		game_clicked.emit(self) #emit the click signal

func _play_button_pressed():
	pass

func _quit_button_pressed():
	#var tween = create_tween() #create a tween
	
	#fade the display out
	#tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)
	#await tween.finished
	display_freed.emit()
	queue_free() #before deleting it
