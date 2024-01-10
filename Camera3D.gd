extends Camera3D

# Cam Movement vars
@export var cam_lerpspeed = .05
@export var cam_z_offset = 10
const CAM_Z_OFFSET = 10
@export var cam_y_offset = 3.7
@export var cam_x_offset = 0

# Temporary Grab Mechanic vars
@export var cam_target: Node3D
var is_grabbed = false
var grabbed_object = null
var grab_offset: Vector3 = Vector3(0, 0, 0)
var grab_ray_pos: Vector3 = Vector3(0, 0, 0)

# Raycast 1: Grab var
var grab_target = null

# Raycast 2: Hover-Player var
var hover_target = null


func _ready():	
# Temp Grab setup
	Messenger.health_grabbed.connect(move_health)
	
func _physics_process(_delta):
	# Camera Follow input control
	var input_up = Input.is_action_pressed("ui_up")
	var input_up_end = Input.is_action_just_released("ui_up")
	if input_up and cam_z_offset == CAM_Z_OFFSET:
		cam_z_offset += .75
	if input_up_end and cam_z_offset >= CAM_Z_OFFSET:
		cam_z_offset -= .75
	
	var cam_follow_pos: Vector3 = cam_target.position
	cam_follow_pos.z += cam_z_offset
	cam_follow_pos.y += cam_y_offset
	cam_follow_pos.x += cam_x_offset
	
	# Camera Follow Normalize
	var cam_direction: Vector3 = cam_follow_pos - self.position
	
	self.position += cam_direction * cam_lerpspeed
	self.rotation = cam_target.rotation

func _process(_delta):
	# Raycast 1: Grab implementation
	shoot_grab_ray()
	
	var new_grab_target = shoot_grab_ray()
	# Raycast 2: Hover implementation
	shoot_hover_ray()
	
	# Raycaast 1: Temp Grab-specific
	Messenger.object_hovered.emit(new_grab_target)
#	print(grab_target)
	print(hover_target)

# Raycast 1: Grab hovering
func shoot_grab_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 3000
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = false
	ray_query.collision_mask = 1
	
	var raycast_result = space.intersect_ray(ray_query)
	
	# Raycast 1: Grab position info
	if raycast_result.has("position"):
		grab_ray_pos = raycast_result.position

	# Raycast 1: Collision info
	if raycast_result.has("collider"):
		grab_target = raycast_result.collider
		return raycast_result.collider

# Raycast 1: Temp grab application
func move_health(grab_state):
	is_grabbed = grab_state

	if is_grabbed:
		if grabbed_object == null:
			grabbed_object = grab_target  # Store the grabbed object
			grab_offset = grabbed_object.global_transform.origin - grab_ray_pos  # Calculate grab offset

		if grabbed_object != null:
			grabbed_object.set_global_position(grab_ray_pos + grab_offset)


# Raycast 2: Player Hovering
func shoot_hover_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 3000
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	ray_query.collision_mask = 1
	
	var raycast_result = space.intersect_ray(ray_query)

# Raycast 2: Collision info
	if raycast_result.has("collider"):
		hover_target = raycast_result.collider
		return raycast_result.collider
