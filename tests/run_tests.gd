extends SceneTree
## Executa todos os tests/test_*.gd em modo headless.
## Uso: godot --headless --script res://tests/run_tests.gd  (ou tests/run_tests.sh)

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	var files := Array(DirAccess.get_files_at(TEST_DIR)).filter(
		func(f: String): return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	var total := 0
	var failed := 0
	for file in files:
		var script: GDScript = load(TEST_DIR + file)
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("  FALHA %s :: não carregou (erro de script)" % file)
			continue
		var seen := {}
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_") or seen.has(method_name):
				continue
			seen[method_name] = true
			total += 1
			var test = script.new()
			test.call(method_name)
			test.cleanup()
			if test.failures.is_empty():
				print("  ok    %s :: %s" % [file, method_name])
			else:
				failed += 1
				print("  FALHA %s :: %s" % [file, method_name])
				for message in test.failures:
					print("        - " + message)
	print("\n%d testes, %d falhas" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)
