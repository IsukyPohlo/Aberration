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
@onready var game: StaticBody3D = $"../../Room/game"
@onready var game2: MeshInstance3D = $"../../Room/desk/desk(Clone)/drawer/drawer/game2"
@onready var earnings: Label = $"../Earnings"
@onready var earningNum: Label = $"../EarningNum"
@onready var mirrorStatic: StaticBody3D = $"../../Mirror/Mirror"

@export var icons: Array[CompressedTexture2D]
@onready var interactText: Label = $"../InteractIcon/InteractText"
@onready var interactIcon: Sprite2D = $"../InteractIcon/Sprite2D"
@onready var numbness: ProgressBar = $"../LeftDown/ProgressBar"

@onready var numbnessShader: ColorRect = $"../../CanvasLayer/Numbness"

var dialogue_finished = false
var state: Dictionary = {
	"dialogue": "intro",
	"name": "",
	"selectedSkin": 0,
	"randomNumber": 0,
	"credits": 0,
	"numbness": 0,
	"quest": 0,
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

func _process(delta: float) -> void:
	
	(numbnessShader.material as ShaderMaterial).set_shader_parameter("alpha", numbness.value/100)
	#print(numbness.value/100)
	
	if state["progress"][0]:
		nameLabel.text = str(state["randomNumber"])
	else:
		nameLabel.text = state["name"]
		
	credsLabel.text = str(state["credits"])
	#print(state["credits"])
	
	numbness.value = state["numbness"]
	
	if state["numbness"] > 90:
		char.setCharHole(true)
	else:
		char.setCharHole(false)
	
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
			
	if params[0] == "mirror":
		if params[1] == "activate":
			mirrorStatic.add_to_group("dialogue")
			
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
	state["numbness"] +=0.5
	earningNum.text = str(len(laptop_input.text))
	
