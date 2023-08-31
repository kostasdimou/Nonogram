#!/usr/bin/tclsh
#
# A TCL script which resolves a nonogram puzzle.
#
# setting : A list of numbers where each one represents the continues black cells.
# pattern : A layout of black, white and guess cells.
#
# Command line:
#
# Nonogram.tcl < 5x5.snake.txt
#
# Output:
#
# ROW_SETTINGS(0) = 5
# ROW_SETTINGS(1) = 1
# ROW_SETTINGS(2) = 5
# ROW_SETTINGS(3) = 1
# ROW_SETTINGS(4) = 5
#
# COLUMN_SETTINGS(0) = 3 1
# COLUMN_SETTINGS(1) = 1 1 1
# COLUMN_SETTINGS(2) = 1 1 1
# COLUMN_SETTINGS(3) = 1 1 1
# COLUMN_SETTINGS(4) = 1 3
#
# MATRIX(0) = #####
# MATRIX(1) = #
# MATRIX(2) = #####
# MATRIX(3) =     #
# MATRIX(4) = #####
# 

proc parse_arguments {arguments} {
}

proc get_settings {} {
	global CONFIG ROW_SETTINGS COLUMN_SETTINGS

	# get dimensions
	puts -nonewline "rows = "; set CONFIG(rows) [gets stdin]
	puts -nonewline "columns = "; set CONFIG(columns) [gets stdin]

	# get row settings
	for {set r 0} {$r < $CONFIG(rows)} {incr r} {
		puts -nonewline "row($r) = "; set ROW_SETTINGS($r) [gets stdin]
	}
	if {$CONFIG(debug)} {
		puts ""
		parray ROW_SETTINGS
	}

	# get column settings
	for {set c 0} {$c < $CONFIG(columns)} {incr c} {
		puts -nonewline "column($c) = "; set COLUMN_SETTINGS($c) [gets stdin]
	}
	if {$CONFIG(debug)} {
		puts ""
		parray COLUMN_SETTINGS
	}
}

proc sum {setting} {
	set cells 0
	foreach block $setting {
		incr cells $block
	}
	return $cells
}

proc build {setting} {
	global CONFIG
	set pattern {}
	foreach block $setting {
		if {[string length $pattern]} {
			append pattern $CONFIG(white)
		}
		append pattern [string repeat $CONFIG(black) $block]
	}
	return $pattern
}

proc calculate_patterns {pattern width extra gap} {
}

proc analyze {settings_array width patterns_array} {
	global CONFIG
	upvar #0 $settings_array SETTINGS
	upvar #0 $patterns_array PATTERNS
	array unset patterns_array
	foreach key [array names SETTINGS] {
		set setting $SETTINGS($key)
		set pattern [build $setting]
		set p 0
		set max_offset [expr {$width - [string length $pattern]}]
		for {set offset 0} {$offset <= $max_offset} {incr offset} {
			set left [string repeat $CONFIG(white) $offset]
			set right [string repeat $CONFIG(white) [expr {$max_offset - $offset}]]
			set PATTERNS($key,$p) $left
			append PATTERNS($key,$p) $pattern $right
			incr p
		}
	}
}

proc analyze_settings {} {
	global CONFIG
	analyze ROW_SETTINGS $CONFIG(columns) ROW
	analyze COLUMN_SETTINGS $CONFIG(rows) COLUMN
}

proc initialize_matrix {} {
	global CONFIG MATRIX
	for {set r 0} {$r < $CONFIG(rows)} {incr r} {
		set row {}
		for {set c 0} {$c < $CONFIG(columns)} {incr c} {
			append row $CONFIG(guess)
		}
		set MATRIX($r) $row
	}
}

proc string_count {container pattern} {
	set new_container [string map [list $pattern {}] $container]
	return [expr {[string length $container] - [string length $new_container]}]
}

proc resolved {} {
	global CONFIG MATRIX
	for {set r 0} {$r < $CONFIG(rows)} {incr r} {
		if {[string first $CONFIG(guess) $MATRIX($r)] > -1} {
			return 0
		}
	}
	return 1
}

proc merge {pattern_1 pattern_2} {
	global CONFIG
	set width [string length $pattern_1]
	if {$width != [string length $pattern_2]} {
		error "proc merge: patterns have different width ($pattern_1 vs $pattern_2)"
	}
	set cells {}
	for {set i 0} {$i < $width} {incr i} {
		set cell_1 [string index $pattern_1 $i]
		set cell_2 [string index $pattern_2 $i]
		append cells [string map [list\
			$CONFIG(black)$CONFIG(black) $CONFIG(black)\
			$CONFIG(white)$CONFIG(white) $CONFIG(white)\
			$CONFIG(black)$CONFIG(failed) $CONFIG(black)\
			$CONFIG(white)$CONFIG(failed) $CONFIG(white)\
			$CONFIG(guess)$CONFIG(black) $CONFIG(black)\
			$CONFIG(guess)$CONFIG(white) $CONFIG(white)\
			$CONFIG(black)$CONFIG(white) $CONFIG(failed)\
			$CONFIG(white)$CONFIG(black) $CONFIG(failed)\
			$CONFIG(guess)$CONFIG(failed) $CONFIG(guess)\
			$CONFIG(failed)$CONFIG(black) $CONFIG(failed)\
			$CONFIG(failed)$CONFIG(white) $CONFIG(failed)\
		] $cell_1$cell_2]
	}
	return $cells
}

proc get_column {index} {
	global CONFIG MATRIX
	set result {}
	for {set r 0} {$r < $CONFIG(rows)} {incr r} {
		append result [string index $MATRIX($r) $index]
	}
	return $result
}

proc set_column {index value} {
	global CONFIG MATRIX
	for {set r 0} {$r < $CONFIG(rows)} {incr r} {
		set row $MATRIX($r)
		set before [string range $row 0 [expr {$index - 1}]]
		set after [string range $row [expr {$index + 1}] end]
		set MATRIX($r) $before
		append MATRIX($r) [string index $value $r] $after
	}
}

proc resolve_matrix {} {
	global CONFIG MATRIX ROW COLUMN
	array set PREVIOUS {}
	while {![resolved] && [lsort [array get PREVIOUS]] != [lsort [array get MATRIX]]} {
		if {$CONFIG(debug)} {
			puts ""
			parray MATRIX
		}
		array set PREVIOUS [array get MATRIX]
		for {set r 0} {$r < $CONFIG(rows)} {incr r} {
			set pattern [string repeat $CONFIG(guess) $CONFIG(columns)]
			foreach key [array names ROW $r,*] {
puts "key = $key row = $ROW($key)"
				set pattern [merge $pattern $ROW($key)]
			}
puts "H pattern = $pattern"
			set MATRIX($r) [merge $MATRIX($r) $pattern]
		}
		for {set c 0} {$c < $CONFIG(columns)} {incr c} {
			set pattern [string repeat $CONFIG(guess) $CONFIG(rows)]
			foreach key [array names COLUMN $c,*] {
				set pattern [merge $pattern $COLUMN($key)]
			}
puts "V pattern = $pattern"
			set column [get_column $c]
			set merged [merge $column $pattern]
			set_column $c $merged
		}
	}
	array unset PREVIOUS
}

# configuration
array set CONFIG {
	black "#"
	columns 0
	debug 1
	failed "-"
	guess "?"
	rows 0
	white " "
}

# arrays
array set ROW_SETTINGS {}
array set ROW {}
array set COLUMN_SETTINGS {}
array set COLUMN {}
array set MATRIX {}
array set PATTERNS {}

# main
parse_arguments $argv
get_settings
analyze_settings
initialize_matrix
resolve_matrix
puts ""
parray MATRIX
