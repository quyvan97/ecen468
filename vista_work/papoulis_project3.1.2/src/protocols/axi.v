
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
`include "axi_define.v"
//*********************************************************************************//
//*****************************   axi Module   *******************************//
//*********************************************************************************//
                                       
                               /***  Modified Version: 11 ***/        // Debugged 
                               
// Protocol defined in 5 state machines, a state machine corresponding to each channel
// to support AXI key features:
// Seperate address/control and data phases.
// Seperate read and write data channels.
// Overlapped transactions, issuing multiple outstanding addresses, and out-of-order transactions.
// Support for Locked access

// Data in this file are extracted from AMBA AXI Protocol V1.0 Specification
// (/*** Bus width and transaction ID width are implementation-specific. Here it is specified as the maximum supported ***/)

                                       
// Protocol First Section
// Declaration of parameters Corresponding to HDL signals (Master, Slave, Global Signals)

(* bus_slave *)
(* bus_master *)
module axi #(parameter WORD_SIZE = 32)
  (
   // Global Signals
   ACLK,
   //ARESETn,

   // Write Address Channel
   AWID,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
   AWVALID,
   AWREADY,

   // Write Channel
   WID,
   WLAST,
   WDATA,
   WSTRB,
   WVALID,
   WREADY,

   // Write Response Channel
   BID,
   BRESP,
   BVALID,
   BREADY,

   // Read Address Channel
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
   ARVALID,
   ARREADY,

   // Read Channel
   RID,
   RLAST,
   RDATA,
   RRESP,
   RVALID,
   RREADY,

   // Low power interface
   CACTIVE,
   CSYSREQ,
   CSYSACK
   );

  
   //***********************   Global AXI Signals    ********************************//
   (* clock *) input ACLK;      // Global clock signal. Signals are to be sampled on the rising edge of the global clock.
   //input ARESETn;               // Global reset signal. It's active LOW. (/*** Not Sure about Papoulis Pragma ***/) 
   
   
   //***********************   Write address channel signals   ********************************//
                
   (* master *) (* id *) input [3:0] AWID;     // Write address ID; the identification tag for the write address group of signals.
   (* master *) (* address *) input [31:0] AWADDR;  // Write address. It gives the address of first transfer in a write burst transaction.
                                      // The associated control signal are used to determine the addresses of the remaining transfers in the burst.
                                                                                
   (* master *) input [3:0] AWLEN;   // Burst length. It gives the exact number of data transfers in a burst associated with the address.
   (* master *) input [2:0] AWSIZE;   // Burst size. It indicates the size of each transfer in the burst. Byte lane strobes indicate exactly which byte lanes to update.
   (* master *) input [1:0] AWBURST;  // Burst type. Coupled with size information details how the address of each transfer within the burst is calculated.
   
   (* master *) input [1:0] AWLOCK;   // Lock type. It provides additional information about the atomic characteristics of the transfer.
   (* master *) input [3:0] AWCACHE;  // Cache type. It indicates the bufferable, cacheable, write-through, write-back, and allocate attributes of the transaction.
   (* master *) input [2:0] AWPROT;   // Protection type. It indicates the normal, privileged, or secure protection level of the transaction,
                                      // and whether the transaction is data access or information access.
                                      
   (* master *) input AWVALID;        // Write address valid. When high, it indicates the availability of valid write address and control information.
                                      // The address and control information remain stable until the address acknowledge signal AWREADY, goes HIGH.                                     
   (* slave *) input AWREADY;         // Write address ready. When high, it indicates that the slave is ready to accept an address and associated control information.


   //***********************   Write data channel signals   ********************************//
   
   (* master *) input [3:0] WID;     // Write ID tag; the identification tag of the write data transfer. 
                                     // The WID value must match the AWID value of the write transaction.
   (* master *) input [WORD_SIZE - 1:0] WDATA;  // Write data. The write data bus can be 8, 16, 32, 64, 128, 256, 512, or 1024 bits wide.
   
   (* master *) input [WORD_SIZE/8 - 1:0] WSTRB;   // Write strobes. It indicates which byte lane to update in the memory.
                                     // There is one write strobe for each 8 bits of the write data bus.
                                     // WSTRB[n] corresponds to WDATA[(8*n)+7 : (8*n)].
   (* master *) input WLAST;         // Write last. It indicates the last transfer in a write burst.                                                                             
   
   (* master *) input WVALID;        // Write valid. When high, it indicates the availability of valid write data and strobes.                                                                       
   (* slave *) input WREADY;         // Write ready. When high, it indicates that the slave is ready to accept write data.
   
   
   //***********************   Write response channel signals   ********************************//
   
   (* slave *) input [3:0] BID;      // Response ID; the identification tag of the write response. 
                                     // The BID value must match the AWID value of the write transaction.
   (* slave *) input [1:0] BRESP;    // Write response. It indicates the status of the write transaction.
                                     // The allowable responses are OKAY, EXOKAY, SLVERR, and DEDERR. 
     
   (* slave *) input BVALID;         // Write response valid. When high, it indicates the availability of valid write response.                                                                       
   (* master *) input BREADY;        // Response ready. When high, it indicates that the master is ready to accept response information.
   
   
   //***********************   Read address channel signals   ********************************//
                
   (* master *) input [3:0] ARID;     // Read address ID; the identification tag for the read address group of signals.
   (* master *) (* address *) input [31:0] ARADDR;  // Read address. It gives the address of first transfer in a read burst transaction.
                                      // The associated control signal are used to determine the addresses of the remaining transfers in the burst.
                                                                                
   (* master *) input [3:0] ARLEN;    // Burst length. It gives the exact number of data transfers in a burst associated with the address.
   (* master *) input [2:0] ARSIZE;   // Burst size. It indicates the size of each transfer in the burst. 
   (* master *) input [1:0] ARBURST;  // Burst type. Coupled with size information details how the address of each transfer within the burst is calculated.
   
   (* master *) input [1:0] ARLOCK;   // Lock type. It provides additional information about the atomic characteristics of the transfer.
   (* master *) input [3:0] ARCACHE;  // Cache type. It provides additional information about the cacheable characteristics of the transfer.
   (* master *) input [2:0] ARPROT;   // Protection type. It provides protection unit information for the transaction.
                                      
   (* master *) input ARVALID;        // Read address valid. When high, it indicates the availability of valid read address and control information.
                                      // The address and control information remain stable until the address acknowledge signal ARREADY, goes HIGH.                                     
   (* slave *) input ARREADY;         // Read address ready. When high, it indicates that the slave is ready to accept an address and associated control information.


   //***********************   Read data channel signals   ********************************//
   
   (* slave *) input [3:0] RID;       // Read ID tag; the identification tag of the read data group of signals. 
                                      // The RID value must match the ARID value of the read transaction.
   (* slave *) input [WORD_SIZE - 1:0] RDATA;    // Read data. The read data bus can be 8, 16, 32, 64, 128, 256, 512, or 1024 bits wide.
   
   (* slave *) input [1:0] RRESP;     // Read response. It indicates the status of the read transfer. 
                                      // The allowable responses are OKAY, EXOKAY, SLVERR, and DEDERR. 
                                     
   (* slave *) input RLAST;           // Read last. It indicates the last transfer in a read burst.                                                                             
   
   (* slave *) input RVALID;          // Read valid. When high, it indicates the availability of the required read data.                                                                       
   (* master *) input RREADY;         // Read ready. When high, it indicates that the master is ready to accept read data and response information.
  
  
   //***********************   Low-power interface signals   ********************************//
     
   (* slave *) input CSYSREQ;                     // System low-power request. Sourse: Clock controller
                                      // It is a request from the system controller for peripheral to enter a low-power state.
   (* master *) input CSYSACK;                     // Low-power request acknowledgement. Source: Peripheral device.  
   (* master *) input CACTIVE;                     // Clock active. Source: Peripheral device. When high, it indicates that the peripheral requires its clock signal.
 
  // Low power interface signals are defined as weak pull-up in the case
  // that they are unconnected.
  tri1                CACTIVE;
  tri1                CSYSREQ;
  tri1                CSYSACK; 
 
// Protocol Second Section
// Declaration of protocol messages and transactions

/*********************************Protocol Messages**********************************/    

// ************************ Write transaction exchanged messages ***************************************************/
(* master *)
function void writeBurst_Control((* id *) input [3:0] TR_ID, input [31:0] AWADDR, input [3:0] AWLEN,
                                 input [2:0] AWSIZE, input int block_size, input [1:0] AWBURST, input [1:0] AWLOCK, input [3:0] AWCACHE,
                                 input [2:0] AWPROT);
   $display($time," Master : Write Burst Control initiated ");
   $display("\t\t Write Address ID: %d ", TR_ID);                                 
   $display("\t\t Write Start Address: %h ", AWADDR);                                    
endfunction

(* slave *)
function void writeBurst_Ready ();
   $display($time," Slave : Write Burst Control accepted ");
endfunction

(* master *)
function void writeBurst_Data ((*  id *) input [3:0] TR_ID, input [WORD_SIZE - 1:0] WDATA, input [WORD_SIZE / 8 - 1 : 0] WSTRB);
    $display($time," Master : Write Burst Data initiated ");
    $display("\t\t Write Data ID: %d ", TR_ID); 
endfunction
     
(* slave *)
function void writeBurst_acceptData ();
    $display($time," Slave : Write Burst Data accepted ");
endfunction

(* master *)
function void writeBurst_LastData ((*  id *) input [3:0] TR_ID, input [WORD_SIZE - 1:0] WDATA, input [WORD_SIZE / 8 -1:0] WSTRB);
    $display($time," Master : Write Burst Last Data initiated ");
    $display("\t\t Write Data ID: %d ", TR_ID);
endfunction

(* slave *)
function void writeBurst_acceptLastData ();
    $display($time," Slave : Write Burst Last Data accepted ");
endfunction

(* slave *)
function void writeBurst_Response((*  id *) input [3:0] TR_ID, input [1:0] BRESP);
     $display($time," Slave : Write Burst Response ");
     $display("\t\t Burst Response ID: %d ", TR_ID);
endfunction


(* master *)
function void writeBurst_acceptResponse();
    $display($time," Master : Write Burst Response accepted ");
endfunction

(* master *)
function void writeBurst_Done ();
    $display($time," Master : Write Burst Completed ");
endfunction

// ************************ Read transaction exchanged messages ***************************************************/
(* master *)
function void readBurst_Control((*  id *) input [3:0] TR_ID, input [31:0] ARADDR, input [3:0] ARLEN,
                                input [2:0] ARSIZE, input int block_size, 
                                input [1:0] ARBURST, input [1:0] ARLOCK, input [3:0] ARCACHE,
                                input [2:0] ARPROT);
   $display($time," Master : Read Burst Control initiated ");
   $display("\t\t Read Address ID: %d ", TR_ID);                                 
   $display("\t\t Read Start Address: %h ", ARADDR);
endfunction

(* slave *)
function void readBurst_Ready ();
    $display($time," Slave : Read Burst Control accepted ");
endfunction

(* slave *)
function void readBurst_Data ((*  id *) input [3:0] TR_ID, input [WORD_SIZE - 1:0] RDATA, input [WORD_SIZE / 8 - 1:0] RRESP);
    $display($time," Slave : Read Burst Data initiated ");
    $display("\t\t Read Data ID: %d ", TR_ID);                                 
endfunction
     
(* master *)
function void readBurst_acceptData ();
    $display($time," Master : Read Burst Data accepted ");
endfunction

(* slave *)
function void readBurst_LastData ((*  id *) input [3:0] TR_ID, input [WORD_SIZE - 1:0] RDATA, input [WORD_SIZE / 8 - 1:0] RRESP);
    $display($time," Slave : Read Burst Last Data initiated ");
    $display("\t\t Read Data ID: %d ", TR_ID);
endfunction

(* master *)
function void readBurst_acceptLastData ();
    $display($time," Master : Read Burst Last Data accepted ");
endfunction

(* master *)
function void readBurst_Done ();
    $display($time," Master : Read Burst Completed ");
endfunction



/*********************************Protocol Transactions**********************************/    
    
(* transaction *)    
function void WRITE((* id *) int TR_ID, (* address *) int AWADDR, output int WDATA[], (* default_value = 2 *) int AWSIZE, (* default_value = 4 *) (* block_size *) int block_size, (* default_value = 1 *) int AWBURST /* INCR burst */, (* default_value = 1 *) int AWLEN, (* default_value = 0 *) int AWLOCK);
endfunction    

(* transaction *)    
function void  READ ((* id *) int TR_ID, (* address *) int ARADDR, input int RDATA[], (* default_value = 2 *) int ARSIZE, (* default_value = 4 *) (* block_size *) int block_size, (* default_value = 1 *) int ARBURST /* INCR burst */, (* default_value = 1 *) int ARLEN, (* default_value = 0 *) int ARLOCK);
endfunction

// Auxiliary signals

int ROutstanding = 0;
int WOutstanding = 0;
int WResponseOutstanding = 0;
logic [3:0] LockedID;
reg [3:0] WIDs[1:15] ;
reg AddrNeed[1:15] ; 


int flag, i ,j;

int RLockedAccessViolation_flag = 0;
int WLockedAccessViolation_flag = 0;

// LOCK FSM
typedef enum{
      UnLocked,
      Locked,
      LockLast
} LOCK_STATES;
LOCK_STATES LockState;
initial LockState = UnLocked;

// Protocol Third Section
// Declaration of protocol states

typedef enum{
      // Write Address Channel States	    
      wait_writeAddress_req,
      wait_writeAddress_ack,

      // Write Data Channel States
      wait_writeData_req,
      wait_writeData_ack,
      wait_writeLastData_ack,
      wait_loop_writeData_req,
      // Write Response Channel States	
      wait_writeResponse_req,
      wait_writeResponse_ack,
      end_write,
      
      //Read Address Channel States	
      wait_readAddress_req,
      wait_readAddress_ack,

      //Read Data Channel States
      wait_readData_req,
      wait_readData_ack,
      wait_loop_readData_req,
      wait_readLastData_ack,
        
      end_read   
    
} PROTOCOL_STATES;

PROTOCOL_STATES AWprotocolState, WprotocolState, BprotocolState, ARprotocolState, RprotocolState;
//AWprotocolState will get values: wait_writeAddress_req, wait_writeAddress_ack
//WprotocolState will get values: wait_writeData_req, wait_writeData_ack
//BprotocolState will get values: wait_writeResponse_req, wait_writeResponse_ack, end_write
//ARprotocolState will get values: wait_readAddress_req, wait_readAddress_ack
//RprotocolState will get values: wait_readData_req, wait_readData_ack, end_read  


// Write Address Channel State machine
(* SM_successor  = wait_writeData_req *)
(* tlm_phase_start = "begin_req" *)
(* tlm_phase_end = "end_req" *)
(* protocol_initial *)
initial
   AWprotocolState = wait_writeAddress_req;
(* protocol_SM *)   
always
begin
    case(AWprotocolState)
        wait_writeAddress_req:
        begin
         if(AWVALID === 1  && WLockedAccessViolation_flag == 0)
            begin
               AWprotocolState = wait_writeAddress_ack;
                (* WRITE *)
               writeBurst_Control(AWID, AWADDR, AWLEN, AWSIZE, 1 << AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT);   
            end
         else
            begin
            AWprotocolState = wait_writeAddress_req;    
            @(negedge ACLK);
            end
        end
        
        wait_writeAddress_ack:
        begin
            if (AWREADY === 1)
            begin
               AWprotocolState = wait_writeAddress_req;
               writeBurst_Ready ();
               @(negedge ACLK);
            end
            else
            begin
               AWprotocolState = wait_writeAddress_ack;
               @(negedge ACLK); 
            end 
        end
    endcase            
end


// Write Data Channel State machine
(* SM_successor = wait_writeResponse_req *)
(* protocol_initial *)
(* tlm_phase_start = "begin_resp" *)
(* tlm_phase_end = "end_resp" *) 

initial
    WprotocolState = wait_writeData_req;
(* protocol_SM *)
always
begin
    case(WprotocolState)
        wait_writeData_req:
        begin
           if(WVALID === 1)
           begin
              
              if (WLAST === 1)
              begin
                  WprotocolState = wait_writeLastData_ack;
                  writeBurst_LastData(WID, WDATA, WSTRB);
              end
               else 
                begin
                  WprotocolState = wait_writeData_ack;
                  writeBurst_Data(WID, WDATA, WSTRB);   
                end
           end
           else
           begin
              WprotocolState = wait_writeData_req;    
              @(negedge ACLK);
           end
        end     
         
        wait_loop_writeData_req:
        begin
           if(WVALID === 1)
           begin
              
              if (WLAST === 1)
              begin
                  WprotocolState = wait_writeLastData_ack;
                  writeBurst_LastData(WID, WDATA, WSTRB);
              end
               else 
                begin
                  WprotocolState = wait_writeData_ack;
                  writeBurst_Data(WID, WDATA, WSTRB);   
                end
           end
           else
           begin
              WprotocolState = wait_loop_writeData_req;    
              @(negedge ACLK);
           end
        end 
  
        wait_writeLastData_ack:
        begin
            if (WREADY === 1)
            begin
                  WprotocolState = wait_writeData_req;
                  writeBurst_acceptLastData ();
                  WResponseOutstanding ++;      //BVALID must wait for WVALID and WREADY to be asserted  ---> Aiming at CA-TLM

                  @(negedge ACLK);               
            end 
            else
            begin
               WprotocolState = wait_writeLastData_ack;
               @(negedge ACLK); 
            end 
        end              
      
        wait_writeData_ack:
        begin
            if (WREADY === 1)
            begin
               if (WLAST !== 1)
                  begin
                        WprotocolState = wait_loop_writeData_req;
                        writeBurst_acceptData ();
                        @(negedge ACLK);
                  end
               
            end 
            else
            begin
               WprotocolState = wait_writeData_ack;
               @(negedge ACLK); 
            end 
        end       
    endcase            
end


// Write Response Channel State machine

(* protocol_initial *)
initial
    BprotocolState = wait_writeResponse_req;
(* protocol_SM *)
always
begin
    case(BprotocolState)
        wait_writeResponse_req:
        begin
           if(WResponseOutstanding !== 0 && BVALID === 1)
           begin
              BprotocolState = wait_writeResponse_ack;
              writeBurst_Response(BID, BRESP);
           end
           else
           begin
              BprotocolState = wait_writeResponse_req;    
              @(negedge ACLK);
           end
        end                            
            
            
                 
        wait_writeResponse_ack:
        begin
            if (BREADY === 1)
            begin
               BprotocolState = end_write;  
               writeBurst_acceptResponse(); 
            end
            else
            begin
               BprotocolState = wait_writeResponse_ack;
               @(negedge ACLK); 
            end            
        end
        
        end_write:
        begin
               BprotocolState = wait_writeResponse_req;  
               writeBurst_Done ();            //Write transaction is considered complete when write response is received by master
               WResponseOutstanding --;
               WOutstanding --;
               @(negedge ACLK);           
        end
        
    endcase            
end



// Read Address Channel State machine
(* SM_successor = wait_readData_req *)
(* tlm_phase_start = "begin_req" *)
(* tlm_phase_end = "end_req" *)
(* protocol_initial *)
initial
   ARprotocolState = wait_readAddress_req;
(* protocol_SM *)   
always
begin
    case(ARprotocolState)
        wait_readAddress_req:
        begin
         if(ARVALID === 1 && RLockedAccessViolation_flag == 0)
            begin
            ARprotocolState = wait_readAddress_ack;
            (* READ *)
	    readBurst_Control(ARID, ARADDR, ARLEN, ARSIZE, 1 << ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT); 
            end
         else
            begin
            ARprotocolState = wait_readAddress_req;    
            @(negedge ACLK);
            end
        end                  
                
        wait_readAddress_ack:
        begin
            if (ARREADY === 1)
            begin
               ARprotocolState = wait_readAddress_req;
               readBurst_Ready ();
               ROutstanding ++;      // RVALID must wait for ARVALID and ARREADY to be asserted  ---> Aiming at CA-TLM
               @(negedge ACLK);
            end
            else
            begin
               ARprotocolState = wait_readAddress_ack;
               @(negedge ACLK); 
            end 
        end
    endcase            
end

// Read Data Channel State machine
(* protocol_initial *)
(* tlm_phase_start = "begin_resp" *)
(* tlm_phase_end = "end_resp" *)
initial
    RprotocolState = wait_readData_req;
(* protocol_SM *)
always
begin
    case(RprotocolState)
        wait_readData_req:
        begin
           if(ROutstanding !== 0 && RVALID === 1)
           begin
              
              
              if (RLAST === 1)
              begin
                  RprotocolState = wait_readLastData_ack;
                  readBurst_LastData(RID, RDATA, RRESP);
              end
               else 
                begin
                  RprotocolState = wait_readData_ack;
                  readBurst_Data(RID, RDATA, RRESP);  
                end
           end
           else
           begin
              RprotocolState = wait_readData_req;    
              @(negedge ACLK);
           end
        end     
          
        wait_readLastData_ack:
        begin
            if (RREADY === 1)
            begin
                  RprotocolState = end_read;
                  readBurst_acceptLastData ();
               
            end 
            else
            begin
               RprotocolState = wait_readLastData_ack;
               @(negedge ACLK); 
            end 
        end
       
        wait_loop_readData_req:
        begin
           if(ROutstanding !== 0 && RVALID === 1)
           begin
              
              
              if (RLAST === 1)
              begin
                  RprotocolState = wait_readLastData_ack;
                  readBurst_LastData(RID, RDATA, RRESP);
              end
               else 
                begin
                  RprotocolState = wait_readData_ack;
                  readBurst_Data(RID, RDATA, RRESP);  
                end
           end
           else
           begin
              RprotocolState = wait_loop_readData_req;    
              @(negedge ACLK);
           end
        end

        wait_readData_ack:
        begin
            if (RREADY === 1)
            begin
               if (RLAST !== 1)
                  
                  begin 
                        RprotocolState = wait_loop_readData_req;
                        readBurst_acceptData ();
                        @(negedge ACLK); 
                  end
            end 
            else
            begin
               RprotocolState = wait_readData_ack;
               @(negedge ACLK); 
            end 
        end
        
        end_read:   
        begin
            RprotocolState = wait_readData_req;
            readBurst_Done ();      //Read transaction is considered complete when last read data is returned to master
            ROutstanding --;
            @(negedge ACLK);            
        end
        
    endcase            
end


//Auxillary Code mainly for Lock Access support


always @(negedge ACLK)
begin
	if (AWVALID ==1 && WLockedAccessViolation_flag == 0 && AWREADY == 1)
	begin	
	  if(WOutstanding == 0)
	  begin 
	       WOutstanding++;
	       WIDs[WOutstanding] = AWID;		
	  end
	  else
	  begin	
          	flag = 0;
	  	for(i = 1 ; i <= WOutstanding ; i++)
	  	begin
			if(WIDs[i] == AWID)
			begin
				flag = 1;
				AddrNeed[i] = 0;
			end
	  	end
		if (flag == 0)
		begin 
	       		WOutstanding++;
	       		WIDs[WOutstanding] = AWID;		
	  	end
          end				  
	end
end

always @(negedge ACLK)
begin
	if (WVALID ==1 && WREADY == 1)
	begin	
	  if(WOutstanding == 0)
	  begin 
	       	WOutstanding++;
	       	WIDs[WOutstanding] = WID;
	       	AddrNeed[WOutstanding] = 1;		
	  end
	  else
	  begin	
          	flag = 0;
	  	for(i = 1 ; i <= WOutstanding ; i++)
	  	begin
			if(WIDs[i] == WID)
			begin
			flag = 1;
			end
	  	end
		if (flag == 0)
		begin 
	       		WOutstanding++;
	       		WIDs[WOutstanding] = WID;
			AddrNeed[WOutstanding] = 1;		
	  	end
          end				  
	end
end

always @(negedge ACLK)
begin
	if (BVALID == 1 && BREADY == 1)
	begin	
	  	for(i = 1 ; i <= WOutstanding ; i++)
	  	begin
			if(WIDs[i] == BID)
				for(j = i ; j < WOutstanding ; j++)
				begin
					WIDs[j] = WIDs[j+1];
					AddrNeed[j] =AddrNeed[j+1];
				end
	  	end 	       							  
	end
end


always @(AWVALID)
begin
	if(AWVALID === 0) 
	     WLockedAccessViolation_flag = 0;
	else
	if (AWVALID == 1)
	begin
	case (LockState)
                    UnLocked:
                     // Check if master is trying to start a locked sequence
                     if(AWLOCK == `AXI_ALOCK_LOCKED)
                        // Check if no other outstanding transactions are waiting to complete and no new address are valid unless locked.
                        if(ROutstanding == 0 && WOutstanding == 0 && ~(!$isunknown(ARVALID) && ARVALID && (ARLOCK != `AXI_ALOCK_LOCKED)) )
                        begin
                           LockState = Locked;
			   LockedID = AWID;
                           (* LockAccess *)
                           WLockedAccessViolation_flag = 0;                    
                        end   
                        else
                        begin
                            $display("Error: A master must wait for all outstanding transactions to complete before issuing a write address which is the first in a locked sequence.");
                            WLockedAccessViolation_flag = 1;
                        end
                      
                     Locked:
		     if (AWID == LockedID)
                     begin	
                      // Check if master is trying to complete a locked sequence
                      if(AWLOCK != `AXI_ALOCK_LOCKED)
                        // Check if no other outstanding transactions are waiting to complete and no new address are valid.
                        if(ROutstanding == 0 && WOutstanding == 0 && ARVALID !== 1)
                        begin
                           LockState = LockLast;
                           (* UnLockAccess *)
                           WLockedAccessViolation_flag =0;
                        end   
                        else
                        begin
                            $display("Error: A master must wait for all locked transactions to complete before issuing an unlocked write address.");
                            WLockedAccessViolation_flag = 1;
                        end
		      end
		      else
                      begin
                            $display("Error: A master must ensure that all transactions within a locked sequence have the same ARID or AWID");
			    WLockedAccessViolation_flag = 1;
                      end

                     
                     LockLast:
                        // Check if unlocking transactions has fully completed and no new address are valid, unless of same LOCK type.
                        if(ROutstanding == 0 && WOutstanding == 0 && ~(!$isunknown(ARVALID) && ARVALID & (ARLOCK != AWLOCK)) )
                        begin
                           if (AWLOCK == `AXI_ALOCK_LOCKED)
		           begin		
                              LockState = Locked;
                              LockedID = AWID;
                           end
                           else
                           begin
                              LockState = UnLocked;
                              WLockedAccessViolation_flag = 0;                           
			   end
                        end   
                        else
                        begin
                            $display("Error: A master must wait for an unlocked transaction at the end of a locked sequence to complete before issuing another write address.");
			    WLockedAccessViolation_flag = 1;
                        end
                endcase
            end
end


always @(ARVALID)
begin
	if(ARVALID === 0) 
	     RLockedAccessViolation_flag = 0;
	else
	if(ARVALID === 1)
        begin
            case (LockState)
                    UnLocked:
                     // Check if master is trying to start a locked sequence
                     if(ARLOCK == `AXI_ALOCK_LOCKED)
                        // Check if no other outstanding transactions are waiting to complete and no new address are valid unless locked.
                        if(ROutstanding == 0 && WOutstanding == 0 && ~(!$isunknown(AWVALID) && AWVALID && (AWLOCK != `AXI_ALOCK_LOCKED)) )
                        begin
                           LockState = Locked;
			   LockedID = ARID;	
                           (* LockAccess *) 
			    RLockedAccessViolation_flag = 0;
                        end   
                        else
                        begin
                            $display("Error: A master must wait for all outstanding transactions to complete before issuing a read address which is the first in a locked sequence.");
			    RLockedAccessViolation_flag = 1;
                        end
        
                                           
                     Locked:
		     if (ARID == LockedID) 
		     begin	
                     	// Check if master is trying to complete a locked sequence
                     	if(ARLOCK != `AXI_ALOCK_LOCKED)
                        // Check if no other outstanding transactions are waiting to complete and no new address are valid.
                     	   if(ROutstanding == 0 && WOutstanding == 0 && AWVALID !== 1)
                     	   begin
                     	      LockState = LockLast;
                     	      (* UnLockAccess *)
			      RLockedAccessViolation_flag = 0;
                     	   end   
                     	   else
                     	   begin
                     	       $display("Error: A master must wait for all locked transactions to complete before issuing an unlocked read address.");
			       RLockedAccessViolation_flag = 1;
                           end
		      end
		      else
                      begin
                            $display("Error: A master must ensure that all transactions within a locked sequence have the same ARID or AWID");
			    RLockedAccessViolation_flag = 1;
                      end		    		
			
                     
                     LockLast:
                        // Check if unlocking transactions has fully completed and no new address are valid, unless of same LOCK type.
                        if(ROutstanding == 0 && WOutstanding == 0 && ~(!$isunknown(AWVALID) && AWVALID & (AWLOCK != ARLOCK)) )
                        begin
                           if (ARLOCK == `AXI_ALOCK_LOCKED)
			   begin	
                              LockState = Locked;
			      LockedID = ARID;
			   end	
                           else
			   begin
                              LockState = UnLocked;
    			      RLockedAccessViolation_flag = 0;                           
			   end	
                        end   
                        else
                        begin
                            $display("Error: A master must wait for an unlocked transaction at the end of a locked sequence to complete before issuing another read address.");
			    RLockedAccessViolation_flag = 1;
                        end
                endcase
            end 
end

         
endmodule  
     
   
