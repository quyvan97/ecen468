#include "UART_XMTR.h"
#include "test.h"

int sc_main (int argc, char* argv[]) {

	// Input/Output Signal
  	sc_signal < sc_uint<WORD_SIZE> > 	Data_Bus;
  	sc_signal < bool > 			Load_XMT_datareg;
  	sc_signal < bool > 			Byte_ready;
  	sc_signal < bool > 			T_byte;
  	sc_signal < bool > 			rst_b;
  
	sc_signal < bool >			Serial_out;

	// Clock Generation
	sc_clock clk("clk", 1, SC_NS);
	
	// Connect the DUT
	// Method 1. Named Connection
	// ...
	// >> Connect your top module here
	// ...

	// Method 2. Positional connection
	// ...
	// >> Connect your testbench here
	// ...

	// Open VCD file
	sc_trace_file *wf = sc_create_vcd_trace_file("wave");

	// Dump the desired signals
	sc_trace(wf, Load_XMT_datareg, "Load_XMT_datareg");
    sc_trace(wf, Byte_ready, "Byte_ready");
	sc_trace(wf, T_byte, "T_byte");
	sc_trace(wf, rst_b, "rst_b");
	sc_trace(wf, Data_Bus, "Data_Bus");
	sc_trace(wf, Serial_out, "Serial_out");
	sc_trace(wf, clk, "clk");
	
	// Time to simulate
	// Simulate until it meets sc_stop() if sc_start(-1) or sc_start()
	//sc_start(1000, SC_NS);	// Simulate for 1000ns
	sc_start();

	// Close the dump file
	sc_close_vcd_trace_file(wf);
	
	return 0;	// Terminate simulation
}
