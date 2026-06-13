extends MeshInstance3D

@onready var moons_path: PathFollow3D = $Path3D/PathFollow3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speeeeeen() #Call the function to cause the earth to spin
	moon_orbit(moons_path) #Call the function that forces the moon to follow the travel pasth

#Function to spin the earth
func speeeeeen():
	#Create a tween to control the spin
	var tween = create_tween()
	
	#Bind the tween to the earth node, so if for any reason, the earth is deleted, the tween doesn't silently continue
	tween.bind_node(self)
	tween.set_loops(0) #Set the tween to loop infinitly
	tween.tween_property(self, "rotation_degrees", Vector3(0, 360, 0), 120) #Set the tween to rotate the earth in forms of degrees, doing a complete 360 on the y axis, over a period of 120 seconds or 2 minutes

#Function to control the moon's orbit
#Note: As the path, and it's children are linked to the earth, it actually also spins with the earth, making the orbit of the moon around the earth actually happen a bit faster then listed
func moon_orbit(moon_progress):
	#Create a tween to control the travel path
	var tween = create_tween()
	
	#Bind the node to the earth... though should probably change it to the moon
	tween.bind_node(self)
	tween.set_loops(0) #Make the tween loop infinitly
	tween.tween_property(moon_progress, "progress_ratio", 1.0, 45.0) #Have the moon progress (measured by ratio) through the full path, over the course of 45 seconds a loop

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
