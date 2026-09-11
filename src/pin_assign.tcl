package require ::quartus::project
package require ::quartus::flow

set csv_file "pinout.csv"
set project_name "Stopwatch";
set revision_name $project_name

# --- Open project if not already open ---
if {[is_project_open]} {
    puts "Project already open: [get_current_project]"
} else {
    if {[project_exists $project_name]} {
        project_open -revision $revision_name $project_name
    } else {
        puts "ERROR: Project $project_name not found in current directory."
        exit -1
    }
}

# --- Check CSV exists ---
if {![file exists $csv_file]} {
    puts "ERROR: CSV file '$csv_file' not found."
    exit -1
}

# --- Read and apply assignments ---
set fh [open $csv_file r]
set line_num 0
set applied 0

while {[gets $fh line] >= 0} {
    incr line_num

    # Skip header row
    if {$line_num == 1} {
        continue
    }

    # Skip blank lines
    if {[string trim $line] eq ""} {
        continue
    }

    set fields [split $line ","]

    if {[llength $fields] < 3} {
        puts "WARNING: Skipping malformed line $line_num: $line"
        continue
    }

    set signal_name  [string trim [lindex $fields 0]]
    set pin_number   [string trim [lindex $fields 1]]
    set io_standard  [string trim [lindex $fields 2]]

    # Apply pin location
    set_location_assignment PIN_$pin_number -to $signal_name

    # Apply I/O standard
    set_instance_assignment -name IO_STANDARD "$io_standard" -to $signal_name

    puts "Assigned $signal_name -> PIN_$pin_number ($io_standard)"
    incr applied
}

close $fh

puts "\nDone. Applied $applied pin assignment(s)."

# --- Save changes ---
export_assignments

if {![info exists ::env(KEEP_OPEN)]} {
    project_close
}
