extends Control

#Declaring Members of the scene for reference
@onready var menu_contents : Node = $"Menu Contents"
@onready var color_rect: ColorRect = $"Menu Contents/ColorRect"
@onready var buttons : Control = $"Menu Contents/Buttons"
@onready var audio_player: AudioStreamPlayer2D = $"Menu Contents/Audio Player"

var scene : Dictionary

var game_selected := false

var small_display_preload = preload("res://Scenes and Code/Scenes/game_display.tscn")
var zoomed_in_display_load = preload("res://Scenes and Code/Scenes/zoomed_in_display.tscn")

var target_folder = "res://Test Games/"

#Arrays and dictionaries needed 
var games_to_add : Array = []
var game_displays : Array[GameDisplay3D] = []
var game_music_dictionary : Dictionary
var hbox_dictionary : Dictionary
var hbox_index : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_array()
	
	connect_buttons()
	#child_entered_tree.connect(_on_child_entered_tree)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#If the player want's to switch the menu from 2d to 3d
	if Input.is_action_just_pressed("Menu Switch"):
		game_menu_config.menu_in_3D = true #Set the flag of menu being in 3d to true, as it is now
		get_tree().change_scene_to_file("res://Scenes and Code/Scenes/collection_menu_3d.tscn") #Switch the scene to the 3d menu

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
		if game_file != "":
			index += 1
		game_file = ""
		thumbnail_file = ""
		info_file = ""
		music_file = ""
	
	#Reorder the gamecards by date
#	order_gamecards()

func create_gamecard(path, game, preview, music, info, game_number):
	#As long as there is a game
	if game != "":
		
		if (float(game_number % 3) == 0):
			var new_hbox = HBoxContainer.new()
			hbox_index += 1
			hbox_dictionary.get_or_add(hbox_index, new_hbox)
			buttons.v_box_container.add_child(new_hbox)
		
		#Load the card and name it
		var gamecard_instance = small_display_preload.instantiate()
		gamecard_instance.name = game.replace(".exe", "_display")
		
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
			gamecard_instance.texture_normal = gamecard_instance.thumbnail
			print("Thumbnail for " + str(gamecard_instance) + " loaded at " + path + preview)
		
		#Same with music
		if music != "":
			game_music_dictionary.get_or_add(gamecard_instance.game_name, path + music)
			print("Music for " + str(gamecard_instance) + " loaded")
		
		#Add the card after all the info has been correctly added
		hbox_dictionary[hbox_index].add_child(gamecard_instance)
		#gamecard_instance.connect("game_clicked", game_button_pressed)
		
		space_games()

#This function spaces the games to not be ontop of each other
func space_games():
	#Declare variables to hold important values
	var game_amt = 0
	var box_amt = 0
	var card_size
	
	#For the hbox containers within the vbox container
	for hbox in buttons.v_box_container.get_children():
		#For the game cards within the currently targeted hbox
		for card in hbox.get_children():
			#Increment the game amount variable, 
			game_amt += 1
			#and find the custom minimum size of the card
			#note this could have been found only once but it seemed easier with my current set up to just take it each time as they will be the same
			card_size = card.custom_minimum_size
		#Now back to focusing on the hbox,
		#We add the seperation override, seperating the game cards horizontally by finding how many game cards there are, and dividing the size of the background by that.
		#Then we subtract the size of the game cards to avoid over seperation
		hbox.add_theme_constant_override("separation", ((int(color_rect.size.x) / game_amt) - (card_size.x)))
		#Reset the game amount so the next hbox doesn't get ruined
		game_amt = 0
		#And increment the box amount
		box_amt += 1
	
	#Now back to focusing on the vbox
	#Seperate the hboxes within similarly to the games in the vboxes
	#but now divide the vertical height of the backgound by the hbox amounts, again subtracting the game card y dimension
	buttons.v_box_container.add_theme_constant_override("separation", ((int(color_rect.size.y) / box_amt) - (card_size.y)))

#func order_gamecards():
#	var gamecards = []
#	for pathfollow in carousel.get_children():
#		#Add the gamecards to the array for easier looping and access
#		gamecards.append(pathfollows.get_child(0))
#	
#	#sort them by year, and then month
#	gamecards.sort_custom(func(a, b): 
#		if a.year_made != b.year_made:
#			return a.year_made < b.year_made
#		return a.month_made < b.month_made)
#	
#	#And then correctly set the cards progress ratio
#	var index = 0
#	for card in gamecards:
#		card.get_parent().progress_ratio = float(1) - float(float(index) / float(gamecards.size() + 1))
#		index += 1
#		print(card.name + " has a progress ratio of " + str(card.get_parent().progress_ratio))


func connect_buttons():
	#Loop through all the burrons in the button node and connect the pressed signal
	for hbox in hbox_dictionary.values():
		for cards in hbox.get_children():
			cards.pressed.connect(game_button_pressed)
			if cards.pressed.is_connected(game_button_pressed):
				print("pressed connected for " + str(cards))
			else:
				print("pressed not connected for " + str(cards))


#called when a game display button is pressed
func game_button_pressed():
	print("button pressed called")
	var pressed_card #declare pressed button
	var new_control = Control.new()
	var game_num = 0
	
	#Check all buttons to see which is being pressed
	for hbox in hbox_dictionary.values():
		hbox.add_child(new_control)
		for card in hbox.get_children():
			if (card is TextureButton):
				if card.button_pressed: #if the button being checked is being pressed
					hbox.move_child(new_control, game_num)
					print(card.name)
					pressed_card = card #set the button being pressed to the pressed button variable
				game_num += 1
	
	pressed_card.reparent(new_control)
	game_selected = true
	zoomed_in_spawn(pressed_card)


#Called when a button is pressed, passing in the display that needs to be zoomed
func zoomed_in_spawn(display_zoomed):
	var zoomed_display #declare a variable for zoomed_display
	zoomed_display = zoomed_in_display_load.instantiate() #instantiate the preloaded scene
	zoomed_display.position = Vector2(0, 0) #Set the position of the zoomed display to (0, 0)
	
	zoomed_display.set_deferred("custom_minimum_size", display_zoomed.size) #set it's minimum size to the size of the small display
	menu_contents.add_child(zoomed_display) #and then add it to the scene, under the correct part of the tree
	
	#Set the variables on the new large display to the selected small displays variables
	zoomed_display.game_name = display_zoomed.game_name
	zoomed_display.month_made = display_zoomed.month_made
	zoomed_display.year_made = display_zoomed.year_made
	zoomed_display.is_2D = display_zoomed.is_2D
	zoomed_display.display = display_zoomed.texture_normal
	
	#Set the display to clear
	zoomed_display.modulate = Color(1, 1, 1, 0)
	#call the fill display function on the zoomed display so it will display the new sets
	zoomed_display.call_deferred("fill_display")
	zoomed_display.quit_pressed.connect(self.big_display_exit_handle)
	#And finally call tween_display to allow the display to actually move it as desired
	call_deferred("tween_display", display_zoomed, zoomed_display)
	
	display_br_music(zoomed_display.game_name)


#Function to tween the displays as needed
func tween_display(small_display, big_display):
	#Ensure the displays are in the correct order so the smaller displays don't end up overlapping the chosen ones
	small_display.move_to_front()
	small_display.get_parent()
	big_display.move_to_front()
	
	#Declare variables to memorize the sizes and positions of the small display, so it can be reset after the tween
	var sds = small_display.size
	var sdcms = small_display.custom_minimum_size
	var sdgp = small_display.global_position
	
	var tween = create_tween() #create the tween
	tween.set_parallel(true) #Set parallel to true to allow the tweens to happen simultaneously
	tween.tween_property(small_display, "custom_minimum_size", Vector2(get_window().size), 1.5) #Tween the minimum size from current to the size of the game window in 1.5 seconds
	tween.tween_property(small_display, "global_position", Vector2(0, 0), 1.5) #Tween the global position from current to (0, 0) aka the center of the screen in this case in 1.5 seconds
	
	#End the parallel... which seems to not be working.  Need to research tween interactions more
	tween.set_parallel(false)
	tween.tween_interval(0.25) # wait for the parallel block to finish
	
	#Tween the big display from clear to opaque
	tween.tween_property(big_display, "modulate", Color(1, 1, 1, 1), 1)
	
	await tween.finished #Wait for the tween to finish and then
	#Set the small display to the memorized variables from earlier
	small_display.custom_minimum_size = sdcms 
	small_display.size = sds
	#small_display.global_position = sdgp
	small_display.position = sdgp#sdgp


#When a child node enters the tree
#func _on_child_entered_tree(node: Node) -> void:
#	print("On child entered tree called")
#	var selected_node
#	#If the node is a beegdisplay
#	if node is BeegDisplay:
#		for flag in game_signals:
#			if flag:
#				var selected_game = str(flag.name).replace("_selected", "")
#				selected_game += "_display" #now selected game is game_display
#				selected_node = get_node("Menu Contents/Buttons/" + selected_game)

func display_br_music(game_name):
	audio_player.stream = load(game_music_dictionary[game_name])
	
	audio_player.play()

func big_display_exit_handle():
	print("Big display exit handling reached")
	audio_player.stop()
	
	game_selected = false
