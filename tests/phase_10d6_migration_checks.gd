extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
 var path:="user://tests/phase10d6/%d_legacy.json"%OS.get_process_id()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
 var original:=MuseumState.new()
 original.campaign_seed=735291385
 original.day_number=12
 original.cash=9876
 original.museum_level=2
 original.phase=MuseumState.Phase.EVENING
 original.last_day_visitors=23
 original.last_day_ticket_income=115
 for i in range(8):
  var item:=original.collection.add(MuseumState.POOL.antiques[i].id,4,60+i,true)
  original.assign(StringName("CASE_%d"%(i+1)),item.instance_id)
 var waiting:=original.collection.add(&"blue_white_jar",6,44,false)
 var pending:=original.collection.add(&"tang_sancai_horse",7,87,true)
 original.consign(pending.instance_id,2)
 var store:=MuseumProfileStore.new()
 store.save_path=path
 var v4:=store.encode(original)
 v4.version=4
 v4.erase("display_layout_version")
 var source:=JSON.stringify(v4,"\t")
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(source);file.close()
 var checksum:=FileAccess.get_sha256(path)
 var loaded:=store.load_profile()
 test.check(store.encode(loaded)==store.encode(original),"every v4 asset/date/cash/condition/pending field migrated losslessly")
 test.check(FileAccess.get_file_as_string(path)==source,"load never overwrites original")
 test.check(store.save_profile(loaded),"v5 save after backup succeeds")
 var backup:="%s.v4.%s.backup.json"%[path,checksum.substr(0,12)]
 test.check(FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup)==source,"v4 byte-exact backup retained")
 test.check(JSON.parse_string(FileAccess.get_file_as_string(path)).version==10,"new profile version10 with preserved old display")
 test.check(store.encode(store.load_profile())==store.encode(original),"v5 disk roundtrip exact")
 test.check(store.load_profile().collection.find(waiting.instance_id).condition==44 and not store.load_profile().collection.find(waiting.instance_id).identified,"unidentified state preserved")
 var bad:=v4.duplicate(true)
 bad.display_assignments["CASE_9"]=str(waiting.instance_id)
 var raw_bad:=JSON.stringify(bad)
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(raw_bad);file.close()
 loaded=store.load_profile()
 test.check(store.write_blocked and not store.save_profile(loaded),"invalid migration blocks automatic writes")
 test.check(FileAccess.get_file_as_string(path)==raw_bad,"failed migration preserves original bytes")
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string("{broken");file.close()
 loaded=store.load_profile()
 test.check(not store.save_profile(loaded) and FileAccess.get_file_as_string(path)=="{broken","corrupt JSON cannot be overwritten")
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(source);file.close()
 loaded=store.load_profile()
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(source+" ");file.close()
 test.check(not store.save_profile(loaded) and FileAccess.get_file_as_string(path)==source+" ","external edits after loading are protected")
 DirAccess.remove_absolute(path)
 DirAccess.remove_absolute(backup)
