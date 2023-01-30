
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

`include "ahb_define.v"
`timescale 1 ps / 1 ps

(* bus_slave *)
module ahb_slave
    (
        (* master *)                         input HSEL, 
        (* master *)                         input [1 : 0] HTRANS, 
        (* master *)                         input HWRITE, 
        (* master *) (* address *)           input [63 : 0] HADDR, 
        (* master *) (* default_value = 2 *) input [2 : 0] HSIZE, 
        (* slave  *) (* default_value = 0 *) input [1 : 0] HRESP, 
        (* slave  *)                         input [63 : 0] HRDATA, 
        (* master *)                         input [63 : 0] HWDATA, 
        (* master *) (* default_value = 0 *) input [2 : 0] HBURST, 
        (* slave  *)                         input HREADY,
        (* clock  *)                         input CLK
    );
   
    typedef enum {
        wait_nonseq_req, 
        wait_write_ack, 
        seq_write_or_end, 
        wait_read_ack,
        write_data,
        end_sequence,
        seq_read_or_end
        } PROTOCOL_STATES;



    (* master *)
    function void NONSEQ_WRITE_REQ(longint HADDR, int HSIZE, int HBURST, int block_size);
    endfunction // void
   
    (* master *)
    function void WRITE_DATA(longint HWDATA);
    endfunction // void
   
    (* master *)
    function void SEQ_WRITE_REQ(longint HADDR, int HSIZE, int block_size);
    endfunction

    (* master *)
    function void NONSEQ_READ_REQ(longint HADDR, int HSIZE, int HBURST, int block_size);
    endfunction
   
    (* master *)
    function void SEQ_READ_REQ(longint HADDR, int HSIZE, int block_size);
    endfunction
    
    (* slave  *)
    function void write_ack();
    endfunction
    
    (* slave  *) (* error *)
    function void bus_error();
    endfunction

    (* slave  *)
    function void bus_split();
    endfunction

    (* slave  *)
    function void bus_retry();
    endfunction
   
    (* master *)
    function void END_TRANSACTION();
    endfunction
    
    (* slave *)
    function void read_ack(longint HRDATA);
    endfunction

    (* transaction *)
    function void READ((* address *) longint HADDR, input longint HRDATA[], (* block_size *) int block_size, (* default_value = 2 *) int HSIZE);
    endfunction

    (* transaction *)
    function void WRITE((* address *) longint HADDR, output longint HWDATA[], (* block_size *) int block_size, (* default_value = 2 *) int HSIZE);
    endfunction

   (* protocol_error *)
      function void protocolError(input string str);
      $display(str);
      endfunction
      

    PROTOCOL_STATES protocolState;

reg [2:0] HSIZE_reg;
   int i;
   
always @(HSIZE)
  begin
     HSIZE_reg = HSIZE;
     for(i = 0; i <= 2 ; i++)
       begin
	  if(HSIZE_reg[i] === 1'bz)
	    begin
               HSIZE_reg[i] = 1'b0;
	    end
       end
  end
   
 
  
(* protocol_initial *)    
initial
        protocolState = wait_nonseq_req;

(* protocol_SM *)
always
   begin
        case(protocolState)
            //idle state
            wait_nonseq_req :
            begin

               if (HSEL && HTRANS == `NONSEQ && HWRITE == `WRITE) 
                 begin
                    protocolState = write_data;	
                    (* WRITE *)
                    NONSEQ_WRITE_REQ(HADDR, HSIZE_reg, HBURST, 1 << HSIZE_reg);
                    @(negedge CLK);
                 end
               else if (HSEL && HTRANS == `NONSEQ && HWRITE == `READ) 
                 begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    (* READ *)
                    NONSEQ_READ_REQ(HADDR, HSIZE_reg, HBURST, 1 << HSIZE_reg);
                    @(negedge CLK);
                 end
               else if (HSEL !== 1'b1) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    @(negedge CLK);
                end
                else if (HSEL && HTRANS == `IDLE) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                     @(negedge CLK);
                end
                else 
                begin
                    $display("protocol ahb_slave sequence is wrong, in state wait_nonseq_req\n");
                    $display("\tthere is no transition that possible at time: ", $time, "\n");
                    @(negedge CLK);
                end
            end

            write_data:
              begin
                 protocolState = wait_write_ack;	//transition to state: wait_write_ack
                 WRITE_DATA(HWDATA);
              end
          
            wait_write_ack : 	//state: wait_write_ack
            begin
                if (!HREADY) 
                begin
                    protocolState = wait_write_ack;	//transition to state: wait_write_ack
                    @(negedge CLK);
                end
                else if (HRESP == `OKAY)
                  begin
                    protocolState = seq_write_or_end;	
                    write_ack();
                  end
                else if (HRESP == `ERROR)
                  begin
                     protocolState = end_sequence;
                     
                     bus_error();
                  end
                else if (HRESP == `RETRY)
                  begin
                     protocolState = end_sequence;
                     bus_retry();
                  end
               else if (HRESP == `SPLIT)
                  begin
                     protocolState = end_sequence;
                     bus_split();
                  end
            end
            
            seq_write_or_end : 	//state: seq_write_or_end
            begin
                if (HSEL && HTRANS == `BUSY) 
                begin
                    protocolState = seq_write_or_end;	//step the BUSY state
                    @(negedge CLK);
                end
                else if (( HSEL && HTRANS == `NONSEQ ) || HTRANS == `IDLE || !HSEL) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    END_TRANSACTION();
                end
                else begin
                    protocolState = write_data;	
                    SEQ_WRITE_REQ(HADDR, HSIZE_reg, 1 << HSIZE_reg);
                    @(negedge CLK);
                end
            end 
  
            
            wait_read_ack : 	//state: wait_read_ack
            begin
                if (!HREADY) 
                begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    @(negedge CLK);
                end
                else if (HRESP == `OKAY)
                  begin
                    protocolState = seq_read_or_end;	//transition to state: seq_read_or_end
                    read_ack(HRDATA);
                end
                else if (HRESP == `ERROR)
                  begin
                     protocolState = end_sequence;
                     
                     bus_error();
                  end
                else if (HRESP == `RETRY)
                  begin
                     protocolState = end_sequence;
                     bus_retry();
                  end
                else if (HRESP == `SPLIT)
                  begin
                     protocolState = end_sequence;
                     bus_split();
                  end
            end
            
            seq_read_or_end : 	//state: seq_read_or_end
            begin
                if (HSEL && HTRANS == `BUSY) 
                begin
                    protocolState = seq_read_or_end;	//step the BUSY state
                    @(negedge CLK);
                end
                else if (( HSEL && HTRANS == `NONSEQ ) || HTRANS == `IDLE || !HSEL) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    END_TRANSACTION();
                end
                else begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    SEQ_READ_REQ(HADDR, HSIZE_reg, 1 << HSIZE_reg);
                    @(negedge CLK);
                end
            end // case: seq_read_or_end

            end_sequence : 	
            begin
                if (( HSEL && HTRANS == `NONSEQ ) || HTRANS == `IDLE || !HSEL) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    END_TRANSACTION();
                end
                else 
                  begin
                    $display("protocol ahb_slave sequence is wrong, in state end_read\n");
                    $display("\tthere is no transition that possible at time: ", $time, "\n");
                    @(negedge CLK);
                  end
            end 
        endcase
    end

endmodule
