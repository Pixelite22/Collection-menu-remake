extends Node3D

signal gamecard_filled

@onready var carousel : Path3D = $Carousel
@onready var camera_3d : Camera3D = $Camera3D
@onready var audio_player : AudioStreamPlayer3D = $"Audio Player"

var games_to_add : Array = []
var game_displays : Array[GameDisplay3D] = []

var moving_forward : bool = true
var carousel_dir : int = 1
var carousel_moving : bool = false
var game_chosen : bool = false

var big_display_preload := preload("res://Scenes and Code/Scenes/game_display_3d.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_array()
	
	for paths in carousel.get_children():
		if paths.get_child(0) is GameDisplay3D:
			game_displays.append(paths.get_child(0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#If we press the next button and the carousel isn't currently moving
	if Input.is_action_just_pressed("Next") and not carousel_moving:
		#Set the carousel movement to true
		carousel_moving = true
		#If it isn't moving forward
		if not moving_forward:
			#Set the direction to the opposite of whatever it currently is
			carousel_dir *= -1
			#and set moving forward to true
			moving_forward = true
		#for the progress of each display in the carousel
		for gamecard_progress in carousel.get_children():
			#Tween the displays to the correct position
			progress_tweening(gamecard_progress)
	
	#Repeat above but for previous, letting the menu move backwards through slight changes to the moving forward bool
	if Input.is_action_just_pressed("Prev") and not carousel_moving:
		carousel_moving = true
		if moving_forward:
			carousel_dir *= -1
			moving_forward = false
		for gamecard_progress in carousel.get_children():
			progress_tweening(gamecard_progress)
	
	#if we want to switch back to the 2d menu
	if Input.is_action_just_pressed("Menu Switch"):
		#Set the menu in 3d flag to false in the gameMenuConfig global script
		game_menu_config.menu_in_3D = false
		#change the current scene to the 2d menu scene
		get_tree().change_scene_to_file("res://Scenes and Code/Scenes/collection_menu.tscn")
	
	if not game_chosen:
		#for each display in the game display array
		for display in game_displays:
			#Force the display to look at the camera's global position at all times
			display.look_at(camera_3d.global_position)
			#rotating something by pi is equivalent of rotating it 180 degrees so I am sure that is what it is
			display.rotate_object_local(Vector3.UP, PI)
		#game_display_3d.rotation = Vector3(camera_3d.rotation.x, camera_3d.rotation.y + 180, camera_3d.rotation.z)


func fill_array():
	#Change this variable when time to export to the file structure we are setting up
	var target_folder = "res://Test Games/"
	var target_folder_contents = DirAccess.get_directories_at(target_folder)
	var possible_game
	var game_file
	var thumbnail_file
	var info_file
	var music_file
	var index = 0
	
	for game_folder in target_folder_contents:
		possible_game = DirAccess.get_files_at(target_folder + game_folder)
		for file in possible_game:
			if file.get_extension() == "exe" or file.get_extension() == "apk" or file.get_extension() == "txt":
				games_to_add.append(game_folder)
				print(game_folder)
	
	
	
	for game_folder in target_folder_contents:
		possible_game = DirAccess.get_files_at(target_folder + game_folder)
		for file in possible_game:
			match file.get_extension().to_lower():
				"exe":
					game_file = file
				"png":
					thumbnail_file = file
				"webp":
					thumbnail_file = file
				"jpg":
					thumbnail_file = file
				"jpeg":
					thumbnail_file = file
				"ogg":
					music_file = file
				"wav":
					music_file = file
				"mp3":
					music_file = file
				"txt":
					info_file = file
				"cfg":
					info_file = file
				
		
		
		create_gamecard(target_folder + game_folder + "/", game_file, thumbnail_file, music_file, info_file, index)
		game_file = ""
		thumbnail_file = ""
		info_file = ""
		music_file = ""
		index += 1

func create_gamecard(path, game, preview, music, info, game_number):
	if game != "":
		var new_pathfollow = PathFollow3D.new()
		new_pathfollow.name = game
		carousel.add_child(new_pathfollow)
		new_pathfollow.progress_ratio = float(float(game_number) / float(games_to_add.size()))
		
		
		var gamecard_instance = big_display_preload.instantiate()
		gamecard_instance.name = game
		
		if info != "":
			var info_file : ConfigFile = ConfigFile.new()
			print(path + info)
			info_file.load(path + info)
			
			gamecard_instance.game_name = info_file.get_value("Game", "name", gamecard_instance.game_name)
			gamecard_instance.month_made = info_file.get_value("Game", "month_made", gamecard_instance.month_made)
			gamecard_instance.year_made = info_file.get_value("Game", "year_made", gamecard_instance.year_made)
			gamecard_instance.is_2D = info_file.get_value("Game", "is_2d", gamecard_instance.is_2D)
		
		if preview != "":
			gamecard_instance.thumbnail = load(path + preview)
		
		if music != "":
			pass
		
		new_pathfollow.add_child(gamecard_instance)

#Function to tween the game cards
func progress_tweening(gamecard_progress):
	var tween = create_tween()
	#Create a new_progress variable for the gamecards to tween to
	var new_progress
	#We do this by setting it's value to:
	#the current progress plus the result of dividing 1 by the amount of game's on the list.  
	#We also multiply this by the carousel's direction of 1 or -1 to tell which direction the games should move
	new_progress = gamecard_progress.progress_ratio + ((1.0/game_displays.size()) * carousel_dir)
	
	#Now we simply set the tween property to tween the passed card's progress ratio to the new target over the span of one second
	tween.tween_property(gamecard_progress, "progress_ratio", new_progress, 1.0)
	#we wait for the tween to finish
	await tween.finished
	#And then set carousel moving to false
	carousel_moving = false

#I believe this is currently not working but meant to tween the postion of the card, to the camera, to look like the game is coming at you, before loading you in
func tween_to_camera(gamecard_tweening):
	var og_gc_gp = gamecard_tweening.global_position
	var og_gc_gr = gamecard_tweening.global_rotation
	
	var tween = create_tween()
	game_chosen = true
	tween.set_parallel(true)
	tween.tween_property(gamecard_tweening, "global_position", camera_3d.global_position + Vector3(1, 0, 0), 1.0)
	tween.tween_property(gamecard_tweening, "global_rotation", camera_3d.global_rotation, 1.0)
	await tween.finished
	
	gamecard_tweening.global_position = og_gc_gp
	gamecard_tweening.global_rotation = og_gc_gr
