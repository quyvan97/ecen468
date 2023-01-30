
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
(* bus_master *)
(* bus_split_policy = "ahb_bus_policy" *) 
module ahb_master
    (
        (* clock  *)                         input CLK, 
        (* master *) (* default_value = 1 *) input HBUSREQ, 
        (* slave  *) (* default_value = 1 *) input HGRANT, 
        (* master *) (* default_value = 0 *) input HLOCK, 
        (* master *) (* default_value = 0 *) input [2 : 0] HBURST, 
        (* master *)                         input [1 : 0] HTRANS, 
        (* master *) (* address *)           input [63 : 0] HADDR, 
        (* master *) (* default_value = 2 *) input [2 : 0] HSIZE, 
        (* master *)                         input HWRITE, 
        (* slave  *)                         input HREADY, 
        (* slave  *) (* default_value = 0 *) input [1 : 0] HRESP, 
        (* slave  *)                         input [63 : 0] HRDATA, 
        (* master *)                         input [63 : 0] HWDATA
    );
   
    (* master *)
    function void BUS_REQ(int HLOCK);
    endfunction

    (* master *) 
    function void NONSEQ_READ_REQ(longint HADDR, int HSIZE, int HBURST, int block_size);
    endfunction
   
    (* master *) 
    function void SEQ_READ_REQ();
    endfunction

    (* master *) 
    function void NONSEQ_WRITE_REQ(longint HADDR, int HSIZE, int HBURST, int block_size);
    endfunction
   
    (* master *) 
    function void SEQ_WRITE_REQ();
    endfunction

    (* master *) 
    function void WRITE_DATA(longint HWDATA);
    endfunction
   
    (* slave  *)
    function void bus_grant();
    endfunction
    
    (* slave  *)
    function void read_ack_grant(longint HRDATA);
    endfunction
    
    (* slave  *)
    function void read_ack_no_grant(longint HRDATA);
    endfunction
    
    (* master *)
    function void END_TRANSACTION();
    endfunction

    (* slave  *)  (* error *)
    function void bus_error();
    endfunction
    
    (* slave  *)
    function void bus_retry();
    endfunction

    (* slave  *)
    function void bus_split();
    endfunction
   
    (* slave  *)
    function void write_ack_grant();
    endfunction
    
    (* slave  *)
    function void write_ack_no_grant();
    endfunction
    
   (* transaction *)
   function void READ(longint HADDR, input longint HRDATA[], (* block_size *) int block_size, (* default_value = 2 *) int HSIZE, (* default_value = 0 *) int HLOCK);
   endfunction

   (* transaction *)
   function void WRITE(longint HADDR, output longint HWDATA[], (* block_size *) int block_size, (* default_value = 2 *) int HSIZE, (* default_value = 0 *) int HLOCK);
   endfunction // void

   (* protocol_error *)
     function void protocolError(input string str);
      $display(str);
      endfunction

typedef enum {
        wait_bus_req,
        wait_bus_grant,
        wait_nonseq_req,
        wait_read_ack,
        seq_read_or_end,
        wait_write_ack,
        seq_write_or_end,
        write_data,
        end_read,
        end_write
        } PROTOCOL_STATES;

        PROTOCOL_STATES protocolState;
   
   reg [2:0] HSIZE_reg;
   int i;

(* protocol_initial *)

initial 
     protocolState = wait_bus_req;

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
   
   
(* protocol_SM *)
always 
begin
        case(protocolState)
            
            //idle state
            wait_bus_req :
              begin                
                if (( HBUSREQ == 1 && !HGRANT && HTRANS == `IDLE ) || HTRANS == `NONSEQ) 
                begin
                    protocolState = wait_bus_grant;	//transition to state: wait_bus_grant
                    (*  READ *)
                    (* WRITE *)
                    BUS_REQ(HLOCK);
                end
                else begin
                    protocolState = wait_bus_req;	//transition to state: wait_bus_req
                    @(negedge CLK);
                end
            end
            
            wait_bus_grant : 	//state: wait_bus_grant
            begin
                if (HBUSREQ && ( HGRANT == 1 ) || HTRANS == `NONSEQ) 
                begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    bus_grant();
                end
                else begin
                    protocolState = wait_bus_grant;	//transition to state: wait_bus_grant
                    @(negedge CLK);
                end
            end
            
            wait_nonseq_req : 	//state: wait_nonseq_req
            begin
                if (HTRANS == `NONSEQ && HWRITE != `WRITE && HREADY) 
                begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    (* READ *)
                    NONSEQ_READ_REQ(HADDR, HSIZE_reg, HBURST, 1 << HSIZE_reg);
                    @(negedge CLK);
                end
                else if (HTRANS == `NONSEQ && HWRITE == `WRITE && HREADY)
                begin
                    protocolState = write_data;	//transition to state: write_data
                    (* WRITE *)
                    NONSEQ_WRITE_REQ(HADDR, HSIZE_reg, HBURST, 1 << HSIZE_reg);
                    @(negedge CLK);
                end     
                else begin
                    protocolState = wait_nonseq_req;	//transition to state: wait_nonseq_req
                    @(negedge CLK);
                end
            end

            write_data :
              begin
                 protocolState = wait_write_ack;
                 WRITE_DATA(HWDATA);
              end
          
            wait_read_ack : 	//state: wait_read_ack
            begin
                if (!HREADY) 
                begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    @(negedge CLK);
                end
                else if (HRESP == `ERROR)
                  begin
                     
                     bus_error();
                     protocolState = end_read;
                  end
                else if (HRESP == `SPLIT)
                  begin
                     bus_split();
                     protocolState = end_read;
                  end
                else if (HRESP == `RETRY)
                  begin
                     bus_retry();
                     protocolState = end_read;
                  end
                else if (HTRANS == `BUSY || HTRANS == `SEQ || ( HTRANS == `IDLE && HGRANT ) || ( HTRANS == `IDLE && !HBUSREQ ) || ( HTRANS == `NONSEQ && HGRANT )) 
                begin
                    protocolState = seq_read_or_end;	//transition to state: seq_read_or_end
                    read_ack_grant(HRDATA);
                end
                else if (HTRANS == `IDLE && !HGRANT && HBUSREQ) 
                begin
                    protocolState = end_read;	//transition to state: end_read
                    read_ack_no_grant(HRDATA);
                end
                else 
                  begin
                     protocolError("protocol ahb_master sequence is wrong, in state wait_read_ack\n\tthere is no transition that possible");
                    @(negedge CLK);
                end
            end
            
            seq_read_or_end : 	//state: seq_read_or_end
            begin
                if (HTRANS == `SEQ) 
                begin
                    protocolState = wait_read_ack;	//transition to state: wait_read_ack
                    SEQ_READ_REQ();
                    @(negedge CLK);
                end
                else if (HTRANS == `BUSY) 
                begin
                    protocolState = seq_read_or_end;	//step on the busy
                    @(negedge CLK);
                end
                else if (( !HBUSREQ && HTRANS == `IDLE ) || ( HGRANT && ( ( HTRANS == `NONSEQ ) || ( HTRANS == `IDLE && HBUSREQ ) ) )) 
                begin
                    protocolState = wait_bus_req;	//transition to state: wait_bus_req
                    END_TRANSACTION();
                end
                else 
                  begin
                     protocolError("protocol ahb_master sequence is wrong, in state seq_read_or_end\n\tthere is no transition that possible");
                     @(negedge CLK);
                end
            end
            
            wait_write_ack : 	//state: wait_write_ack
            begin
                if (!HREADY) 
                begin
                    protocolState = wait_write_ack;	//transition to state: wait_write_ack
                    @(negedge CLK);
                end
               else if (HRESP == `ERROR)
                 begin
                     
                     bus_error();
                     protocolState = end_write;
                  end
                else if (HRESP == `SPLIT)
                  begin
                     bus_split();
                     protocolState = end_write;
                  end
                else if (HRESP == `RETRY)
                  begin
                     bus_retry();
                     protocolState = end_write;
                  end
                else if (HTRANS == `BUSY || HTRANS == `SEQ || ( HTRANS == `IDLE && HGRANT ) || ( HTRANS == `IDLE && !HBUSREQ) || ( HTRANS == `NONSEQ && HGRANT )) 
                begin
                   protocolState = seq_write_or_end;
                   
                    write_ack_grant();
                end
                else if (HTRANS == `IDLE && !HGRANT && HBUSREQ) 
                begin
                   protocolState = end_write;
                   write_ack_no_grant();
                end
                else 
                  begin
                     protocolError("protocol ahb_master sequence is wrong, in state wait_write_ack\n\tthere is no transition that possible");
                    @(negedge CLK);
                end
            end
            
            seq_write_or_end : 	//state: seq_write_or_end
              begin
                if (HTRANS == `SEQ) 
                begin
                    protocolState = write_data;	
                    SEQ_WRITE_REQ();
                    @(negedge CLK);
                end
                else if (HTRANS == `BUSY) 
                begin
                    protocolState = seq_write_or_end;	//step on the busy
                    @(negedge CLK);
                end
                else if (( !HBUSREQ && HTRANS == `IDLE ) || ( HGRANT && ( ( HTRANS == `NONSEQ ) || ( HTRANS == `IDLE && HBUSREQ ) ) )) 
                begin
                    protocolState = wait_bus_req;	//transition to state: wait_bus_req
                    END_TRANSACTION();
                end
                else 
                  begin
                     protocolError("protocol ahb_master sequence is wrong, in state seq_write_or_end\n\tthere is no transition that possible");
                     @(negedge CLK);
                end
            end
            
            
            end_write :
            begin
                begin
                    protocolState = wait_bus_req;	//transition to state: wait_bus_req
                    END_TRANSACTION(); 
                end
            end
            end_read :
            begin
                begin
                    protocolState = wait_bus_req;	//transition to state: wait_bus_req
                    END_TRANSACTION(); 
                end
            end
        endcase
end
endmodule
