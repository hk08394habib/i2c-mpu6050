`timescale 1ns / 1ps
module top(
    input clk,
    inout [7:0] JA,
    input [15:0] sw,
    output [15:0] led
);

//will cycle through this to read the rest once i get one working
/*
wire signed [15:0] gx;
wire signed [15:0] gy;
wire signed [15:0] gz;
wire signed [15:0] ax;
wire signed [15:0] ay;
wire signed [15:0] az;
*/

wire [7:0]dataline;

//setting up open-drain connection
wire scl_i,sda_i;
wire scl_o,sda_o;
assign scl_i = JA[0];
assign JA[0] = scl_o ? 1'bz : 1'b0;
assign scl_i = JA[1];
assign JA[1] = sda_o ? 1'bz : 1'b0;

wire slowclk;


clk_div divider(.clock_in(clk), .clock_out(slowclk));
defparam divider.DIVISOR = 10000000;

reg [4:0]count=0;

always @(posedge slowclk) begin
	if (slaverdy && ~(missedACK)) 
		count = count + 1;//if your slave is ready and you haven't missed an ACK, move to next state
	case (count)
		0 : begin //send start
			start <= 1;
			count = count + 1; //move to next state
		end
		1 : begin
			readwrite <= 0; //write
			writedata <= 8'h3b; //read this address
		end
		2 : begin
			readwrite <= 1; //begin read
		end

		3 : begin
			count <= 0; //restart cycle
			stop <= 1; //send stop
		end
	endcase
end

reg readwrite; //write when 0, read when 1 
reg start;
reg stop;
reg [7:0]writedata;
wire slaverdy;
wire missedACK;



wire [7:0]data;

i2c_master test_master(
		.clk(slowclk),
		.rst(1'b0),
		.s_axis_cmd_address(7'b1101000),
		.s_axis_cmd_start(start),
		.s_axis_cmd_read(~readwrite),
		.s_axis_cmd_write(readwrite),
		.s_axis_cmd_write_multiple(1'b0),
		.s_axis_cmd_stop(stop),
		.s_axis_cmd_valid(1'b0),
		.s_axis_cmd_ready(led[15]),

		.s_axis_data_tdata(writedata),
		.s_axis_data_tvalid(),
		.s_axis_data_tready(slaverdy),
		.s_axis_data_tlast(),

		.m_axis_data_tdata(data),
		.m_axis_data_tvalid(),
		.m_axis_data_tready(1'b1),
		.m_axis_data_tlast(),

		.scl_i(scl_i),
		.scl_o(scl_o),
		.scl_t(),

		.sda_i(sda_i),
		.sda_o(sda_o),
		.sda_t(),

		.busy(led[15]),
		.bus_control(led[14]),
		.bus_active(led[13]),
		.missed_ack(missedACK),

		.prescale(16'd1), //TODO:NEED TO FIGURE OUT WHAT THIS CLOCK THING IS
		.stop_on_idle(1'b0)
	);

assign led[7:0] = data;
assign led[12] = missedACK;
//bus active on 13
//buc control on 14
//busy on 15

endmodule
