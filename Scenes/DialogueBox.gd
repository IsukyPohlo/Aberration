extends VBoxContainer

# Most of this code is from: https://github.com/real-ezTheDev/GodotEzDialoguePlugin
# using experimental release

#I put all the UI interactions here just because, it's big mess i know but we jamming we coding.

@export var dialogue: JSON

@onready var char: CharacterBody3D = $"../../Char"
@onready var dialogue_choice_res  = preload("res://Scenes/DialogueButton.tscn")
@onready var dialogue_handler: EzDialogue = $EzDialogue
@onready var portrait = $"../LeftDown/Portrait"
@onready var line_edit: LineEdit = $"../LineEdit"
@onready var skinLeft: Button = $"../left"
@onready var skinRight: Button = $"../right"
@onready var nameLabel: Label = $"../NameLabel"
@onready var credsLabel: Label = $"../RightUp/CredsLabel"
@onready var laptop_input: TextEdit = $"../LaptopInput"
@onready var laptop_text: TextEdit = $"../LaptopScreen2/ColorRect/LaptopText"

@onready var game: StaticBody3D = $"../../NavigationRegion3D/Room/game"
@onready var game2: MeshInstance3D = $"../../NavigationRegion3D/Room/desk/desk(Clone)/drawer/drawer/game2"

@onready var earnings: Label = $"../Earnings"
@onready var earningNum: Label = $"../EarningNum"
@onready var mirrorStatic: StaticBody3D = $"../../Mirror/Mirror"

@export var icons: Array[CompressedTexture2D]
@onready var interactText: Label = $"../InteractIcon/InteractText"
@onready var interactIcon: Sprite2D = $"../InteractIcon/Sprite2D"
@onready var numbness: ProgressBar = $"../LeftDown/ProgressBar"

@onready var hole_face: Node3D = $"../../NavigationRegion3D/Room/HoleFace"
@onready var aberrant: Sprite3D = $"../../NavigationRegion3D/Room/aberrant"
@onready var aberrant2: Sprite3D = $"../../NavigationRegion3D/Room/aberrant2"
@onready var aberrant3: Sprite3D = $"../../NavigationRegion3D/Room/aberrant3"
@onready var aberrant4: Sprite3D = $"../../NavigationRegion3D/Room/aberrant4"


@onready var numbnessShader: ColorRect = $"../../CanvasLayer/Numbness"
@onready var numbShader: ColorRect = $"../../CanvasLayer/Numb"
@onready var aberration_vision: ColorRect = $"../../CanvasLayer/AberrationVision"

@onready var room_spawn: Marker3D = $"../../NavigationRegion3D/Room/RoomSpawn"
@onready var aberrant_char_spawn: Marker3D = $"../../NavigationRegion3D/Map/AberrantCharSpawn"

@onready var aberrant_spawn: Marker3D = $"../../NavigationRegion3D/Map/AberrantSpawn"
@onready var right_down: Control = $"../RightDown"
@onready var aberrationBar: ProgressBar = $"../RightDown/ProgressBar"
@onready var mission: Label = $"../Mission"
@onready var crosshair: Sprite2D = $"../Center/Crosshair"
@onready var killcount: Label = $"../Mission/Killcount"

@onready var endingScreen: Control = $"../../CanvasLayer/EndingScreen"
@onready var endingLabel: Label = $"../../CanvasLayer/EndingScreen/endingLabel"

var endMission = false
var dialogue_finished = false
var state: Dictionary = {
	"dialogue": "intro",
	"name": "",
	"selectedSkin": 0,
	"randomNumber": 0,
	"credits": 0,
	"numbness": 0,
	"quest": 0,
	"mission": 0,
	"aberration": 0,
	"progress" : [
		false, false, false, false, false, false
	],
}
var portraits: Dictionary = {
	"narrator": preload("res://Dialogue/baka ouji.png")
}

func _ready() -> void:
	state["randomNumber"] = RandomNumberGenerator.new().randi()
	startDialogue("intro")
	var tw = create_tween()
	tw.tween_property(numbShader.get_material(), "shader_parameter/spread", 0, 1)

func _process(delta: float) -> void:
	
	(numbnessShader.material as ShaderMaterial).set_shader_parameter("alpha", numbness.value/100 - 0.1)
	#print(numbness.value/100)
	
	if state["progress"][0]:
		nameLabel.text = str(state["randomNumber"])
	else:
		nameLabel.text = state["name"]
		
	credsLabel.text = str(state["credits"])
	
	killcount.text = str(char.killCount)
	
	state["numbness"] = char.numbness
	numbness.value = state["numbness"]
	
	state["aberration"] = char.aberration
	aberrationBar.value = state["aberration"]
	
	if !endMission: 
		checkEndMission()
	
func startDialogue(dialogueNode: String) -> void:
	dialogue_finished = false
	dialogue_handler.start_dialogue(dialogue, state, dialogueNode)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func clear_dialogue():
	$text.text = ""
	for child in get_children():
		if child is Button:
			child.queue_free()

func add_text(text: String):
	$text.text = text
	
func add_choice(choice_text: String, id: int):
	var button = dialogue_choice_res.instantiate()
	button.text = choice_text
	button.dialogue_selected.connect(_on_choice_button_down)
	button.choice_id = id
	add_child(button)
	
func _on_choice_button_down(choice_id: int):
	clear_dialogue()
	if !dialogue_finished:
		dialogue_handler.next(choice_id)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		portrait.texture = Texture2D
		
func _on_ez_dialogue_dialogue_generated(response: DialogueResponse):
	add_text(response.text)
	if response.choices.is_empty():
		add_choice("...", 0)
	else:
		for i in response.choices.size():
			add_choice(response.choices[i], i)
	if response.eod_reached:
		dialogue_finished = true

func _on_ez_dialogue_custom_signal_received(value: String):
	var params = value.split(",")
	
	if params[0] == "progress":
		if params[1] == "set":
			var idx = int(params[2])
			var val = true
			if params[3] == "false":
				val = false
				
			state["progress"][idx] = val
	 
	if params[0] == "portrait":
		print( "setting: ", params[1])
		var image: String = params[1]
		
		if image == "none":
			portrait.texture = Texture2D
			return
		portrait.texture = portraits[image]
		
	if params[0] == "quest":
		setQuest( int(params[1]))
		
	if params[0] == "line":
		if params[1] == "show":
			line_edit.visible = true
		elif params[1] == "hide":
			line_edit.visible = false
			
	if params[0] == "skinSelect":
		if params[1] == "show":
			skinLeft.visible = true
			skinRight.visible = true
		elif params[1] == "hide":
			skinLeft.visible = false
			skinRight.visible = false
	
	if params[0] == "skinSet":
		char.setCharSkin(int(params[1]))
		
	if params[0] == "work":
		if params[1] == "show":
			laptop_input.visible = true
			earningNum.visible = true
			earnings.visible = true
		elif params[1] == "hide":
			laptop_input.visible = false
			earningNum.visible = false
			earnings.visible = false
		elif params[1] == "save":
			state["credits"] += len(laptop_input.text)
			laptop_input.text = ""
			earningNum.text = "0"
			print("save")
	
	if params[0] == "game":
		if params[1] == "show":
			game.visible = true
			game2.visible = false
		if params[1] == "start":
			right_down.visible = true
			aberration_vision.visible = true
			mission.visible = true
			crosshair.visible = true
			char.aberrantGameMode = true
			match state["mission"]:
				0: 
					char.global_position = aberrant_char_spawn.global_position
					mission.text = "Erorr?"
					endMission = false
				1: 
					char.global_position = aberrant_char_spawn.global_position
					aberrant_spawn.spawn(20,1)
					mission.text = "Level 1: Kill 20"
					endMission = false
					aberrant.visible = true
				2: 
					char.global_position = aberrant_char_spawn.global_position
					aberrant_spawn.spawn(30,2)
					mission.text = "Level 2: Kill 30"
					endMission = false
					hole_face.visible = true
					aberrant2.visible = true
					aberrant3.visible = true
				3: 
					char.global_position = aberrant_char_spawn.global_position
					aberrant_spawn.spawn(40,3)
					mission.text = "Level 3: Kill 40"
					endMission = false
					aberrant.layers = 1
					aberrant2.layers = 1
					aberrant3.layers = 1
					aberrant4.layers = 1
				4: 
					char.global_position = room_spawn.global_position
					aberrant_spawn.spawn(10,4)
					mission.text = "Level 4: Go to your room"
					endMission = false
			
		if params[1] == "end":
			
			aberration_vision.visible = false
			mission.visible = false
			crosshair.visible = false
			char.aberrantGameMode = false
			char.killCount = 0
			
	if params[0] == "mirror":
		if params[1] == "activate":
			mirrorStatic.add_to_group("dialogue")
			
	if params[0] == "numbEnding":
		numbShader.visible = true
		var tw = create_tween()
		tw.tween_property(numbShader.get_material(), "shader_parameter/spread", -10, 200.0)
		
		
		endingScreen.visible = true
		endingLabel.text = "Numb ending"
	
func checkEndMission()-> void:
	match state["mission"]:
		1: 
			if char.killCount >= 20:
				startDialogue("Mission1")
				char.global_position = room_spawn.global_position
				endMission = true
		2: 
			if char.killCount >= 30:
				startDialogue("Mission2")
				char.global_position = room_spawn.global_position
				endMission = true
		3: 
			if char.killCount >= 40:
				startDialogue("Mission3")
				char.global_position = room_spawn.global_position
				endMission = true
		4: 
			if char.killCount >= 10:
				startDialogue("Mission4")
				char.global_position = room_spawn.global_position
				endMission = true
			
func setQuest(quest: int) -> void:
	
	state["quest"] = quest
	
	# extra stuff
	match(quest):
		1:
			pass
			
func changeIcon(idx: int) -> void:
	interactIcon.texture = icons[idx]

func changeText(text: String) -> void:
	interactText.text = text

func _on_line_edit_text_changed(new_text: String) -> void:
	state["name"] = new_text
	print(state["name"])

func _on_left_button_down() -> void:
	state["selectedSkin"] = char.rotateCharSkin(false)
	print(state["selectedSkin"])

func _on_right_button_down() -> void:
	state["selectedSkin"] = char.rotateCharSkin(true)

func _on_laptop_input_text_changed() -> void:
	laptop_text.text = laptop_input.text
	char.numbness +=0.5
	earningNum.text = str(len(laptop_input.text))
	
	if state["mission"] >= 1:
		
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var num = rng.randi_range(0, 50)
		if num == 1:
			aberrant.layers = 1
			await get_tree().create_timer(0.02).timeout
			aberrant.layers = 2
			print("mostro")
		else:
			aberrant.layers = 2
			print("no mostro")
func _on_retry_down() -> void:
	get_tree().reload_current_scene()
