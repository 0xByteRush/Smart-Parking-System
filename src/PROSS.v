`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:32:59 12/07/2024 
// Design Name: 
// Module Name:    Smart_Parking_System 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


// Main project module
module Smart_Parking_System(
input sysclk, reset, normal_enter, normal_exit, handicap_enter,handicap_exit, 
output LED_Handicap_RED, LED_Handicap_GREEN, LED_Normal_RED, LED_Normal_GREEN,   [7:0] seg, an
);
	
	// Declarations
    reg [4:0] normal_count;
    reg [2:0] handicap_count;
	 
	 // Previous clock cycle button signals declarations
	 reg entry_normal_prev, exit_normal_prev;
	 reg entry_handicap_prev, exit_handicap_prev;

	 wire clean_normal_enter,clean_normal_exit,clean_handicap_enter,clean_handicap_exit;
	 wire entry_pulse, exit_pulse;
	
	// Debouncer declarations for push buttons
	debounce debounced_signal (sysclk,normal_enter,clean_normal_enter); // normal_enter M17
	debounce debounced_signal1 (sysclk,normal_exit,clean_normal_exit); // normal_exit P18
	debounce debounced_signal2 (sysclk,handicap_enter,clean_handicap_enter); // handicap_enter M18
	debounce debounced_signal3 (sysclk,handicap_exit,clean_handicap_exit); // handicap_exit P17
	
	// Assigning Red and Green LEDs on the FPGA board depending on the values of the normal parking counts and the handicap parking counts
	assign LED_Handicap_RED = handicap_count == 0;
	assign LED_Handicap_GREEN = handicap_count > 0; 
	assign LED_Normal_RED = normal_count == 0;
	assign LED_Normal_GREEN = normal_count > 0;

    always @(posedge sysclk or posedge reset) begin
			// Resetting the previous inputs to 0 
        if (reset) begin
            entry_normal_prev <= 0;
            exit_normal_prev <= 0;
				entry_handicap_prev <= 0;
            exit_handicap_prev <= 0;
        end 
		  
		  // Setting the previous inputs to the resepective debouncers' outputs 
		  else begin
            entry_normal_prev <= clean_normal_enter; 
            exit_normal_prev <= clean_normal_exit;
				entry_handicap_prev <= clean_handicap_enter; 
            exit_handicap_prev <= clean_handicap_exit; 
        end
    end
	
	// Assigning entry and exit pulses for the entry and exit buttons for the normal and handicapped parkings respectively
    assign normal_entry_pulse = clean_normal_enter && !entry_normal_prev;
    assign normal_exit_pulse = clean_normal_exit && !exit_normal_prev;
	 assign handicap_entry_pulse = clean_handicap_enter && !entry_handicap_prev;
    assign handicap_exit_pulse = clean_handicap_exit && !exit_handicap_prev;
	 
    always @(posedge sysclk or posedge reset) begin
			// Resetting the normal parking count to 20 and handicap count to 5
        if (reset) begin
            normal_count <= 5'd20;
            handicap_count <= 3'd5;
        end
		  
		  else begin
				// Decrementing  the parking count of the normal parking if the entry button pulse, the debouncer output are detected and the parking count is greater than 0
            if (normal_entry_pulse && clean_normal_enter && normal_count > 0) 
                normal_count <= normal_count - 1; 
				// Incrementing the parking count of the normal parking if the exit button pulse, the debouncer output are detected and the parking count is less than 20
            else if (normal_exit_pulse && clean_normal_exit && normal_count < 5'd20) 
                normal_count <= normal_count + 1; 
            
				// Decrementing  the parking count of the handicapped parking if the handicapped entry button pulse, the debouncer output are detected and the handicapped parking count is greater than 0
            if (handicap_entry_pulse && clean_handicap_enter && handicap_count > 0) 
                handicap_count <= handicap_count - 1;
				// Incrementing the parking count of the handicapped parking if the handicapped exit button pulse, the debouncer output are detected and the handicapped parking count is less than 5
            else if (handicap_exit_pulse && clean_handicap_exit && handicap_count < 3'd5) 
                handicap_count <= handicap_count + 1; 
        end
    end

	// Seven segment display to display the parking type labels and the available parking counts
	DISP7SEG ssd (sysclk, normal_count % 10, normal_count / 10, 12, 10, handicap_count, 12, 10, 11, text_mode, slow, med, fast, error, seg, an);
endmodule