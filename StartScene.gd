extends Control
@onready var badge_button: TextureButton = $BadgeButton
@onready var game_button: TextureButton = $CenterContainer/GridContainer/GodotButton

func _ready():
	# Connect both buttons in _ready()
	badge_button.pressed.connect(_on_badge_pressed)
	game_button.pressed.connect(_on_godot_button_pressed)

func _on_godot_button_pressed():
	get_tree().change_scene_to_file("res://scenes/gd_script_scene.tscn")

func _on_badge_pressed():
	OS.shell_open("https://bolt.new/")

#func _on_c_sharp_button_pressed():
#	get_tree().change_scene_to_file("res://scenes/c_sharp_scene.tscn")
