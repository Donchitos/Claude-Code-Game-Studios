extends SceneTree
func _initialize():
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	assert(c.content_hash == "1e3c41e4223704a29050f28294bef4a38b9569186e6a6234a921c3685e92ab3e")
	assert(OS.get_user_data_dir().contains("Spirit Nexus D P00 20260915"))
	print("D_PACK_IDENTITY_PASS ",c.content_hash," ",OS.get_user_data_dir())
	quit()
