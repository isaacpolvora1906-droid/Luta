extends RefCounted
## Base mínima de testes (sem dependências externas). Cada método test_* é um teste.

var failures: Array[String] = []
var _nodes: Array[Node] = []


func assert_true(condition: bool, message := "esperava verdadeiro") -> void:
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message := "esperava falso") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("%s: esperado %s, obtido %s" % [message, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, message := "", tolerance := 0.0001) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: esperado %f, obtido %f" % [message, expected, actual])


## Registra um nó para ser liberado ao fim do teste.
func track(node: Node) -> Node:
	_nodes.append(node)
	return node


func cleanup() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func new_fighter() -> Fighter:
	var fighter := track(Fighter.new()) as Fighter
	fighter.reset_for_round(0.0, true)
	return fighter


func step_n(fighter: Fighter, bits: int, frames: int) -> void:
	for i in frames:
		fighter.step(bits)
