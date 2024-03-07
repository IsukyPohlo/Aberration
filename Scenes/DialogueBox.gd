extends VBoxContainer

# Most of this code is from: https://github.com/real-ezTheDev/GodotEzDialoguePlugin
# using experimental release

@export var dialogue: JSON

@onready var dialogue_choice_res  = preload("res://Scenes/DialogueButton.tscn")
@onready var dialogue_handler: EzDialogue = $EzDialogue
@onready var portrait = $"../Portrait"
@onready var line_edit: LineEdit = $"../LineEdit"
@onready var skinLeft: Button = $"../left"
@onready var skinRight: Button = $"../right"

var dialogue_finished = false
var state: Dictionary = {
	"dialogue": "intro",
	"name": "",
	"quest": 0,
	"progress" : [
		false, false, false, false, false, false
	],
}
var portraits: Dictionary = {
	"narrator": preload("res://Dialogue/baka ouji.png")
}

func _ready() -> void:
	startDialogue("intro")

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
		
func setQuest(quest: int) -> void:
	
	state["quest"] = quest
	
	# extra stuff
	match(quest):
		1:
			pass

func _on_line_edit_text_changed(new_text: String) -> void:
	state["name"] = new_text
	print(state["name"])
