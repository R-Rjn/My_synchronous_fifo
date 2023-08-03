// Define a randomizing class to generate random testbench input values
class randomizing;
  rand bit [7:0] data_in;// Random 8-bit data_in variable
  rand bit readEnable,writeEnable,empty,full; // Random control signals for read, write, empty, and full
endclass

// Testbench module
module tb;
  logic [7:0] data_in;// Input data to the FIFO
  logic clk,rst,readEnable,writeEnable; // Control signals for clock, reset, read, and write
  logic empty,full;// Output signals for empty and full status of the FIFO
  logic [3:0] fifo_cnt; // Output signal for the number of elements in the FIFO
  logic [7:0] data_out; // Output data from the FIFO
//   logic [7:0] fifo_ram [0:7];
//   logic [2:0] rd_ptr,wr_ptr;

// Declare and instantiate FIFO module with the testbench signals
  logic [7:0] que_data[$], que;
  
  fifo uut(data_in,clk,rst,readEnable,writeEnable,empty,full,fifo_cnt,data_out);
  randomizing ran; // Instantiate the randomizing class to generate random test inputs

 // Define a covergroup to capture code coverage information 
  covergroup cv_grp @(posedge clk);
     option.per_instance = 1; 
    DataInput: coverpoint data_in{bins b1 = {[0:32]};
                              bins b2 = {[33:64]};
                              bins b3 = {[65:128]};
                              bins b4 = {[129:$]};
                              bins b5 = {0,32,33,64,65,128,129};
                              }
    Write: coverpoint writeEnable{bins WriteDisable = {0};
                         bins WriteEnable = {1};}
    
    Read: coverpoint readEnable{bins ReadDisable= {0};
                         bins ReadEnable = {1};}
    
    Empty: coverpoint empty{bins no = {0};
                            bins yes = {1};}
    Full: coverpoint full{bins no = {0};
                            bins yes = {1};}
    RecievedData: coverpoint data_out{bins b1 = {[0:32]};
                              bins b2 = {[33:64]};
                              bins b3 = {[65:128]};
                              bins b4 = {[129:$]};
                              bins b5 = {0,32,33,64,65,128,129};}
  endgroup
  cv_grp cv_inst; // Instantiate the covergroup for coverage collection
  
  initial begin
    ran = new(); // Create an instance of the randomizing class
    clk=1'b0;
    rst=1'b0;
    ran.randomize(); // Randomize the testbench inputs using the randomizing class
    writeEnable = ran.writeEnable; // Assign random write control signal to the testbench
    data_in = ran.data_in; // Assign random data_in to the testbench input
    
    repeat(10) @(posedge clk); // Wait for a few clock cycles
    
    rst = 1'b1; // Activate reset signal

    // Simulate FIFO write operations for a few iterations
    repeat(2) begin
      for(int i=0;i<30;i++) begin
        @(posedge clk); // Wait for a positive edge of the clock
        ran.randomize(); // Randomize the testbench inputs
        writeEnable = ran.writeEnable; // Assign random write control signal to the testbench
        if (writeEnable & !full)  begin // Check if write is enabled and FIFO is not full
          data_in = ran.data_in; // Assign random data_in to the testbench input
          que_data.push_back(data_in); // Store data_in in the que_data array
        end
      end
      #50;  // Delay for 50 time units after each iteration
    end
end
  
  
  always #5 clk = ~clk; // Generate a clock signal with a 5 time unit period
  
  initial begin
    ran = new(); // Create an instance of the randomizing class
    clk=1'b0;
    rst=1'b0;
    ran.randomize(); // Randomize the testbench inputs using the randomizing class
    readEnable = ran.readEnable; // Assign random read control signal to the testbench
    
    repeat(20) @(posedge clk); // Wait for a few clock cycles
    
    rst = 1'b1; // Activate reset signal

    // Simulate FIFO read operations for a few iterations
    repeat(2) begin
      for(int i=0;i<30;i++) begin
        @(posedge clk); // Wait for a positive edge of the clock
        ran.randomize(); // Randomize the testbench inputs
        readEnable = ran.readEnable; // Assign random read control signal to the testbench
        if (readEnable & !empty)  begin  // Check if read is enabled and FIFO is not empty
          #1; // Wait for 1 time unit to simulate read latency
          que = que_data.pop_front(); // Retrieve data from que_data array as if reading from the FIFO
          $display("TIme = %0t: read data = %0d || write data = %0d ",$time,data_in,data_out); // Display read and write data at each iteration

        end
      end
      #50; // Delay for 50 time units after each iteration
    end
    $finish; // Finish the simulation after all iterations are complete
end
    
  initial begin
    cv_inst = new(); // Create an instance of the covergroup
    $dumpfile("dump.vcd"); // Create a VCD dump file
    $dumpvars; // Dump variables for VCD output
    $display("the data out = %0d",data_out); // Display the initial value of data_out
  end
    
endmodule
 
