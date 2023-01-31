//===========================================
// Function : Asynchronous SRAM 
//===========================================
#include "systemc.h"

#define DATA_WIDTH        8 
#define ADDR_WIDTH        18 
#define RAM_DEPTH         1 << ADDR_WIDTH

SC_MODULE (RAM) {
  // ----- Declare Input/Output ports -----
  // INPUTS
  sc_in <sc_uint <DATA_WIDTH> >  InData;
  sc_in <sc_uint <ADDR_WIDTH> >  Addr;
  sc_in <bool>                 bCE;
  sc_in <bool>                 bWE;
  //OUTPUTS
  sc_out <sc_uint <DATA_WIDTH> > OutData;

  // ----- Internal variables -----
  // Declare 256K SRAM unit, each has 8 bits
  sc_uint<DATA_WIDTH> mem [RAM_DEPTH];
  

  // ----- Code Starts Here ----- 
  // Memory Write Block 
  // Write Operation : When we_b = 0, ce_b = 0
  void write_ram(){
    if (!bWE.read() && !bCE.read()) {
      // Assign InData into 1 address as in memory
      mem[Addr.read()] = InData.read();
    }
  }
  
  // Memory Read Block 
  // Read Operation : When we_b = 1, ce_b = 0
  void read_ram() {
    if (bWE.read() && !bCE.read()){
      //Write data from 1 address of memory to OutData
      OutData.write(mem[Addr.read()]);
    }
  }

  // ----- Constructor for the SC_MODULE -----
  // sensitivity list
  SC_CTOR(RAM) {
    SC_METHOD(write_ram);
    sensitive << Addr << bCE << bWE << InData;
    SC_METHOD(read_ram);
    sensitive << Addr << bCE << bWE;
  }
};

