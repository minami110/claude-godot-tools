# Re-saves Godot text resources (.tscn / .tres) through the editor's resource
# pipeline so UIDs are injected and load failures are surfaced.
#
# Usage:
#   godot --headless --editor --path <project_root> --script <abs>/resave.gd -- <paths...>
#
# Paths after `--` may be files or directories (recursed), given as res://,
# absolute, or project-root-relative. Only .tscn / .tres are processed;
# hidden directories (.godot, .git, ...) are skipped.
#
# Output contract:
#   [RESAVE] FAIL <res://path> (load|save)   per failed file
#   [RESAVE] ok=<N> failed=<M>               final summary
# Exit code: 0 = all saved, 1 = one or more failures, 2 = bad arguments.
extends SceneTree

var _ok_count := 0
var _fail_count := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("[RESAVE] error: no paths given after '--'")
		quit(2)
		return

	var files: Array[String] = []
	for arg in args:
		if not _collect(arg, files):
			printerr("[RESAVE] error: path not found: %s" % arg)
			quit(2)
			return

	if files.is_empty():
		printerr("[RESAVE] error: no .tscn/.tres files matched the given paths")
		quit(2)
		return

	for path in files:
		_resave(path)

	print("[RESAVE] ok=%d failed=%d" % [_ok_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


# Normalizes `arg` and appends matching resource files to `out`,
# skipping files already collected via an earlier argument.
# Returns false if the path does not exist.
func _collect(arg: String, out: Array[String]) -> bool:
	var path := _normalize(arg)
	if DirAccess.dir_exists_absolute(path):
		_collect_dir(path, out)
		return true
	if FileAccess.file_exists(path):
		if _is_target(path) and not out.has(path):
			out.append(path)
		return true
	return false


func _collect_dir(dir_path: String, out: Array[String]) -> void:
	for name in DirAccess.get_directories_at(dir_path):
		if not name.begins_with("."):
			_collect_dir(dir_path.path_join(name), out)
	for name in DirAccess.get_files_at(dir_path):
		var path := dir_path.path_join(name)
		if _is_target(path) and not out.has(path):
			out.append(path)


func _normalize(arg: String) -> String:
	var path := arg
	if not path.begins_with("res://"):
		if path.is_absolute_path():
			path = ProjectSettings.localize_path(path)
		else:
			path = "res://" + path
	return path.simplify_path()


func _is_target(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext == "tscn" or ext == "tres"


func _resave(path: String) -> void:
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if res == null:
		_fail_count += 1
		print("[RESAVE] FAIL %s (load)" % path)
		return
	var err := ResourceSaver.save(res, path)
	if err != OK:
		_fail_count += 1
		print("[RESAVE] FAIL %s (save)" % path)
		return
	_ok_count += 1
