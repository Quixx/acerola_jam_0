extends Node

signal screen_shake()
signal bullet_hit(options)
signal ability_start(duration)
signal ability_fail(reason, ability)
signal noise_event(position, distance)
signal random_initialized()

signal player_dead()
signal game_end()
