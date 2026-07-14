class_name UpgradeConfig
extends Resource

enum UpgradeId {
	DOUBLE_JUMP,
	QUICK_SLIDE,
}

@export var upgrade_id: UpgradeId = UpgradeId.DOUBLE_JUMP
@export var run_currency_cost: int = 20
@export var max_stack_count: int = 1
@export var display_name: String = "Double Jump"
