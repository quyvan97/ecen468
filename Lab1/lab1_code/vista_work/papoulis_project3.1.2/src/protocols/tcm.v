
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

(* bus_master *)
(* bus_slave *)
module tcm #(parameter ADDR_WIDTH = 15, parameter DATA_WIDTH = 72, parameter CYCLE_ACCURATE = 0)
  (
    (* clock  *)                         input CLK,
    (* master *)                         input TCMCS,
    (* master *) (* default_value = 0 *) input TCMnRW,
    (* master *) (* address *)           input [ADDR_WIDTH-1:0] TCMADDR,
    (* slave  *)                         input [DATA_WIDTH-1:0] TCMRD,
    (* master *)                         input [DATA_WIDTH-1:0] TCMWD,
    (* master *) (* default_value = 1 *) input [7:0] TCMWE,
    (* slave  *) (* default_value = 0 *) input TCMWAIT
  );

  reg past_TCMWAIT;

  (* master *)
  function void REQUEST ();
`ifdef DEBUG
    $display ("%0t/I, %m :- REQUEST ()", $time);
`endif
  endfunction

  (* master *)
  function void READ_REQ (int TCMADDR);
`ifdef DEBUG
    $display ("%0t/I, %m :- READ_REQ (TCMADDR=%h)", $time, TCMADDR);
`endif
  endfunction

  (* slave *)
  function void read_ack (int TCMRD, int BSize);
`ifdef DEBUG
    $display ("%0t/O, %m :- read_ack (TCMRD=%h)", $time, TCMRD);
`endif
  endfunction

  (* master *)
  function void WRITE_REQ (int TCMADDR, int TCMWD, int TCMWE, int BSize);
`ifdef DEBUG
    $display ("%0t/I, %m :- WRITE_REQ (TCMADDR=%h TCMWD=%h TCMWE=%h)", $time, TCMADDR, TCMWD, TCMWE);
`endif
  endfunction

  (* slave *)
  function void write_ack ();
`ifdef DEBUG
    $display ("%0t/O, %m :- write_ack ()", $time);
`endif
  endfunction

  (* master *)
  function void END_READ_TRANSACTION ();
`ifdef DEBUG
    $display ("%0t/I, %m :- END_READ_TRANSACTION ()", $time);
`endif
  endfunction

  (* master *)
  function void END_WRITE_TRANSACTION ();
`ifdef DEBUG
    $display ("%0t/I, %m :- END_WRITE_TRANSACTION ()", $time);
`endif
  endfunction

  (* master *)
  function void idle ();
`ifdef DEBUG
    $display ("%0t/I, %m :- idle ()", $time);
`endif
  endfunction

  (* transaction *) (* default_read *)
  function void READ (int TCMADDR, input int TCMRD [], (* block_size *) (* default_value = 1 *) int BSize);
  endfunction

  (* transaction *) (* default_write *)
  function void WRITE (int TCMADDR, output int TCMWD [], output int TCMWE, (* block_size *) (* default_value = 1 *) int BSize);
  endfunction

  (* transaction *)
  function void IDLE_CYCLE ();
  endfunction

  (* protocol_error *)
  function void protocolError (input string error);
    $display ($time, " --> ERROR in %m");
    $display (error);
  endfunction

  typedef enum {
    IDLE,
    BRANCH,
    READ_WAIT,
    WRITE_WAIT
  } PROTOCOL_STATES;

  PROTOCOL_STATES protocolState;

  (* protocol_initial *)
  initial
    protocolState = IDLE;

  (* protocol_SM *)
  always
  begin

    case (protocolState)

      IDLE :
      begin
        if (TCMCS !== 1'bx)
        begin
          protocolState = BRANCH;
          (* READ *) (* WRITE *) (* IDLE_CYCLE *)
          REQUEST ();
        end
        else
        begin
          protocolState = IDLE;
          @ (negedge CLK);
        end
      end

      BRANCH :
      begin
        if (TCMCS != 1)
        begin
          (* IDLE_CYCLE *)
          idle ();
          protocolState = IDLE;
          @ (negedge CLK);
        end
        else if (TCMnRW == 0 && TCMWE == 0)
        begin
          past_TCMWAIT = TCMWAIT;
          protocolState = READ_WAIT;
          (* READ *)
          READ_REQ (TCMADDR);
          @ (negedge CLK);
        end
        else if (TCMnRW == 1)
        begin
          past_TCMWAIT = TCMWAIT;
          protocolState = WRITE_WAIT;
          (* WRITE *)
          WRITE_REQ (TCMADDR, TCMWD, TCMWE, 1);
          @ (negedge CLK);
        end
        else
        begin
          protocolError ("protocol tcm sequence is wrong in state BRANCH");
          @ (negedge CLK);
        end
      end

      READ_WAIT :
      begin
        if (past_TCMWAIT == 1)
        begin
          past_TCMWAIT = TCMWAIT;
          protocolState = READ_WAIT;
          @ (negedge CLK);
        end
        else
        begin
          protocolState = IDLE;
          read_ack (TCMRD, 1);
        end
      end

      WRITE_WAIT :
      begin
        if (past_TCMWAIT == 1)
        begin
          past_TCMWAIT = TCMWAIT;
          protocolState = WRITE_WAIT;
          @ (negedge CLK);
        end
        else
        begin
          protocolState = IDLE;
          write_ack ();
        end
      end

    endcase

  end

endmodule

