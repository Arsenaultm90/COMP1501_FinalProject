extends Node

const NORTH = 0
const EAST = 1
const SOUTH = 2
const WEST = 3


const LEVELS = {
	1: {
		"blocked_cells": [], 
		"flow_interval": 4
	},
	2: {
		"blocked_cells": [
			Vector2i(2, 1), Vector2i(2, 4),
			Vector2i(5, 1), Vector2i(5, 4),
			Vector2i(3, 2), Vector2i(4, 3),
		],
		"flow_interval": 3
	},
	3: {
		"blocked_cells": [
			Vector2i(1, 1), Vector2i(1, 4),
			Vector2i(3, 0), Vector2i(3, 5),
			Vector2i(4, 0), Vector2i(4, 5),
			Vector2i(6, 2), Vector2i(6, 3)
		],
		"flow_interval": 2
	},
}

const PIPE_CONNECTIONS = {
	"empty": [],
	"blocked":  [],
	"start": [EAST, WEST],
	"end": [NORTH, SOUTH],
	"straight_h":  [EAST, WEST],
	"straight_v":  [NORTH, SOUTH],
	"elbow_ne":    [NORTH, EAST],
	"elbow_es":    [EAST, SOUTH],
	"elbow_sw":    [SOUTH, WEST],
	"elbow_nw":    [NORTH, WEST],
}

const ELBOW_TRANSFORMS = {
	"elbow_es": {"rotation": 0.0,   "flip_h": false, "flip_v": false},
	"elbow_sw": {"rotation": 90.0,  "flip_h": false, "flip_v": false},
	"elbow_nw": {"rotation": 180.0, "flip_h": false, "flip_v": false},
	"elbow_ne": {"rotation": 270.0, "flip_h": false, "flip_v": false},
}

const STRAIGHT_TRANSFORMS = {
	"straight_h": {"rotation": 90.0, "flip_h": false, "flip_v": false},
	"straight_v": {"rotation": 0.0,  "flip_h": false, "flip_v": false},
}
