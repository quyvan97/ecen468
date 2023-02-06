
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
module rendezvous
    (
     (* clock  *) input CLK
    );

    (* master *)
    function void start_send_token(int tokenId, int tokenSize, int tokenAddress);
    endfunction

    (* slave *)
    function void end_receive_token(int tokenId, int tokenSize, int tokenAddress);
    endfunction // void

    (* transaction *)
    function void TOKEN_TRANSACTION(int tokenId, int tokenSize, int tokenAddress);
    endfunction // void


    typedef enum {
        state_0,
        state_1
    } PROTOCOL_STATES;


    PROTOCOL_STATES protocolState;

(* protocol_initial *)
initial
        protocolState = state_0;


(* protocol_SM *)
always

begin
        case(protocolState)

            //idle state
            state_0 :
            begin

                begin
                    protocolState = state_1;    //transition to state: state_1
                    (* TOKEN_TRANSACTION *)
                    start_send_token(0, 0, 0);
                    @(negedge CLK);
                end

            end

            state_1 : 
            begin

                begin
                    protocolState = state_0;    //transition to state: state_0
                    end_receive_token(0, 0, 0);
                    @(negedge CLK);
                end

            end
        endcase
end
endmodule
