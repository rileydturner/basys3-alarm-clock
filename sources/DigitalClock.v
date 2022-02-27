`timescale 1ns / 1ps

module DigitalClock(
    input clk, // FPGA clock signal, 100 MHz
    input btnC, btnU, btnL, btnR, btnD, // FPGA IO pushbuttons
    input [2:0] sw,//switch to turn on alarm mode
    output reg [6:0] seg,
    output reg [3:0] an, // FPGA 7-Segment Display
    output reg [0:0] led //LED 0 is AM/PM LED
    );
    
    /* Timing parameters */
    reg [31:0] counter = 0;
    reg [31:0] d_counter =0;
    parameter max_counter = 100000000; // 100 MHz / 100000000 = 1 Hz => 1 second per second
    parameter display_counter = 500000; //500000 / 100MHZ = 5ms
    
    /* Data registers */
    reg [5:0] Hours, Minutes, Seconds = 0; 
    reg [3:0] D0,D1, D2, D3 = 0; 
    reg current_bit = 0;      // Currently only minutes and hours
    
    //reg AM_PM = 0;  // AM = 0/off , PM = 1/on
    
    reg [1:0] current_LED = 0;
    reg [7:0] LED_out [3:0];
    
    //alarm
    reg [5:0] Seconds_alarm = 0;
    reg [5:0] Minutes_alarm = 12;
    
    //alarm mode restart
    reg [5:0] Seconds_alarm_reset = 0;
    reg [5:0] Minutes_alarm_reset = 12;
    
    /* Modes */
    parameter Hours_And_Minutes = 1'b0; // Clock mode - 12:00AM to 11:59PM
    parameter Set_Clock = 1'b1;         // Set time mode
    reg Current_Mode = Set_Clock; //Start in set time mode by default
   
    
    wire [3:0] four_bit_data [3:0]; 
    assign  four_bit_data[0] = D0;
    assign  four_bit_data[1] = D1;
    assign  four_bit_data[2] = D2;
    assign  four_bit_data[3] = D3;
    
                      	 
    always @(posedge clk) begin
        if (counter < max_counter) begin
            counter <= counter+1;
        end 
        else begin
            //current_LED <= current_LED + 1;
            counter <= 0;
        end
        if(d_counter < display_counter) begin
            d_counter <= d_counter + 1; 
        end 
        else begin
            current_LED <= current_LED + 1;
            d_counter <= 0;
        end
                
		case(four_bit_data[current_LED]) //S15, S14, S13, S12 are the binary data bits, MSB->LSB
			 4'b0000 : LED_out[current_LED] <= 7'b1000000; //0
			 4'b0001 : LED_out[current_LED] <= 7'b1111001; //1
			 4'b0010 : LED_out[current_LED] <= 7'b0100100; //2
			 4'b0011 : LED_out[current_LED] <= 7'b0110000; //3
			 4'b0100 : LED_out[current_LED] <= 7'b0011001; //4
			 4'b0101 : LED_out[current_LED] <= 7'b0010010; //5
			 4'b0110 : LED_out[current_LED] <= 7'b0000010; //6
			 4'b0111 : LED_out[current_LED] <= 7'b1111000; //7
			 4'b1000 : LED_out[current_LED] <= 7'b0000000; //8
			 4'b1001 : LED_out[current_LED] <= 7'b0011000; //9
			 default : LED_out[current_LED] <= 7'b1000000; //otherwise 0
		 endcase
        
        case(current_LED)
            0: begin
                an <= 4'b1110; 
                seg <= LED_out[0];
            end
                
            1: begin
                an <= 4'b1101;
                seg <= LED_out[1];            
            end
            
            2: begin
                an <= 4'b1011;
                seg <= LED_out[2];
            end
            
            3: begin
                an <= 4'b0111;
                seg <= LED_out[3];
            end                
        endcase 
        case(Current_Mode)
            Hours_And_Minutes: begin // Clock mode - 12:00AM to 11:59PM
                if (btnC) begin
                    Current_Mode <= Set_Clock; // Swap modes when you push the center button 
                    // Reset variables to prepare for set time mode 
                    counter <= 0;
                    current_bit <= 0;
                    Seconds <= 59; //59
                end
                
                if (counter < max_counter) begin // time
                    counter <= counter + 1;
                end 
                else begin
                    counter <= 0;
                    Seconds <= Seconds + 1;
                end                                
            end //Hours_And_Minutes (minutes_and_seconds)
            Set_Clock: begin
                /*Seconds_alarm <= Seconds;
                Minutes_alarm <= Minutes;*/
                if (btnC) begin // Push center button to commit time set and return to Clock mode
                    Current_Mode <= Hours_And_Minutes;
                    Seconds_alarm_reset <= Seconds; //must restart at this time
                    Minutes_alarm_reset <= Minutes; //must resart at this time
                end
                
                if (counter < (25000000)) begin // different clock speed when setting - 4 Hz
                    counter <= counter + 1;
                end 

                else begin
                    counter <= 0;
                    case (current_bit)
                        1'b0: begin //minutes (seconds)
                            if (btnU) begin // Increment minutes when you push up
                                Seconds <= Seconds + 1;
                            end
                            if (btnD) begin // Decrement minutes when you push down
                                if (Seconds > 0) begin
                                    Seconds <= Seconds - 1;
                                end 
                                else if (Minutes > 1) begin
                                    Minutes <= Minutes - 1;
                                    Seconds <= 59;
                                end 
                                else if (Minutes == 1) begin
                                    Minutes <= 12;
                                    Seconds <= 59;
                                end
                            end
                            if (btnL || btnR) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 1;
                            end
                        /*Seconds_alarm <= Seconds;
                        Minutes_alarm <= Minutes;*/
                        end // end 1'b0
                        1'b1: begin //hours (Minutes)
                            if (btnU) begin // Increment hours when you push up
                                Minutes <= Minutes + 1;
                            end
                            if (btnD) begin // Decrement minutes when you push down
                                if (Minutes > 1) begin
                                    Minutes <= Minutes - 1;
                                end else if (Minutes == 1) begin
                                    Minutes <= 12;
                                end
                            end
                            if (btnL || btnR) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 0;
                            end
                        /*Seconds_alarm <= Seconds;
                        Minutes_alarm <= Minutes;*/
                        end // end 1'b1                         
                endcase   // end case (current_bit)
                if(sw[2] == 1)begin
                Seconds <= Seconds_alarm_reset;
                Minutes <= Minutes_alarm_reset;
                end
                if(sw[1] == 1)begin
                Seconds_alarm <= Seconds;
                Minutes_alarm <= Minutes;
                end

                if(sw[0] == 1) begin
                    /*Seconds_alarm <= Seconds;
                    Minutes_alarm <= Minutes;*/
                    if(Minutes_alarm == Minutes && Seconds_alarm == Seconds)
                        led <= 1;////test
                     else 
                        led <= 0;
                    /*if(Seconds == Seconds_alarm &&  Minutes == Minutes_alarm) begin //Seconds_alarm Minutes_alarm
                        led <= 0;
                    end
                    else begin
                        led <= 1;
                    end*/
                    if (counter < max_counter) begin // time
                        counter <= counter + 1;
                    end 
                    else begin
                    counter <= 0;
                    Seconds <= Seconds + 1; ///ADD BLINK FUNCTIONALITY WHEN ALARM IS REACHED
                    
                    end    
                end  //          
                end                    
            end // end Set_Clock
        endcase // end case(Current_Mode)
        
        /* Clock Stuff */
        if (Seconds >= 60) begin // After 60 seconds, increment minutes
                Seconds <= 0;
                Minutes <= Minutes + 1;
        end
        if (Minutes >= 12) begin // After 60 minutes, increment hours
                Minutes <= 0;
                Hours <= Hours + 1;
        end
        if (Hours >= 24) begin // After 12 hours, swap between AM and PM
            Hours <= 0;
        end
       
        D0 <= Seconds % 10;  // 1's of minutes
        D1 <= Seconds / 10;  // 10's of minutes            
        if (Minutes < 12) begin
            if (Minutes == 0) begin // 00:00 military = 12:00 AM
                D2 <= 2;
                D3 <= 1;
            end else begin
                D2 <= Minutes % 10;    // 1's of hours
                D3 <= Minutes / 10;    // 10's of hours
            end
            //AM_PM <= 0;
            end else begin // end Hours < 12
                if (Minutes == 12) begin //12:00 military = 12:00 PM
                    D2 <= 2;
                    D3 <= 1;
                end else begin
                    D2 <= (Minutes - 12) % 10;    // 1's of hours
                    D3 <= (Minutes - 12) / 10;    // 10's of hours
                end
                //AM_PM <= 1;                        
        end // end Hours >= 12             
    end //end always @(posedge clk)
endmodule
