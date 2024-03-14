extends CanvasLayer

@export_file("*.tscn") var main_menu_scene

@onready var options_menu = $OptionsMenu
@onready var pickup_container = $MarginContainer/VBoxContainer/PickupContainer
@onready var pickup_label = $MarginContainer/VBoxContainer/PickupContainer/HBoxContainer/PanelContainer/MarginContainer/PickupLabel
@onready var err_sound = $ErrSound

@onready var ability_a_label = $MarginContainer/VBoxContainer/AbilityQContainer/HBoxContainer/PanelContainer/MarginContainer/Label
@onready var ability_a_progress_bar = $MarginContainer/VBoxContainer/AbilityQContainer/HBoxContainer/PanelContainer/ProgressBar
@onready var ability_b_label = $MarginContainer/VBoxContainer/AbilityEContainer/HBoxContainer/PanelContainer/MarginContainer/Label
@onready var ability_b_progress_bar = $MarginContainer/VBoxContainer/AbilityEContainer/HBoxContainer/PanelContainer/ProgressBar

@export var battle_text: PackedScene

var show_pickup_action = true

func _ready():
	GlobalSignals.connect("ability_fail", on_ability_fail)
	options_menu.visible = false
	get_tree().paused = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		toggle_options_menu()
	
	update_pickup_hint()
	var player: Player = Global.player
	if not player:
		return
	update_ability(player.ability_q, ability_a_label, ability_a_progress_bar)
	update_ability(player.ability_e, ability_b_label, ability_b_progress_bar)
	

func update_pickup_hint():
	if not Global.player:
		return
	
	var pickup_object = Global.player.pickup_interaction_object
	var equipped_weapon = Global.player.equipped_weapon
	var should_show_pickup_action = pickup_object or equipped_weapon
	
	if should_show_pickup_action:
		var target_string = "DROP WEAPON"
		if not equipped_weapon:
			target_string = "PICKUP"
		pickup_label.text = target_string
	
	if should_show_pickup_action == show_pickup_action:
		return
		
	var tween = create_tween()
	if should_show_pickup_action:
		tween.parallel().tween_property(pickup_container, "position", Vector2(0, 0), 0.2).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pickup_container, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	else:
		tween.parallel().tween_property(pickup_container, "position", Vector2(32, 0), 0.2).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(pickup_container, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_OUT)
	show_pickup_action = should_show_pickup_action

func update_ability(ability: BaseAbility, ability_label: Label, ability_progress_bar: ProgressBar):
	if not ability:
		return
		
	if ability.was_used:
		# TOOD: Do animation
		ability_label.text = ability.ability_name
	else:
		ability_label.text = '???????'
	
	var ability_progress = max(ability.cooldown_time  - ability.cooldown_timer, 0.0) / ability.cooldown_time
	ability_progress_bar.value = ability_progress * 100.0

func toggle_options_menu():
	options_menu.visible = !options_menu.visible
	get_tree().paused = options_menu.visible

func _on_continue_button_pressed():
	toggle_options_menu()

func _on_exit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)

func on_ability_fail(reason: BaseAbility.AbilityTriggerResult, ability: BaseAbility):
	var new_text = battle_text.instantiate()
	add_child(new_text)
	var mouse_position =  get_viewport().get_mouse_position()
	if not mouse_position:
		return
	new_text.global_position = mouse_position
	
	err_sound.play()
	match reason:
		BaseAbility.AbilityTriggerResult.COOLDOWN:
			new_text.text = str(ability.cooldown_timer).pad_decimals(2) + "s COOLDOWN"
		BaseAbility.AbilityTriggerResult.OUT_OF_RANGE:
			new_text.text = "OUT OF RANGE"
		BaseAbility.AbilityTriggerResult.AREA_OCCUPIED:
			new_text.text = "AREA OCCUPIED"
		BaseAbility.AbilityTriggerResult.INVALID_TARGET:
			new_text.text = "INVALID TARGET"
		BaseAbility.AbilityTriggerResult.NO_USAGE_LEFT:
			new_text.text = "NO USAGE LEFT"

