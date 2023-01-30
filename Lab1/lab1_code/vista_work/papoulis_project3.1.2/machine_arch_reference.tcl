*****************************************************************************************

Model Builder Machine Architecture TCL Script Command Reference 

Commands are listed alphabetically; argument alternatives are provided in square brackets.

*****************************************************************************************

add_delay_policy [-h] [-p <power>] [-l <latency>] [-latency <latency>] [-d] [-disabled] [-usage] [-help] [-power <power>] [-sync <sync>] [-s <sync>] port_or_transaction wait_states

add_pipeline_policy [-p <power>] [-b <buffer_size>] [-s <sync>] [-buffer-size <buffer_size>] [-d] [-usage] [-sync <sync>] [-latency <latency>] [-disabled] [-h] [-help] [-l <latency>] [-power <power>] port_or_transaction cause

add_power_policy [-h] [-d] [-disabled] [-usage] [-help] port_or_transaction power time_interval

add_reader_writer_dma [-h] [-usage] [-help] slave_port master_ports_list dma_name source_addr_reg_name target_addr_reg_name

add_sequential_policy [-p <power>] [-cause <cause>] [-c <cause>] [-s <sync>] [-d] [-usage] [-sync <sync>] [-latency <latency>] [-disabled] [-h] [-help] [-l <latency>] [-power <power>] port_or_transaction

add_split_policy [-p <power>] [-type <type>] [-t <type>] [-d] [-usage] [-w <wait_states>] [-latency <latency>] [-disabled] [-wait-states <wait_states>] [-h] [-help] [-l <latency>] [-power <power>] port_or_transaction burst_size

add_transaction_to_buffer [-h] [-usage] [-help] buffer_name port_name transaction_name condition

declare_buffer [-h] [-usage] [-help] [-r <reset>] [-reset <reset>] buffer_name

declare_direct_mapping_cache [-h] [-hit-policy <hit_policy>] [-usage] [-help] [-critical-word-first <critical_word_first>] [-m <miss_policy>] [-c <critical_word_first>] [-miss-policy <miss_policy>] slave_port lines_num line_size

declare_fifo_register [-h] [-usage] [-help] [-f <fifo_size>] [-fifo-size <fifo_size>] slave_port name address width

declare_full_associative_cache [-h] [-hit-policy <hit_policy>] [-usage] [-help] [-critical-word-first <critical_word_first>] [-m <miss_policy>] [-r <replacement_policy>] [-c <critical_word_first>] [-replacement-policy <replacement_policy>] [-miss-policy <miss_policy>] slave_port lines_num line_size

declare_variable [-h] [-t <type>] [-usage] [-help] [-kind <kind>] [-type <type>] [-k <kind>] name

declare_memory [-h] [-io] [-usage] [-help] [-is-virtual] memory_name slave_port base_address size

declare_register [-type <type>] [-r <rw_access>] [-size <size>] [-s <size>] [-t <type>] [-usage] [-w <width>] [-h] [-width <width>] [-help] [-i] [-rw-access <rw_access>] [-k <kind>] [-kind <kind>] [-is-trigger] slave_port register_name register_addr bit_range

declare_set_associative_cache [-h] [-hit-policy <hit_policy>] [-usage] [-help] [-critical-word-first <critical_word_first>] [-m <miss_policy>] [-r <replacement_policy>] [-c <critical_word_first>] [-replacement-policy <replacement_policy>] [-miss-policy <miss_policy>] slave_port line_size set_num lines_per_set

declare_state [-h] [-usage] [-help] [-history-values-count <history_values_count>] [-kind <kind>] [-k <kind>] name

declare_variable [-h] [-t <type>] [-usage] [-help] [-kind <kind>] [-type <type>] [-k <kind>] name

monitor_input_port [-h] [-usage] [-help] port transactions_window_size

set_clock_tree_power [-h] [-usage] [-help] clock_tree

set_leakage_power [-h] [-usage] [-help] leakage

set_nominal_clock [-h] [-usage] [-help] value

set_register_value [-h] [-usage] [-help] register_name port_name transaction_name condition value

set_sync_all [-h] [-usage] [-help] value

state_power [-h] [-usage] [-help] [-condition-pairs <condition_pairs>] [-c <condition_pairs>] power

