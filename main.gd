extends Node2D

@onready var _MainWindow: Window = get_window()
@onready var char_sprite: AnimatedSprite2D = $Character/AnimatedSprite2D
@onready var emitter: CPUParticles2D = $Character/CPUParticles2D

var player_size: Vector2i = Vector2i(100,104)
#The offset between the mouse and the character
var mouse_offset: Vector2 = Vector2.ZERO
var selected: bool = false
#This will be the position of the pet above the taskbar
var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(0)
var taskbar_pos: int = screen_rect.end.y - player_size.y
var screen_width: int = screen_rect.end.x
var screen_offset: int = screen_rect.position.x
#If true the character will move
var is_walking: bool = false
var walk_direction: int = 1
#Character walk speed
const WALK_SPEED = 150
var current_display: int = 0

func _ready():
	var args = OS.get_cmdline_user_args()
	
	for i in range(args.size()):
		if args[i] == "--display" and i + 1 < args.size():
			current_display = int(args[i + 1])
	
	# Update screen rect based on selected display
	screen_rect = DisplayServer.screen_get_usable_rect(current_display)
	taskbar_pos = screen_rect.end.y - player_size.y
	screen_width = screen_rect.end.x
	screen_offset = screen_rect.position.x
	
	#Change the size of the window
	_MainWindow.min_size = player_size
	_MainWindow.size = _MainWindow.min_size
	#Places the character in the middle of the screen and on top of the taskbar
	_MainWindow.position = Vector2i(screen_offset + screen_rect.size.x/2 - player_size.x/2, taskbar_pos)

func _process(delta):
	if selected:
		follow_mouse()
	if is_walking:
		walk(delta)
	move_pet()
	#emit heart particles when petted
	if Input.is_action_just_pressed("pet"):
		emitter.emitting = true

func follow_mouse():
	#Follows mouse cursor but clamps it on the taskbar
	_MainWindow.position = Vector2i(clamp_on_screen_width((get_global_mouse_position().x 
		 + mouse_offset.x),
		 player_size.x), taskbar_pos) 

func move_pet():
	#On right click and hold it will follow the pet and when released
	#it will stop following
	if Input.is_action_pressed("move"):
		selected = true
		mouse_offset = _MainWindow.position - Vector2i(get_global_mouse_position()) 
	if Input.is_action_just_released("move"):
		selected = false

func clamp_on_screen_width(pos, player_width):
	return clampi(pos, screen_offset, screen_width - player_width)

func walk(delta):
	#Moves the pet
	_MainWindow.position.x = _MainWindow.position.x + WALK_SPEED * delta * walk_direction
	#Clamps the pet position on the width of screen
	_MainWindow.position.x = clampi(_MainWindow.position.x, screen_offset
			,clamp_on_screen_width(_MainWindow.position.x, player_size.x))
	#Changes direction if it hits the sides of the screen
	if ((_MainWindow.position.x == (screen_width - player_size.x)) or (_MainWindow.position.x == screen_offset)):
		walk_direction = walk_direction * -1
		char_sprite.flip_h = !char_sprite.flip_h

func choose_direction():
	if (randi_range(1,2) == 1):
		walk_direction = 1
		char_sprite.flip_h = false
	else:
		walk_direction = -1
		char_sprite.flip_h = true

func _on_character_walking():
	is_walking = true
	choose_direction()

func _on_character_finished_walking():
	is_walking = false
