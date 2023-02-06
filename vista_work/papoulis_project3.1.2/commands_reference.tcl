*****************************************************************************************

Model Builder TCL Command Reference 

Commands are listed alphabetically; argument alternatives are provided in square brackets.

*****************************************************************************************

add_generated_files_to_vista_project [-h] [-usage] [-help] tlm_model_path vista_project

add_template [-h] [-t <type>] [-usage] [-help] [-f] [-type <type>] [-force] logical_path source_directory_path

associate_hdl_unit_to_tlm_model [-h] [-usage] [-help] hdl_unit_path tlm_model_path port_associations

clean_tlm_library [-h] [-usage] [-help] library_name

clear_causality_ban [-h] [-usage] [-help] tlm_model_path port_name

create_tlm_library [-h] [-usage] [-help] library_name physical_path

create_tlm_model [-generics <generics>] [-machine-arch-tcl-path <machine_arch_tcl_path>] [-p <pv_kind>] [-ipxact-ven <ipxact_vendor>] [-other-port-list <other_port_list>] [-ns <model_namespace>] [-a <auto_parameters_defaults>] [-r] [-type <type>] [-generate-ipxact] [-dont-save] [-c <class_name_external_pv>] [-auto-parameters-defaults <auto_parameters_defaults>] [-pv-kind <pv_kind>] [-t <type>] [-include <include>] [-usage] [-ipxact-ver <ipxact_version>] [-vista-project <vista_project>] [-mp <max_parameters_of_pv_constructor>] [-e <external_pv_include>] [-ipxact-vendor <ipxact_vendor>] [-v <vista_project>] [-op <other_port_list>] [-ds] [-overwrite <overwrite>] [-max-parameters-of-pv-constructor <max_parameters_of_pv_constructor>] [-g <generate_kind>] [-h] [-generate-kind <generate_kind>] [-help] [-generics-data <generics>] [-i <include>] [-gen-ipxact] [-external-pv-include <external_pv_include>] [-model-namespace <model_namespace>] [-read-only] [-class-name-external-pv <class_name_external_pv>] [-timing-kind <timing_kind>] [-m <machine_arch_tcl_path>] [-ipxact-version <ipxact_version>] [-o <overwrite>] [-tk <timing_kind>] model_name library_name port_list parameter_list

delete_objects [-h] [-usage] [-help] object_list

does_tlm_library_exist [-h] [-usage] [-help] library_name

dump_simulation_data [-h] [-usage] [-help] [-i <instance_path>] [-instance-path <instance_path>] db_path output_file

export_model [-h] [-append] [-usage] [-help] [-a] tlm_model_path tar_file

extract_model_interface [-h] [-usage] [-help] hdl_unit_path library_name model_name

extract_netlist_power [-input-slew <input_slew>] [-r <reset>] [-c <clks>] [-reset <reset>] [-usage] [-w <wire_load>] [-h] [-ignore-netlist-interface-mismatching] [-help] [-clks <clks>] [-wire-load <wire_load>] [-ignore-missing-cells] hdl_unit_path netlist_source tech_library

generate_model_code [-p <pv_kind>] [-ns <model_namespace>] [-b <backup_dir>] [-files <files>] [-pv-kind <pv_kind>] [-c <class_name_external_pv>] [-backup-dir <backup_dir>] [-t <timing_kind>] [-usage] [-vista-project <vista_project>] [-v <vista_project>] [-f <files>] [-overwrite] [-g <generate_kind>] [-include-external-pv-model-path <include_external_pv_model_path>] [-max-parameters-of-pv-constructor <max_parameters_of_pv_constructor>] [-h] [-generate-kind <generate_kind>] [-help] [-i <include_external_pv_model_path>] [-model-namespace <model_namespace>] [-timing-kind <timing_kind>] [-class-name-external-pv <class_name_external_pv>] [-m <max_parameters_of_pv_constructor>] [-o] tlm_model_path output_directory modeling_style

generate_testbench [-h] [-t] [-usage] [-help] [-tlm-types] tlm_model_path transaction_ports db_path output_file

get_causality_ban [-h] [-usage] [-help] tlm_model_path port_name

import [-h] [-usage] [-help] tar_file

instantiate_template [-h] [-generics <generics>] [-usage] [-help] [-g <generics>] template_path model_name library_name

learn_model [-p <progress_cmd>] [-timing-model-source <timing_model_source>] [-r <rand_seed>] [-use-timing-policies] [-t <timing_model_source>] [-usage] [-include-dirs <include_dirs>] [-u] [-g <genetic_confidence>] [-h] [-progress-cmd <progress_cmd>] [-help] [-i <include_dirs>] [-l] [-genetic-confidence <genetic_confidence>] [-rand-seed <rand_seed>] [-learn-pv] tlm_model_path instance_path_list

list_commands [-h] [-usage] [-help]

list_machine_architecture_commands [-h] [-usage] [-help]

list_read_vcd_commands [-h] [-usage] [-help]

load_model [-h] [-d <dry>] [-usage] [-help] [-dry <dry>] library model

load_tcl_machine_arch [-h] [-usage] [-help] tlm_model_path tcl_script_path

parse_protocol_source [-include-dir <include_dir>] [-s] [-generate-ipxact] [-d <dest_library>] [-usage] [-vendor <vendor>] [-g] [-h] [-help] [-i <include_dir>] [-dest-library <dest_library>] [-suppress-warnings] [-version <version>] source_file

parse_regular_expression [-h] [-usage] [-help] protocol_path source_file

parse_verilog_source [-h] [-d <directives>] [-usage] [-help] [-directives <directives>] source_files library_name

parse_vhdl_source [-h] [-usage] [-help] source_files library_name

put_causality_ban [-h] [-usage] [-help] tlm_model_path port_name event_name

read_technology_library [-h] [-usage] [-help] [-without-delay] [-w] source_file folder_name

read_vcd [-p <power_tech_lib>] [-netlist-toggle-check <netlist_toggle_check>] [-netlist-clk-check <netlist_clk_check>] [-vsim-options <vsim_options>] [-r <rand_seed>] [-s <sdf_file>] [-no-vista] [-sdf-file <sdf_file>] [-calculate-glitch-power] [-t <tcl>] [-usage] [-includes-dir <includes_dir>] [-verbose] [-calculation-power-start-time <calculation_power_start_time>] [-ignore-missing-signals-in-vcd-file] [-power-tech-lib <power_tech_lib>] [-h] [-help] [-interactive-mode] [-comparing-start-time <comparing_start_time>] [-tcl <tcl>] [-ignore-toggles-on-unassociated-ports] [-m <move_clocks>] [-move-clocks <move_clocks>] [-rand-seed <rand_seed>] [-comments <comments>] hdl_unit_path instance_path db_name vcd_file_path

reload_tlm_library [-h] [-d <directory>] [-usage] [-help] [-directory <directory>] library_name

remove_tlm_library [-h] [-usage] [-help] library_name

report_instance_activity [-h] [-usage] [-help] simulation_dir instance_path output_file

run_external_command [-h] [-sources <sources>] [-usage] [-help] [-rand-seed <rand_seed>] [-e <env>] [-env <env>] [-output-path <output_path>] [-r <rand_seed>] [-s <sources>] [-o <output_path>] command

save_model [-h] [-d <directory>] [-usage] [-help] [-vista-project <vista_project>] [-directory <directory>] [-v <vista_project>] [-g] [-generate] tlm_model_path

save_tlm_library [-h] [-d <directory>] [-usage] [-help] [-directory <directory>] library_name

set_tlm_library_physical_path [-h] [-usage] [-help] library_name physical_path

start_output_log [-h] [-usage] [-help]

stop_output_log [-h] [-usage] [-help]

