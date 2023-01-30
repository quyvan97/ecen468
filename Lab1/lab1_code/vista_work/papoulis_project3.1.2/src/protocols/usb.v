
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

`define INTERRUPT_CONTROL  0
`define ISOCHRONOUS        1
`define BULK               2

`timescale 1 ps / 1 ps
module usb #(parameter endpoint_type_param = `INTERRUPT_CONTROL)
    (
        (* master  *) input [1 : 0] LINESTATE,
        (* master  *) input [1 : 0] XCVRSEL,
        (* master  *) input TERMSEL,
        (* master  *) input RXACTIVE, 
        (* master  *) input RXVALID, 
        (* master  *) input TXREADY, 
        (* slave   *) input TXVALID, 
        (* master  *) (* default_value = 0 *) input [15 : 0] XDATAIN, 
        (* slave   *) input [15 : 0] XDATAOUT, 
        (* clock   *) input XCLK
    );

   integer hSize = 0;
   integer address = 0;
   integer end_point = 0;
   
   integer   hs = 0;
   integer   fs = 0;
   integer   isMaster = 0;
   
   typedef enum {
        UNSET,
        HS,
        FS
   } MODE;
   
   MODE mode = UNSET;
   integer   endpoint_type = endpoint_type_param;
         
    (* slave *)
    function void transmit_data(int XDATAOUT);
    endfunction
    
    (* slave *)
    function void transmit_data_packet(int XDATAOUT);
    endfunction
    
    (* slave *)
    function void transmit_handshake_packet(int XDATAOUT);
    endfunction
    
    (* slave *)
    function void end_trans_data(int hSize);
    endfunction
    
    (* slave *)
    function void no_handshake();
    endfunction 

   
    (* slave *)
    function void continue_bulk();
    endfunction
    
    (* master *)
    function void end_receive_data(int hSize);
    endfunction
    
    (* master *)
    function void receive_data(int XDATAIN);
    endfunction

   (* master *)
    function void receive_control_data(int end_point);
    endfunction
   
    (* master *)
    function void receive_data_packet(int XDATAIN);
    endfunction
    
    (* master *)    
    function void receive_handshake_packet(int XDATAIN);
    endfunction
    
    (* master *)    
    function void master_no_handshake();
    endfunction // void
   
   (* master *)    
    function void invalid_packet();
    endfunction // void
   
    (* master *)    
    function void master_continue_bulk();
    endfunction 

    (* master *)
    function void start_transaction(int address, MODE mode_p, int endpoint_type_p, int block_size);
    endfunction
   
    (* master *)
    function void receive_in_token_packet(int address, MODE mode_p, int endpoint_type_p);
    endfunction
    
    (* master *)
    function void receive_out_token_packet(int address, MODE mode_p, int endpoint_type_p);
    endfunction
    
    (* master *)
    function void receive_setup_token_packet(int address, MODE mode_p, int endpoint_type_p);
    endfunction
    
    (* master *)
    function void receive_sof_token_packet(int address, MODE mode_p, int endpoint_type_p);
    endfunction 

    (* master *)
    function void receive_ping_packet(int address, MODE mode_p, int endpoint_type_p);
    endfunction 

    (* transaction *) (* default_read *)
    function void IN_PACKET((* address *) int address, input int XDATAOUT[], (* default_value = 0 *) int end_point,
                            (* block_size *) (* default_value = 2 *) int block_size);
    endfunction 
   
    (* transaction *) (* default_write *)
    function void OUT_PACKET((* address *) int address, output int XDATAIN[], (* default_value = 0 *) int end_point,
                             (* block_size *) (* default_value = 2 *) int block_size);
    endfunction 
      
    (* transaction *)
    function void SETUP_PACKET((* address *) int address, output int XDATAIN[], (* default_value = 0 *) int end_point,
                               (* block_size *) (* default_value = 2 *) int block_size);
    endfunction 
   
    (* transaction *)
    function void SOF_PACKET((* address *) int address, (* default_value = 0 *) int end_point,
                             (* block_size *) (* default_value = 2 *) int block_size);
    endfunction

    (* transaction *)
    function void PING_PACKET((* address *) int address, (* default_value = 0 *) int end_point,
                              (* block_size *) (* default_value = 2 *) int block_size);
    endfunction 

   (* protocol_error *)
   function void protocolError(input string error);
      $display(error);
   endfunction // void
   
typedef enum {
        idle_state,
        state_0,
              state_6,
        state_8,
        state_9,
        state_11,
        state_14,
        state_16,
        state_17,
        state_18,
        state_35,
        state_36,
        state_37      
} PROTOCOL_STATES;

PROTOCOL_STATES protocolState;
    
(* protocol_initial *)
initial
        protocolState = idle_state;
    

(* protocol_SM *)
always
begin
       case(protocolState)

            idle_state : 
              begin
                 hs = (XCVRSEL == 0 && TERMSEL == 0);
                 fs = (XCVRSEL == 1 && TERMSEL == 1);

                 if (hs)
                   mode = HS;
                 
                 if (fs)
                   mode = FS;
                 
                 if (isMaster)
                   begin
                      @(negedge XCLK);
                   end
                 else
                if (RXACTIVE !== 1 || RXVALID !== 1 || ( XDATAIN[7 : 0] != 105 && XDATAIN[7 : 0] != 165 && XDATAIN[7 : 0] != 225 && XDATAIN[7 : 0] != 45 &&
                                                         XDATAIN[7 : 0] != 180)) 
                  begin
                     if (TXVALID && TXREADY)
                       begin
                          protocolError("ERROR: The current usb protocol is for an usb slave, only a master can transmit from idle state");
                          isMaster = 1;
                          @(negedge XCLK);
                       end
                    else
                      begin
                         protocolState = idle_state;
                         @(negedge XCLK);
                      end
                  end
                else if (XDATAIN[7 : 0] == 105 || XDATAIN[7 : 0] == 225 ||
                         XDATAIN[7 : 0] == 45 || XDATAIN[7 : 0] == 165 ||
                         XDATAIN[7 : 0] == 180) 
                begin
                   protocolState = state_0;
                   end_point = XDATAIN[15 : 15];
                   address = XDATAIN[14 : 8];
                   
                   (* IN_PACKET *)
                   (* OUT_PACKET *)
                   (* SETUP_PACKET *)
                   (* SOF_PACKET *)
                   (* PING_PACKET *)
                   start_transaction(address, mode, endpoint_type, 2);   
                end
       
                else 
                begin
                   protocolError("ERROR:\tprotocol usb sequence is wrong, in state idle_state\n\tthere is no transition that possible");
                   @(negedge XCLK);
                end
            end
            
            state_0 : 
              begin
                end_point = XDATAIN[15 : 15];
                address = XDATAIN[14 : 8];
                if (XDATAIN[7 : 0] == 105) 
                begin
                    protocolState = state_6;
                    (* IN_PACKET *)
                    receive_in_token_packet(address, mode, endpoint_type);
                    @(negedge XCLK);
                end
                else if (XDATAIN[7 : 0] == 225) 
                begin
                    protocolState = state_14;
                    (* OUT_PACKET *)
                    receive_out_token_packet(address, mode, endpoint_type);
                    @(negedge XCLK);
                end
                else if (XDATAIN[7 : 0] == 45) 
                begin
                    protocolState = state_14;
                    (* SETUP_PACKET *)
                    receive_setup_token_packet(address, mode, endpoint_type);
                    @(negedge XCLK);
                end
                else if (XDATAIN[7 : 0] == 165) 
                begin
                    protocolState = state_35;
                    (* SOF_PACKET *)
                    receive_sof_token_packet(address, mode, endpoint_type);
                    @(negedge XCLK);
                end
                else if (XDATAIN[7 : 0] == 180) // PING
                begin
                    protocolState = state_36;
                    (* PING_PACKET *)
                    receive_ping_packet(address, mode, endpoint_type);
                    @(negedge XCLK);
                end
            end
            
            state_6 : 	//state: state_6
            begin
                if (!RXVALID) 
                begin
                    protocolState = state_6;
                    @(negedge XCLK);
                end
                else if (RXVALID) 
                begin
                    protocolState = state_8;
                   
                   end_point = (XDATAIN[2 : 0] << 1) + end_point;
                    receive_control_data(end_point);
                    @(negedge XCLK);
                end
                else 
                begin
                   protocolError("ERROR:\tprotocol usb sequence is wrong, in state state_6\n\tthere is no transition that possible");
                   @(negedge XCLK);
                end
            end
            
            state_8 : 	//state: state_8
            begin
                if (TXVALID === 0 && RXACTIVE === 0) 
                begin
                    protocolState = state_8;
                    @(negedge XCLK);
                end
                else if (RXACTIVE) 
                begin
                    protocolState = idle_state;
                    no_handshake();
                end
                else if (TXVALID) 
                begin
                    @(negedge XCLK);
                    if (XDATAOUT[7 : 0] == 15 || XDATAOUT[7 : 0] == 135 || XDATAOUT[7 : 0] == 75 || XDATAOUT[7 : 0] == 195) 
                    begin
                        protocolState = state_9;
                        transmit_data_packet(XDATAOUT);
                        @(negedge XCLK);
                    end
                    else if (XDATAOUT[7 : 0] == 90 || XDATAOUT[7 : 0] == 30 || XDATAOUT[7 : 0] == 150) 
                    begin
                        protocolState = idle_state;
                        
                        transmit_handshake_packet(XDATAOUT);
                        @(negedge XCLK);
                    end
                    
                
                end
                else 
                begin
                   protocolError("ERROR:\tprotocol usb sequence is wrong, in state state_8\n\tthere is no transition that possible");
                   @(negedge XCLK);
                end
            end
            
            state_9 : 	//state: state_9
            begin
                if (!TXVALID) 
                begin
                    protocolState = state_11;
                    hSize = (XDATAOUT[7:0] == XDATAOUT[15:8]);
                    end_trans_data(hSize);
                    @(negedge XCLK);
                end
                else if (!TXREADY) 
                begin
                    protocolState = state_9;
                    @(negedge XCLK);
                end
                else begin
                    protocolState = state_9;
                    transmit_data(XDATAOUT);
                    @(negedge XCLK);
                end
            end
            
            state_11 : 	//state: state_11
              begin
                if (endpoint_type == `ISOCHRONOUS)
                    // || RXVALID && ( XDATAIN[7 : 0] == 45 || XDATAIN[7 : 0] == 105 || XDATAIN[7 : 0] == 225 || XDATAIN[7 : 0] == 165 ))
                begin
                   protocolState = idle_state;
                   master_no_handshake();
                end
                else if (!RXVALID || !RXACTIVE) 
                begin
                    protocolState = state_11;
                    @(negedge XCLK);
                end
                else if (RXVALID && ( XDATAIN[7 : 0] == 210 || XDATAIN[7 : 0] == 90 || XDATAIN[7 : 0] == 30 || XDATAIN[7 : 0] == 150 )) // handshake
                begin
                    protocolState = idle_state;
                    receive_handshake_packet(XDATAIN);
                    @(negedge XCLK);
                end
                else
                  if (endpoint_type == `BULK && (XDATAIN[7 : 0] == 105 || XDATAIN[7 : 0] == 225)) 
                    begin
                       protocolState = idle_state;
                       master_continue_bulk();
                    end
                 else
                   begin
                      
                      protocolError("protocol usb sequence is wrong, in state state_11\n\tthere is no transition that possible");
                      @(negedge XCLK);
                   end
            end
            
            state_14 : 	//state: state_14
            begin
                if (!RXVALID) 
                begin
                    protocolState = state_14;
                    @(negedge XCLK);
                end
                else if (RXVALID) 
                begin
                    protocolState = state_16;
                   end_point = (XDATAIN[2 : 0] << 1) + end_point;
                    receive_control_data(end_point);
                    @(negedge XCLK);
                end
                else 
                begin
                   protocolError("protocol usb sequence is wrong, in state state_14\n\tthere is no transition that possible");
                   @(negedge XCLK);
                end
            end
              
            state_16 : 	//state: state_16
            begin
                if (!RXACTIVE || !RXVALID) 
                begin
                    protocolState = state_16;
                    @(negedge XCLK);
                end
                else if ( RXVALID && (XDATAIN[7 : 0] == 195 || XDATAIN[7 : 0] == 75 || XDATAIN[7 : 0] == 135 || XDATAIN[7 : 0] == 15) )
                  begin
                    protocolState = state_17;
                    receive_data_packet(XDATAIN);
                    @(negedge XCLK);
                  end
                else
                  begin
                     protocolState = idle_state;
                     invalid_packet();
                  end
               
            end
            
            state_17 : 	//state: state_17
              begin
                if (RXVALID) 
                begin
                    protocolState = state_17;
                    receive_data(XDATAIN);
                    @(negedge XCLK);
                end
                else if (!RXACTIVE && ((hs && LINESTATE[1:0] == 0) || (fs && LINESTATE[1:0] == 1)))
                begin
                    protocolState = state_18;
                    hSize = (XDATAIN[7:0] == XDATAIN[15:8]);
                    end_receive_data(hSize);
                end
                else begin
                    protocolState = state_17;
                    @(negedge XCLK);
                end
            end
            
            state_18 : 	//state: state_18
              begin
                if (endpoint_type == `ISOCHRONOUS)
                begin
                   protocolState = idle_state;
                   no_handshake();
                end
                else if (TXVALID === 0 && RXACTIVE === 0) 
                begin
                    protocolState = state_18;
                    @(negedge XCLK);
                end
                else if (TXVALID) 
                begin
                    @(negedge XCLK);
                    if (XDATAOUT[7 : 0] == 210 || XDATAOUT[7 : 0] == 90 || XDATAOUT[7 : 0] == 30 || XDATAOUT[7 : 0] == 150) 
                    begin
                        protocolState = idle_state;
                        transmit_handshake_packet(XDATAOUT);
                        @(negedge XCLK);
                    end
                    
                
                end
                else if (!RXVALID)
                  begin
                    protocolState = state_18;
                    @(negedge XCLK); 
                  end
                else if (endpoint_type == `BULK && (XDATAIN[7 : 0] == 225 || XDATAIN[7 : 0] == 105))                   begin
                     protocolState = idle_state;
                     continue_bulk();
                  end
                 else
                   begin
                      protocolError("protocol usb sequence is wrong, in state state_18\n\tthere is no transition that possible");
                      @(negedge XCLK);
                   end
            end
            
            state_35 : 	//state: state_35
              begin
                if (!RXVALID) 
                begin
                    protocolState = state_35;
                    @(negedge XCLK);
                end
                else begin
                    protocolState = idle_state;
                   end_point = (XDATAIN[2 : 0] << 1) + end_point;
                    receive_control_data(end_point);
                end
              end // case: state_35

         state_36 : 	//state: state_36
            begin
                if (!RXVALID) 
                begin
                    protocolState = state_36;
                    @(negedge XCLK);
                end
                else if (RXVALID) 
                begin
                    protocolState = state_37;
                   end_point = (XDATAIN[2 : 0] << 1) + end_point;
                    receive_control_data(end_point);
                    @(negedge XCLK);
                end
                else 
                begin
                    protocolError("protocol usb sequence is wrong, in state state_14\n\tthere is no transition that possible");
                    @(negedge XCLK);
                end
            end
            
            state_37 : 	//state: state_37
              begin
                
                if (RXACTIVE)
                begin
                   protocolState = idle_state;
                   no_handshake();
                end
                else if (TXVALID === 0 && RXACTIVE === 0) 
                begin
                    protocolState = state_37;
                    @(negedge XCLK);
                end
                else if (TXVALID) 
                begin
                    @(negedge XCLK);
                    if (XDATAOUT[7 : 0] == 210 || XDATAOUT[7 : 0] == 90 || XDATAOUT[7 : 0] == 30 || XDATAOUT[7 : 0] == 150) 
                    begin
                        protocolState = idle_state;
                        transmit_handshake_packet(XDATAOUT);
                        @(negedge XCLK);
                    end
                    
                
                end
                
                else 
                begin
                    protocolError("protocol usb sequence is wrong, in state state_37\n\tthere is no transition that possible");
                    @(negedge XCLK);
                end
            end
        endcase

end
endmodule
