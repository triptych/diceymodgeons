extends PanelContainer

signal equipment_deleted(key)

onready var SizeOption = find_node("SizeOption")
onready var ColorOption = find_node("ColorOption")
onready var AlternateStatusOption = find_node("AlternateStatusOption")

onready var DeleteButton = find_node("DeleteButton")

onready var UsesSpin = find_node("UsesSpin")
onready var SpellSpin = find_node("SpellSpin")

onready var CastBackwardsCheck = find_node("CastBackwardsCheck")
onready var SingleUseCheck = find_node("SingleUseCheck")
onready var SFXCheck = find_node("SFXCheck")

onready var EquipmentTags = find_node("EquipmentTags")

onready var SlotsContainer = find_node("SlotsContainer")

onready var GadgetOption = find_node("GadgetOption")
onready var UpgradeOption = find_node("UpgradeOption")
onready var WeakenOption = find_node("WeakenOption")

onready var DescriptionEdit = find_node("DescriptionEdit")

onready var EquipmentCard = find_node("EquipmentCard")

var data_id:String = ""
var data:Dictionary = {}

func _ready():
	SizeOption.set_meta("list", ["1", "2"])

	Utils.fill_options(ColorOption, Gamedata.items.get("colors", []), true)
	Utils.fill_options(UpgradeOption, Gamedata.items.get("upgrade_modifier", {}), false)
	Utils.fill_options(WeakenOption, Gamedata.items.get("weaken_modifier", {}), false)

func set_data(data):
	data_id = Database.get_data_id(data, "Name")
	self.data = data

	var status = Database.commit(Database.Table.STATUS_EFFECTS, Database.READ, null, "Name")
	status.push_front('NONE')
	var filtered = []
	for s in status:
		if s.begins_with("alternate_"):
			continue

		filtered.push_back(s)

	Utils.fill_options(AlternateStatusOption, filtered, true)

	_setup(SizeOption, "Size", 1)
	_setup(ColorOption, "Colour", "")
	_setup(AlternateStatusOption, "Alternate Status Trigger", "")

	_setup(UsesSpin, "Uses?", 0)
	_setup(SpellSpin, "Witch Spell", 0)

	_setup(CastBackwardsCheck, "Cast Backwards?", false)
	_setup(SingleUseCheck, "Single use?", false)
	_setup(SFXCheck, "SFX", false)

	_setup(EquipmentTags, "Tags", [])

	_setup(SlotsContainer, "Slots", [])

	_setup(UpgradeOption, "Upgrade", "")
	_setup(WeakenOption, "Weaken", "")

	_setup(DescriptionEdit, "Description", "")

	if data_id.find("_") > -1:
		var table = Database.get_table(Database.Table.EQUIPMENT)
		DeleteButton.visible = not table.is_in_game_data(data_id)

	EquipmentCard.set_title(data_id)
	EquipmentCard.change_size(data.get("Size", 1))
	EquipmentCard.set_description(data.get("Description", ""))

	EquipmentCard.change_color(data.get("Colour", ""), data.get("Category", ""), data_id.ends_with("_upgraded") or data_id.ends_with("_deckupgrade"))

	var items = Database.commit(Database.Table.SKILLS, Database.READ)
	var values = {}
	values["None"] = "No gadget"
	for item in items.keys():
		values[item] = items[item].get("Description", "")
	Utils.fill_options(GadgetOption, values, false)

	_setup(GadgetOption, "Gadget", "")

func _setup(node, key, def):
	if node is SpinBox:
		node.value = data.get(key, def)
		Utils.connect_signal(node, key, "value_changed", self, "_on_SpinBox_value_changed")
	elif node is LineEdit:
		node.text = data.get(key, def)
		Utils.connect_signal(node, key, "text_changed", self, "_on_LineEdit_text_changed")
	elif node is CheckBox:
		node.pressed = data.get(key, def)
		Utils.connect_signal(node, key, "toggled", self, "_on_CheckBox_toggled")
	elif node is TextEdit:
		node.text = data.get(key, def)
		Utils.connect_signal(node, key, "text_changed", self, "_on_TextEdit_text_changed")
	elif node is OptionButton:
		var s = str(data.get(key, def))
		# Upgrade modifier doesn't need all those extra change_*. All of those are change_power now.
		if node == UpgradeOption and s.begins_with("change_"):
			s = "change_power"
		Utils.option_select(node, s)
		Utils.connect_signal(node, key, "item_selected", self, "_on_OptionButton_item_selected")
	elif node == DescriptionEdit:
		node.text = data.get(key, def)
		Utils.connect_signal(node, key, "text_changed", self, "_on_TextEdit_text_changed")
	elif node == SlotsContainer:
		var tags = data.get("Tags", [])
		_update_SlotsContainer_visibility(tags)
		node.set_data(data)
		Utils.connect_signal(node, "Slots", "slots_changed", self, "_on_SlotsContainer_slots_changed")
		Utils.connect_signal(node, "NEED TOTAL?", "total_changed", self, "_on_SlotsContainer_total_changed")
	elif node == EquipmentTags:
		node.set_data(data)

		var tags = data.get(key, [])
		_update_SlotsContainer_visibility(tags)

		Utils.connect_signal(node, "Tags", "tag_added", self, "_on_EquipmentTags_tag_added")
		Utils.connect_signal(node, "Tags", "tag_removed", self, "_on_EquipmentTags_tag_removed")
	else:
		printerr("Node %s couldn't be setup" % node.name)

func _update_SlotsContainer_visibility(tags):
	var hide_it = false
	for hide_it_for_tag in Gamedata.items.get("hide_slots_for_tags", []):
		if hide_it_for_tag in tags:
			hide_it = true
			break

	if hide_it:
		SlotsContainer.visible = false
		Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, "Slots", [])
		Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, "NEED TOTAL?", 0)
		SlotsContainer.set_data(data)
	else:
		SlotsContainer.visible = true

func _on_SpinBox_value_changed(value, node, key):
	if not data_id: return
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, value)

func _on_LineEdit_text_changed(value, node, key):
	if not data_id: return
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, value)

func _on_CheckBox_toggled(value, node, key):
	if not data_id: return
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, value)

func _on_TextEdit_text_changed(node, key):
	if not data_id: return

	if node == DescriptionEdit:
		EquipmentCard.set_description(node.text)

	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, node.text)

func _on_OptionButton_item_selected(id, node, key):
	if not data_id: return
	Utils.update_option_tooltip(node, id)
	if node == ColorOption:
		var color = node.get_item_text(node.selected).to_upper()
		EquipmentCard.change_color(color, "GRAY", data_id.ends_with("_upgraded") or data_id.ends_with("_deckupgrade"))


	var value = Utils.option_get_selected_key(node)

	if (node == UpgradeOption or node == WeakenOption or node == AlternateStatusOption) and node.selected == 0:
		value = ""

	if node == SizeOption:
		value = node.selected + 1
		EquipmentCard.change_size(value)

	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, value)

func _on_SlotsContainer_slots_changed(slots, node, key):
	if not data_id: return
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, slots)

func _on_SlotsContainer_total_changed(new_total, node, key):
	if not data_id: return
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, new_total)

func _on_EquipmentTags_tag_added(value, node, key):
	var tags = data.get(key, [])
	tags.push_back(value)
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, tags)
	_update_SlotsContainer_visibility(tags)

func _on_EquipmentTags_tag_removed(value, node, key):
	var tags = data.get(key, [])
	tags.erase(value)
	Database.commit(Database.Table.EQUIPMENT, Database.UPDATE, data_id, key, tags)
	_update_SlotsContainer_visibility(tags)

func _on_DeleteButton_pressed():
	if not data_id: return
	ConfirmPopup.popup_confirm("Are you sure you want to delete '%s'?" % data_id)
	var result = yield(ConfirmPopup, "action_chosen")
	if result == ConfirmPopup.OKAY:
		Database.commit(Database.Table.EQUIPMENT, Database.DELETE, data_id)
		emit_signal("equipment_deleted", data_id)
