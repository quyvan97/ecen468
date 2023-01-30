
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


(* bus_slave *)
(* bus_master *)
module apb
  (
    (* clock   *)                         input PCLK,
    (* master  *) (* address *)           input [31 : 0] PADDR,
    (* master  *)                         input PWRITE,
    (* master  *)                         input PSEL,
    (* master  *)                         input PENABLE,
    (* master  *)                         input [31 : 0] PWDATA,
    (* slave   *)                         input [31 : 0] PRDATA,
    (* slave   *) (* default_value = 1 *) input PREADY,
    (* slave   *) (* default_value = 0 *) input PSLVERROR
  );

  (* master *)
  function void READ_REQ (int PADDR, int block_size);
    $display ("%0t/I, %m :- READ_REQ(PADDR=%0h, block_size=%0d)", $time, PADDR, block_size);
  endfunction

  (* slave *)
  function void read_ack (int PRDATA);
    $display ("%0t/O, %m :- read_ack(PRDATA=%0h)", $time, PRDATA);
  endfunction

  (* slave *)
  function void read_error ();
    $display ("%0t/O, %m :- read_error()", $time);
  endfunction

  (* master *)
  function void WRITE_REQ (int PADDR, int PWDATA, int block_size);
    $display ("%0t/I, %m :- WRITE_REQ(PADDR=%0h, PWDATA=%0h, block_size=%0d)", $time, PADDR, PWDATA, block_size);
  endfunction

  (* slave *)
  function void write_ack ();
    $display ("%0t/O, %m :- write_ack()", $time);
  endfunction

  (* slave *)
  function void write_error ();
    $display ("%0t/O, %m :- write_error()", $time);
  endfunction

  (* master *)
  function void END_TRANSACTION ();
    $display ("%0t/I, %m :- END_TRANSACTION()", $time);
    $display (" ");
  endfunction

  (* transaction *) (* default_read *)
  function void READ (int PADDR, input int PRDATA [], (* block_size *) int block_size);
  endfunction

  (* transaction *) (* default_write *)
  function void WRITE (int PADDR, output int PWDATA [], (* block_size *) int block_size);
  endfunction

  (* protocol_error *)
  function void protocolError (input string error);
    $display ($time, " --> ERROR in %m");
    $display (error);
  endfunction

  typedef enum {
    IDLE,
    ENABLE_READ,
    ENABLE_WRITE,
    STANDBY_READ,
    STANDBY_WRITE
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
        if (PSEL !== 1'b1)
        begin
          protocolState = IDLE;
          @ (negedge PCLK);
        end
        else if (PWRITE == 1'b0)
        begin
          protocolState = ENABLE_READ;
          (* READ *)
          READ_REQ (PADDR, 4);
          @ (negedge PCLK);
        end
        else if (PWRITE == 1'b1)
        begin
          protocolState = ENABLE_WRITE;
          (* WRITE *)
          WRITE_REQ (PADDR, PWDATA, 4);
          @ (negedge PCLK);
        end
        else
        begin
          protocolError ("protocol apb sequence is wrong in state IDLE");
          @ (negedge PCLK);
        end
      end

      ENABLE_READ :
      begin
        if (PREADY == 1'b0)
        begin
          protocolState = ENABLE_READ;
          @ (negedge PCLK);
        end
        else if (PSLVERROR == 1'b1)
        begin
          protocolState = STANDBY_READ;
          read_error ();
          @ (negedge PCLK);
        end
        else if (PENABLE && PWRITE == 1'b0)
        begin
          protocolState = STANDBY_READ;
          read_ack (PRDATA);
          @ (negedge PCLK);
        end
        else
        begin
          protocolError ("protocol apb sequence is wrong in state ENABLE_READ");
          @ (negedge PCLK);
        end
      end

      ENABLE_WRITE :
      begin
        if (PREADY == 1'b0)
        begin
          protocolState = ENABLE_WRITE;
          @ (negedge PCLK);
        end
        else if (PSLVERROR == 1'b1)
        begin
          protocolState = STANDBY_WRITE;
          write_error ();
          @ (negedge PCLK);
        end
        else if (PENABLE && PWRITE == 1'b1)
        begin
          protocolState = STANDBY_WRITE;
          write_ack ();
          @ (negedge PCLK);
        end
        else
        begin
          protocolError ("protocol apb sequence is wrong in state ENABLE_WRITE");
          @ (negedge PCLK);
        end
      end

      STANDBY_READ :
      begin
        if (PSEL !== 1'b1)
        begin
          protocolState = IDLE;
          END_TRANSACTION ();
          @ (negedge PCLK);
        end
        else if (PWRITE == 1'b0)
        begin
          protocolState = ENABLE_READ;
          READ_REQ (PADDR, 4);
          @ (negedge PCLK);
        end
        else
        begin
          protocolError ("protocol apb sequence is wrong in %m state STANDBY_READ");
          @ (negedge PCLK);
        end
      end

      STANDBY_WRITE :
      begin
        if (PSEL !== 1'b1)
        begin
          protocolState = IDLE;
          END_TRANSACTION ();
          @ (negedge PCLK);
        end
        else if (PWRITE == 1'b1)
        begin
          protocolState = ENABLE_WRITE;
          WRITE_REQ (PADDR, PWDATA, 4);
          @ (negedge PCLK);
        end
        else
        begin
          protocolError ("protocol apb sequence is wrong in %m state STANDBY_WRITE");
          @ (negedge PCLK);
        end
      end

    endcase

  end

endmodule

