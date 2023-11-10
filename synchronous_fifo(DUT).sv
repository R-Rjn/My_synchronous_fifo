// Here is the code for a synchronous FIFO, where we define the inputs and outputs for the design.
// The inputs and their meanings are as follows:
// - clk: The clock signal of the system.
// - rst: The reset signal used to initialize the FIFO.
// - readEnable: This signal is used to give permission to read from the read pointer.
// - writeEnable: This signal is used to give permission to write to the write pointer.
// The outputs and their meanings are as follows:
// - empty: This active signal indicates that there is no data present in the FIFO.
// - full: This active signal indicates that the FIFO's memory limit is full.
// Internal signals and storage in the FIFO:
// - [7:0] fifo_ram[0:7]: This is a 7x8 storage array used as memory for the FIFO.
// - [2:0] rd_ptr: This is a 3-bit read pointer used to access the FIFO memory.
// - [2:0] wr_ptr: This is a 3-bit write pointer used to access the FIFO memory.

interface synch_fifo(); //interface of synchronous fifo
  logic clk,rst,readEnable,writeEnable,empty,full;
  logic [7:0] data_in;
  logic [7:0] data_out;
  
  modport rtl(input clk,rst,readEnable,writeEnable,data_in, output data_out,full,empty);
  modport tb(output clk,rst,readEnable,writeEnable,data_in, input data_out,full,empty);
endinterface

module fifo (synch_fifo.rtl inf);
  
  reg [7:0] fifo_ram[0:7]; // Internal FIFO memory, 8 elements of 8-bit each
  reg [2:0] rd_ptr, wr_ptr; // Read and write pointers to access the FIFO memory
  reg [3:0]fifo_cnt;
  
  assign inf.empty = (fifo_cnt==0); // Output signal indicating if FIFO is empty
  assign inf.full = (fifo_cnt==8); // Output signal indicating if FIFO is full

// _____________________________________
  
// Synchronous reset and default value assignment on positive edge of the clock 
  always @(posedge inf.clk) begin: default_value
    if(!inf.rst) begin
         wr_ptr <= 3'b000; // Initialize write pointer to 0
         rd_ptr <= 3'b000; // Initialize read pointer to 0
         inf.data_out <= 0; // Initialize output data to 0
     end 
  end
  
  //__________________________________

// Write operation on positive edge of the clock when writeEnable is high and FIFO is not full  
  always @(posedge inf.clk) begin: write
    if(inf.writeEnable && !inf.full) begin
      fifo_ram[wr_ptr] <= inf.data_in; // Write data_in to the FIFO memory at wr_ptr
        wr_ptr <= wr_ptr + 1; // Increment the write pointer
    //else if(wr && rd)
      //    fifo_ram[wr_ptr] <= data_in;
  end
  end
  
// _____________________________________

// Read operation on positive edge of the clock when readEnable is high and FIFO is not empty
  always @(posedge inf.clk) begin: read
    if(inf.readEnable && !inf.empty) begin
    inf.data_out <= fifo_ram[rd_ptr]; // Read data from the FIFO memory at rd_ptr
        rd_ptr <= rd_ptr + 1; // Increment the read pointer
    //else if(wr && rd)
      //data_out <= fifo_ram[rd_ptr];
  end
  end
  
  //==================================
  
// Count and update the number of elements in the FIFO
  always @(posedge inf.clk) begin: count
    if(!inf.rst) fifo_cnt <=0; // Reset fifo_cnt to 0 during synchronous reset
     else begin
       case ({inf.writeEnable,inf.readEnable})
           2'b00, 2'b11: fifo_cnt <= fifo_cnt; // No change in count when both readEnable and writeEnable are low (idle state)
           2'b01: fifo_cnt <=  fifo_cnt-1; // Decrement the count when readEnable is high and writeEnable is low (read operation)
           2'b10: fifo_cnt <=  fifo_cnt+1; // Increment the count when writeEnable is high and readEnable is low (write operation)
           //2'b11: fifo_cnt <= fifo_cnt;
         endcase
     end
 end
endmodule
