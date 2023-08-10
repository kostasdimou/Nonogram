#!/usr/bin/tclsh

array set CONFIG {
	black "@"
	guess "?"
	white " "
}
puts -nonewline "rows = "; set CONFIG(rows) [gets stdin]
puts -nonewline "columns = "; set CONFIG(columns) [gets stdin]

array set ROWS {}
for {set r 0} {$r < $CONFIG(rows)} {incr r} {
	puts -nonewline "row($r) = "; set ROWS($r) [gets stdin]
}
array set COLUMNS {}
for {set c 0} {$c < $CONFIG(columns)} {incr c} {
	puts -nonewline "column($c) = "; set COLUMNS($c) [gets stdin]
}

array set MATRIX {}
for {set r 0} {$r < $CONFIG(rows)} {incr r} {
	set row {}
	for {set c 0} {$c < $CONFIG(columns)} {incr c} {
		append row $CONFIG(guess)
	}
	set MATRIX($r) $row
}

puts ""
parray ROWS
puts ""
parray COLUMNS
puts ""
parray MATRIX

proc string_count {str char} {
	set new_str [string map [list $char {}] $str]
	return [expr {[string length $str] - [string length $new_str]}]
}

for {set r 0} {$r < $CONFIG(rows)} {incr r} {
	set blacks 0
	foreach block $ROWS($r) {
		incr blacks $block
	}
	set total $blacks
	set whites [llength $ROWS($r)]; incr whites -1
	incr total $whites
	if {$total == $CONFIG(columns)} {
		set MATRIX($r) {}
		foreach block $ROWS($r) {
			if {$MATRIX($r) != {}} {
				append MATRIX($r) $CONFIG(white)
			}
			append MATRIX($r) [string repeat $CONFIG(black) $block]
		}
	}
}

puts ""
parray MATRIX

