extends Node

var player: Player = null
var seed_value = ''
var timer = 0
var timer_running = false
var rng = null
var goal_reached = false

var cursor_default = load("res://assets/cursor.png")
var cursor_crosshair = load("res://assets/crosshair.png")

enum CursorType
{
	DEFAULT,
	CROSSHAIR
}

func _ready():
	set_cursor(CursorType.DEFAULT)
	rng = RandomNumberGenerator.new()
	GlobalSignals.connect("player_dead", on_player_dead)

func register_player(player_node):
	player = player_node

func start_timer():
	timer_running = true
	
func stop_timer():
	timer_running = false

func _process(delta):
	if timer_running:
		timer += delta
		
func on_player_dead():
	stop_timer()

func set_cursor(cursor: CursorType):
	if cursor == CursorType.DEFAULT:
		Input.set_custom_mouse_cursor(cursor_default, 0, Vector2(64, 64))
	else:
		Input.set_custom_mouse_cursor(cursor_crosshair, 0, Vector2(64, 64))
		
