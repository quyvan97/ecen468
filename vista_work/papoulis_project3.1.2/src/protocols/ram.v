
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
module ram #(parameter ADDR_WIDTH = 19, DATA_WIDTH = 8)

  (
    (* clock  *)                         input clk,
    (* master *)                         input ram_we,
    (* master *) (* address *)           input [ADDR_WIDTH-1 : 0] ram_addr,
    (* master *) (* default_value = 0 *) input [DATA_WIDTH-1 : 0] ram_data_in,
    (* slave *)  (* default_value = 0 *) input [DATA_WIDTH-1 : 0] ram_data_out
  );

  (* master *)
  function void NONSEQ_WRITE (int ram_addr, int ram_data_in, int block_size);
    $display ("%0t/I, %m :- NONSEQ_WRITE(ram_addr=%0h, ram_data_in=%0h)", $time, ram_addr, ram_data_in);
  endfunction

  (* master *)
  function void SEQ_WRITE (int ram_addr, int ram_data_in, int block_size);
    $display ("%0t/I, %m :- SEQ_WRITE(ram_addr=%0h, ram_data_in=%0h)", $time, ram_addr, ram_data_in);
  endfunction

  (* slave *)
  function void nonseq_write_ack ();
    $display ("%0t/O, %m :- nonseq_write_ack()", $time);
  endfunction

  (* slave *)
  function void seq_write_ack (int addr_count);
    $display ("%0t/O, %m :- seq_write_ack(addr_count=%0h)", $time, addr_count);
  endfunction

  (* master *)
  function void NONSEQ_READ (int ram_addr, int block_size);
    $display ("%0t/I, %m :- NONSEQ_READ(ram_addr=%0h)", $time, ram_addr);
  endfunction

  (* master *)
  function void SEQ_READ (int ram_addr, int block_size);
    $display ("%0t/I, %m :- SEQ_READ(ram_addr=%0h)", $time, ram_addr);
  endfunction

  (* slave *)
  function void nonseq_read_ack (int ram_data_out);
    $display ("%0t/O, %m :- nonseq_read_ack(ram_data_out=%0h)", $time, ram_data_out);
  endfunction

  (* slave *)
  function void seq_read_ack (int ram_data_out, int addr_count);
    $display ("%0t/O, %m :- seq_read_ack(ram_data_out=%0h, addr_count=%0h)", $time, ram_data_out, addr_count);
  endfunction

  (* master *)
  function void END_TRANSACTION ();
    $display ("%0t/I, %m :- END_TRANSACTION()", $time);
  endfunction

  (* transaction *) (* default_write *)
  function void WRITE (int ram_addr, output int ram_data_in[], (* default_value = 1 *) (* block_size *) int block_size);
  endfunction

  (* transaction *) (* default_read *)
  function void READ (int ram_addr, input int ram_data_out[], (* default_value = 1 *) (* block_size *) int block_size);
  endfunction

  (* protocol_error *)
  function void protocolError (input string error);
    $display ($time, " --> ERROR in %m");
    $display (error);
  endfunction

  reg [ADDR_WIDTH-1 : 0] start_ram_addr;
  reg [ADDR_WIDTH-1 : 0] addr_count;

  typedef enum {
    IDLE,
    NONSEQ_WRITE_STATE, WRITE_LOOP_STATE, SEQ_WRITE_STATE,
    NONSEQ_READ_STATE,  READ_LOOP_STATE,  SEQ_READ_STATE
  } PROTOCOL_STATES;

  PROTOCOL_STATES protocolState;

  (* protocol_initial *)
  initial protocolState = IDLE;

  (* protocol_SM *)
  always
  begin
    case (protocolState)

      IDLE :
      begin
        if ( (|ram_addr === 1'b0) || (|ram_addr === 1'bX) || (|ram_addr === 1'bZ) )
        begin
          protocolState = IDLE;
          @ (negedge clk);
        end
        else if (ram_we == 1'b1)
        begin
          protocolState = NONSEQ_WRITE_STATE;
          start_ram_addr = ram_addr;
          (* WRITE *)
          NONSEQ_WRITE (ram_addr, ram_data_in, 1);
          @ (negedge clk);
        end
        else if (ram_we == 1'b0)
        begin
          protocolState = NONSEQ_READ_STATE;
          start_ram_addr = ram_addr;
          (* READ *)
          NONSEQ_READ (ram_addr, 1);
          @ (negedge clk);
        end
        else
        begin
          protocolError ("protocol ram sequence is wrong in state IDLE");
          @ (negedge clk);
        end
      end

      NONSEQ_WRITE_STATE :
      begin
        protocolState = WRITE_LOOP_STATE;
        addr_count = 1'b0;
        nonseq_write_ack ();
        @ (negedge clk);
      end

      WRITE_LOOP_STATE :
      begin
        if ( (|ram_addr === 1'b0) || (|ram_addr === 1'bX) || (|ram_addr === 1'bZ) )
        begin
          protocolState = WRITE_LOOP_STATE;
          @ (negedge clk);
        end
        else if ( (ram_addr == start_ram_addr + addr_count + 1'b1) /* && (addr_count < 'h40) */ )
        begin
          protocolState = SEQ_WRITE_STATE;
          SEQ_WRITE (ram_addr, ram_data_in, 1);
          @ (negedge clk);
        end
        else
        begin
          protocolState = IDLE;
          END_TRANSACTION ();
        end
      end

      SEQ_WRITE_STATE :
      begin
        protocolState = WRITE_LOOP_STATE;
        addr_count = addr_count + 1'b1;
        seq_write_ack (addr_count);
        @ (negedge clk);
      end

      NONSEQ_READ_STATE :
      begin
        protocolState = READ_LOOP_STATE;
        addr_count = 1'b0;
        nonseq_read_ack (ram_data_out);
        @ (negedge clk);
      end

      READ_LOOP_STATE :
      begin
        if ( (|ram_addr === 1'b0) || (|ram_addr === 1'bX) || (|ram_addr === 1'bZ) )
        begin
          protocolState = READ_LOOP_STATE;
          @ (negedge clk);
        end
        else if ( (ram_addr == start_ram_addr + addr_count + 1'b1) /* && (addr_count < 'h40) */ )
        begin
          protocolState = SEQ_READ_STATE;
          SEQ_READ (ram_addr, 1);
          @ (negedge clk);
        end
        else
        begin
          protocolState = IDLE;
          END_TRANSACTION ();
        end
      end

      SEQ_READ_STATE :
      begin
        protocolState = READ_LOOP_STATE;
        addr_count = addr_count + 1'b1;
        seq_read_ack (ram_data_out, addr_count);
        @ (negedge clk);
      end

    endcase

  end

endmodule

