//===========================================
// Function : UART Transmitter
//===========================================
#include "UART_XMTR.h"

  // ----- Code Starts Here ----- 

  void UART_XMTR::Send_bit() {
    
    switch(IntState){
      
      case STATE_IDLE:
        if(!rst_b){ // RESET PUSHED
          NextIntState = STATE_IDLE;
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl; 
        }
        else{
          if(Load_XMT_datareg){ // IF LOAD, START LOADING
            XMT_datareg = Data_Bus;
            NextIntState = STATE_IDLE;
            // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
          }
          else{
            if(Byte_ready){ // ALL BIT READY, LOAD TO SHIFT REG, MOVING NEXT STATE
              XMT_shftreg = (XMT_datareg.range(7,0),sc_uint<1>(1));
              NextIntState = STATE_WAITING;
              // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
            }
            else { 
              NextIntState = STATE_IDLE;
              // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl; 
            }
          }
        }
        break;
    		
      case STATE_WAITING:
        if(T_byte){ // INSERT START BIT, MOVING TO SENDING
          XMT_shftreg[0] = 0;
          NextIntState = STATE_SENDING;
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
        }
        else {
          NextIntState = STATE_WAITING;
          
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
        }
        break;
			
			case STATE_SENDING:
        if(bit_count < 9){ // START SENDING BIT, COUNT FROM 0 TO 9 TILL FINISH ALL BIT
          XMT_shftreg = (sc_uint<1>(1), XMT_shftreg.range(8,1));
          NextIntState = STATE_SENDING;
          bit_count++; // INCREMENT BIT COUNTER
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
        }
        else{
          bit_count = 0; //RESET BIT COUNTER
          NextIntState = STATE_IDLE;
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;
        }
        break;

      default: 
        NextIntState = STATE_IDLE;
          // FOR TESTING std::cout << "@IntState : " << IntState << "\t" << "NextIntState: " << NextIntState << "bit_count: " << bit_count << std::endl;

    }
  
		Serial_out.write(XMT_shftreg[0]);
  
  }

  void UART_XMTR::Initialize() {
		if(!rst_b.read()) {
			IntState = STATE_IDLE;
			
			XMT_shftreg = 0x1ff;
			bit_count = 0;
		}
		else {
			IntState = NextIntState;
		}
  }
