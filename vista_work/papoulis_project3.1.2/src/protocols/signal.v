
//************************************************************
//                                                            
//      Copyright Mentor Graphics Corporation 2006 - 2011     
//                  All Rights Reserved                       
//                                                            
//       THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY      
//         INFORMATION WHICH IS THE PROPERTY OF MENTOR        
//         GRAPHICS CORPORATION OR ITS LICENSORS AND IS       
//                 SUBJECT TO LICENSE TERMS.                  
//                                                            
//************************************************************


`timescale 1 ps / 1 ps

module signal
  (
    (* clock  *) input CLK,
    (* master *) input VALUE
  );

  reg prevValue;

  (* master *)
  function void Set(int address, int value_p, int block_size);
  endfunction

  (* transaction *)
  function void WRITE((* address *) int address, output int value_p[], (* block_size *) int block_size);
  endfunction

  typedef enum {
    idle
  } State;

  State state;

  (* protocol_initial *)
  initial 
  	state = idle;

  initial
	prevValue = 0;

  (* protocol_SM *)
  always
  begin
    case (state)
      idle :
      begin
        if (VALUE !== prevValue && VALUE !== 1'bx && $time != 0)
          begin
             (* WRITE *)
             Set(0, VALUE, 1);
             prevValue = VALUE;
             @ (negedge CLK);
        end
        else
        begin
          prevValue = VALUE;
          @ (negedge CLK);
        end
      end
    endcase
  end

endmodule

