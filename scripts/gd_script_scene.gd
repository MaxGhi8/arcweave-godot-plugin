extends Control

@onready var scroll_container: ScrollContainer = $StoryContainer/ScrollContainer
@onready var text_window: RichTextLabel = $StoryContainer/ScrollContainer/TextWindow
@onready var image_window: TextureRect = $Background
@onready var options_container: VBoxContainer = $StoryContainer/OptionsContainer
@onready var refresh_button: Button = $StoryContainer/UIButtonsContainer/RefreshButton
@onready var restart_button: Button = $StoryContainer/UIButtonsContainer/RestartButton
@onready var menu_button: MenuButton = $MenuButton
@onready var arcweave_node: Node = $ArcweaveNode
@onready var button_sound_player: AudioStreamPlayer2D = $ButtonSoundPlayer
@onready var music_player: AudioStreamPlayer2D = $MusicPlayer
var music_enabled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Using Godot Script ./GodotSceneScript.gd")
	arcweave_node.connect("ProjectUpdated", _on_project_updated)
	
	setup_button_sound_options()
	setup_background_music()
	music_player.play()
	setup_text_window()
	
	menu_button.pressed.connect(_on_menu_pressed)
	var popup = menu_button.get_popup()
	popup.add_item("Save Game", 0)
	popup.add_item("Load Game", 1)
	popup.add_separator()
	popup.add_item("Toggle Music", 2)
	popup.set_item_checked(2, music_enabled)
	popup.id_pressed.connect(_on_menu_item_pressed)
	
	apply_button_style(refresh_button)
	apply_button_style(restart_button)
	refresh_button.pressed.connect(_on_refresh_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	repaint()


func repaint():
	text_window.text = arcweave_node.Story.GetCurrentRuntimeContent()
	
	var asset = arcweave_node.Story.GetCurrentElement().Cover
	if asset != null:
		image_window.texture = load("res://assets" + asset.Path)
	else:
		image_window.texture = null
	add_options()


func add_options():
	for option in options_container.get_children():
		options_container.remove_child(option)
		option.queue_free()
	
	var options = arcweave_node.Story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null:
		if len(paths) == 1:
			for path in paths:
				var button : Button = create_button_continue(path)
				options_container.add_child(button)
		else:
			for path in paths:
				if path.IsValid:
					var button : Button = create_button(path)
					options_container.add_child(button)


func create_button_continue(path):
	var button : Button = Button.new()
	
	# For multi-row content
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(200, 30)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	button.text = "Continue."
	button.pressed.connect(_on_option_button_pressed_with_sound.bind(path))
	
	apply_button_style(button)
	
	return button


func create_button(path):
	var button : Button = Button.new()
	
	# For multi-row content
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(200, 30)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	button.text = path.label if path.label != "" else "Continue."
	button.pressed.connect(_on_option_button_pressed_with_sound.bind(path))
	
	apply_button_style(button)
	
	return button


func _on_menu_button_pressed_with_sound(path):
	play_button_sound()
	_on_option_button_pressed(path)


func _on_option_button_pressed_with_sound(path):
	play_button_sound()
	_on_option_button_pressed(path)


func play_button_sound():
	if button_sound_player.stream != null:
		button_sound_player.play()


func _on_option_button_pressed(path):
	arcweave_node.Story.SelectPath(path)
	repaint()


func _on_project_updated():
	repaint()


func _on_refresh_pressed():
	arcweave_node.UpdateStory()


func _on_restart_pressed():
	get_tree().reload_current_scene()


func _on_menu_pressed():
	var popup = menu_button.get_popup()
	popup.set_item_disabled(1, !FileAccess.file_exists("user://savegame.save"))
	popup.position = Vector2i(25, 460)


func _on_menu_item_pressed(id):
	if id == 0:
		save_game()
	elif id == 1:
		load_game()
	elif id == 2:
		toggle_music()


func save_game():
	var save_game_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save = arcweave_node.Story.GetSave()
	save_game_file.store_var(save)


func load_game():
	var save_game_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var save = save_game_file.get_var()
	arcweave_node.Story.LoadSave(save)
	repaint()


func toggle_music():
	music_enabled = !music_enabled
	var popup = menu_button.get_popup()
	popup.set_item_checked(2, music_enabled)
	
	if music_enabled:
		if not music_player.playing:
			music_player.play()
		music_player.volume_db = -23  # Restore original volume
	else:
		music_player.stop()


func setup_text_window():
	text_window.add_theme_color_override("default_color", Color.WHITE)
	text_window.add_theme_constant_override("outline_size", 2)
	text_window.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Configure the RichTextLabel for proper sizing
	text_window.fit_content = true
	text_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_window.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Configure the ScrollContainer
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Style remains the same
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	text_window.add_theme_stylebox_override("normal", style)


func setup_button_sound_options():
	var click_sound = load("res://assets/SoundsEffects/SelectClick.wav")
	button_sound_player.stream = click_sound
	button_sound_player.volume_db = -15

func setup_background_music():
	var background_music = load("res://assets/SoundsEffects/AventureChillWalk.mp3")
	music_player.stream = background_music
	music_player.volume_db = -23
	music_player.autoplay = true
	music_player.finished.connect(_on_music_finished)


func _on_music_finished():
	if music_enabled:
		music_player.play() 


func apply_button_style(button: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0.7)
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 0.6)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.1, 0.3, 0.15, 0.85)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
