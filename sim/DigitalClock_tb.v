`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2021 09:25:49 AM
// Design Name: 
// Module Name: DigitalClock_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DigitalCLock_tb;

    reg clk; // FPGA clock signal, 100 MHz
    reg btnC, btnU, btnL, btnR, btnD; // FPGA IO pushbuttons
    reg [0:0] sw;//switch to turn on alarm mode
    wire [6:0] seg;
    wire [3:0] an; // FPGA 7-Segment Display
    wire [0:0] led; //LED 0 is AM/PM LED
    


    // Instantiate the Unit Under Test (UUT)
    DigitalClock UUT0 (
        .clk(clk)
    );
    
    //Generating the Clock with `1 Hz frequency
    initial clk = 0;
    always #100000000 clk = ~clk;  //Every 1 sec toggle the clock.

      
endmodule
