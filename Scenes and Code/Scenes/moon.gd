extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speeeeeen() #call speeeeeen

func speeeeeen():
	var tween = create_tween()
	
	tween.bind_node(self) #Bind tween to node to allow for it's ending if the node is removed
	tween.set_loops(0) #Loop infintely
	tween.tween_property(self, "rotation_degrees", Vector3(0, 360, 0), 30) #Tween the rotation for a full spin on the y axis over a period of 30 seconds
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
