
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

// defines for HWRITE
`define READ  1'b0
`define WRITE 1'b1

// defines for HTRANS [1:0]
`define IDLE   2'b00
`define BUSY   2'b01
`define NONSEQ 2'b10
`define SEQ    2'b11
 
// defines for HBURST [2:0]
`define SINGLE 3'b000
`define INCR   3'b001
`define WRAP4  3'b010
`define INCR4  3'b011
`define WRAP8  3'b100
`define INCR8  3'b101
`define WRAP16 3'b110
`define INCR16 3'b111

// defines for HSIZE [2:0]
`define SIZE_8    3'b000 // Byte
`define SIZE_16   3'b001 // Halfword
`define SIZE_32   3'b010 // Word
`define SIZE_64   3'b011
`define SIZE_128  3'b100 // 4-word line
`define SIZE_256  3'b101 // 8-word line
`define SIZE_512  3'b110
`define SIZE_1024 3'b111

// defines for HRESP [1:0]
`define OKAY  2'b00
`define ERROR 2'b01
`define RETRY 2'b10
`define SPLIT 2'b11

