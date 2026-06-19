extends Node3D

signal gamecard_filled

#Node Declaring
@onready var carousel : Path3D = $Carousel
@onready var camera_3d : Camera3D = $Camera3D
@onready var audio_player : AudioStreamPlayer3D = $"Audio Player"

#Arrays and dictionaries needed 
var games_to_add : Array = []
var game_displays : Array[GameDisplay3D] = []
var game_music_dictionary : Dictionary

#Variables controlling the carousel and cards on it
var moving_forward : bool = true
var carousel_dir : int = 1
var carousel_moving : bool = false
var game_chosen : bool = false

#Folder games are stored in
var target_folder = "res://Test Games/"

#Preload the big_display_preload
var big_display_preload := preload("res://Scenes and Code/Scenes/game_display_3d.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#When the screen loads, call the function that collects the game folders and sets them up as cards
	fill_array()
	
	#Just adds the game display nodes into the proper array for referral
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
	var target_folder_contents = DirAccess.get_directories_at(target_folder)
	var possible_game
	var game_file
	var thumbnail_file
	var info_file
	var music_file
	var index = 0
	
	#for game folders in the folder they should be in
	for game_folder in target_folder_contents:
		#Loop through the game folders to make sure it is a folder with a game in it
		possible_game = DirAccess.get_files_at(target_folder + game_folder)
		for file in possible_game:
			if file.get_extension() == "exe" or file.get_extension() == "apk":
				games_to_add.append(game_folder) #And add it to the array
	
	
	#Loop through the game folders again
	for game_folder in target_folder_contents:
		#and loop through the possible games
		possible_game = DirAccess.get_files_at(target_folder + game_folder)
		for file in possible_game:
			#and find what the file extension is, seting the file to the correct var
			match file.get_extension().to_lower():
				"exe":
					game_file = file
				"apk":
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
		
		#Call the function to create a game card when the files are collected
		create_gamecard(target_folder + game_folder + "/", game_file, thumbnail_file, music_file, info_file, index)
		#Reset the files and increment the index
		game_file = ""
		thumbnail_file = ""
		info_file = ""
		music_file = ""
		index += 1
	
	#Reorder the gamecards by date
	order_gamecards()

func create_gamecard(path, game, preview, music, info, game_number):
	#As long as there is a game
	if game != "":
		#Create a pathfollow to place the gamecard on
		var new_pathfollow = PathFollow3D.new()
		new_pathfollow.name = game
		carousel.add_child(new_pathfollow)
		
		#Load the card and name it
		var gamecard_instance = big_display_preload.instantiate()
		gamecard_instance.name = game.replace(".exe", "_3d_display")
		
		#And define the path to the game
		gamecard_instance.game_path = path + game
		
		#If there is an info file
		if info != "":
			#Open it and set the details as needed
			var info_file : ConfigFile = ConfigFile.new()
			print(path + info)
			info_file.load(path + info)
			
			gamecard_instance.game_name = info_file.get_value("Game", "name", gamecard_instance.game_name)
			gamecard_instance.month_made = info_file.get_value("Game", "month_made", gamecard_instance.month_made)
			gamecard_instance.year_made = info_file.get_value("Game", "year_made", gamecard_instance.year_made)
			gamecard_instance.is_2D = info_file.get_value("Game", "is_2d", gamecard_instance.is_2D)
			gamecard_instance.explainer = info_file.get_value("Game", "explainer", gamecard_instance.explainer)
		
		#If there is a preview image, set it correctly
		if preview != "":
			gamecard_instance.thumbnail = load(path + preview)
		
		#Same with music
		if music != "":
			game_music_dictionary.get_or_add(gamecard_instance.game_name, path + music)
		
		#Add the card after all the info has been correctly added
		new_pathfollow.add_child(gamecard_instance)
		gamecard_instance.connect("game_clicked", game_button_pressed)


func order_gamecards():
	var gamecards = []
	for pathfollows in carousel.get_children():
		#Add the gamecards to the array for easier looping and access
		gamecards.append(pathfollows.get_child(0))
	
	#sort them by year, and then month
	gamecards.sort_custom(func(a, b): 
		if a.year_made != b.year_made:
			return a.year_made < b.year_made
		return a.month_made < b.month_made)
	
	#And then correctly set the cards progress ratio
	var index = 0
	for card in gamecards:
		card.get_parent().progress_ratio = float(1) - float(float(index) / float(gamecards.size() + 1))
		index += 1
		print(card.name + " has a progress ratio of " + str(card.get_parent().progress_ratio))

#Function to tween the game cards
func progress_tweening(gamecard_progress):
	var tween = create_tween()
	#Create a new_progress variable for the gamecards to tween to
	var new_progress
	#We do this by setting it's value to:
	#the current progress plus the result of dividing 1 by the amount of game's on the list.  
	#We also multiply this by the carousel's direction of 1 or -1 to tell which direction the games should move
	new_progress = gamecard_progress.progress_ratio + ((1.0/(1 + game_displays.size())) * carousel_dir)
	
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
	tween.tween_property(gamecard_tweening, "global_position", camera_3d.global_position, 1.0)
	tween.tween_property(gamecard_tweening, "global_rotation", camera_3d.global_rotation, 1.0)
	await tween.finished
	
	gamecard_tweening.global_position = og_gc_gp
	gamecard_tweening.global_rotation = og_gc_gr

func game_button_pressed(game_chose):
	#Set pressed_button to the passed in chosen game
	#var pressed_button = game_chose
	#print(pressed_button)
	#for display in game_displays:
	#	if display.game_display.button_pressed:
	#		pressed_button = display.game_display
	
	#Set menu_in_3d to true in case it somehow wasn't
	game_menu_config.menu_in_3D = true
	
	await tween_to_camera(game_chose)
	
	#Match case to load the correct game
	#All cases are built the same so instead, the first comment under pressed button will instead be a template
#	match pressed_button.name:
#		#name of game card
#			#tween_to_camera(name of game card)
#			#change the scene to that of the chosen game
#		"pongalong_display_3d":
#			print("Pongalong matched")
#			await tween_to_camera(pongalong_display_3d)
#			#get_tree().change_scene_to_file("res://Games/Pongalong/Scenes/main.tscn")
#		comin_to_town_display_3d:
#			print("Comin to town matched")
#			await tween_to_camera(comin_to_town_display_3d)
#			#get_tree().change_scene_to_file("res://Games/Comin To Town/Scenes/main.tscn")
#		scoundrel_display_3d:
#			print("Scoundrel matched")
#			await tween_to_camera(scoundrel_display_3d)
#			#get_tree().change_scene_to_file("res://Games/Scoundrel/Scenes and Code/Scenes/main.tscn")
#		lamplighters_display_3d:
#			print("Lamplighters matched")
#			await tween_to_camera(lamplighters_display_3d)
#			#get_tree().change_scene_to_file("res://Games/Lamplighters/Scenes and Codes/Scenes/main.tscn")
#		hack_and_sketch_display_3d:
#			print("Hack and Sketch matched")
#			await tween_to_camera(hack_and_sketch_display_3d)
#			#get_tree().change_scene_to_file("res://Games/Hack and Sketch/Scenes/Main.tscn")
	
	create_big_display(game_chose)

func create_big_display(game_selected):
	print(game_selected, " pressed")
	#instantiate th preloaded big display
	var big_display = big_display_preload.instantiate()
	
	#Set the big display flag to true, and pass the needed info
	big_display.is_big_display = true
	big_display.game_name = game_selected.game_name
	big_display.month_made = game_selected.month_made
	big_display.year_made = game_selected.year_made
	big_display.is_2D = game_selected.is_2D
	big_display.thumbnail = game_selected.thumbnail
	big_display.explainer = game_selected.explainer
	big_display.game_path = game_selected.game_path 
	#big_display.look_at(camera_3d.global_position)
	display_br_music(big_display.game_name)
	#Add the display as a child of the camera
	add_child(big_display)
	
	#And set the position just a little infront of the cmaera
	#big_display.position = Vector3(0, 0, -0.62)
	big_display.position = Vector3(5.351638, 1.6321, 6.121825)
	
	big_display.look_at(camera_3d.global_position)
	big_display.rotate_object_local(Vector3.UP, PI)
	big_display.rotation_degrees.z -= 10
	#big_display.rotation = Vector3(28.2, -15.9, -10)
	#Then connect the signal telling us when the display is freed to the right function
	big_display.connect("display_freed", unchoose_game)

func unchoose_game():
	game_chosen = false #Set game_chosen to false so the games on the carousel look at the camera correctly again.
	audio_player.stop()


func display_br_music(game_name):
	if game_name in game_music_dictionary:
		audio_player.stream = load(game_music_dictionary[game_name])
		audio_player.play()
