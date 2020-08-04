module Top( input clk,
	output reg [9:0] leds,
	output reg vga_hsync,
	output reg vga_vsync,
	output reg [3:0] vga_r,
	output reg [3:0] vga_g,
	output reg [3:0] vga_b );

wire        lock;
wire [15:0] io_data = port_data;
reg  [15:0] mem_data;

/* interrupts */
reg         nmi;
reg         intr;
reg         inta;
reg   [7:0] irq;

/* data bus */
reg  [19:1] data_m_addr;
reg         data_mem_ack;
wire [15:0] data_m_data_in = d_io ? io_data : mem_data;
reg  [15:0] data_m_data_out;
reg         data_m_access;
wire        data_m_ack = data_mem_ack | port_ack;
reg         data_m_wr_en;
reg   [1:0] data_m_bytesel;

/* instruction bus */
reg  [19:1] instr_m_addr;
reg  [15:0] instr_m_data_in;
reg         instr_m_access;
reg         instr_m_ack;

/* multiplexed bus */
reg  [19:1] q_m_addr;
reg  [15:0] q_m_data_out;
wire [15:0] q_m_data_in = ram_data | vga_data;
wire        q_m_ack = ram_ack | vga_ack;
reg         q_m_access;
reg         q_m_wr_en;
reg   [1:0] q_m_bytesel;
reg         d_io;

/* PORTS */
reg         port_access;
reg         port_ack;
reg  [15:0] port_data;

/* RAM */
reg         ram_access;
reg         ram_ack;
reg  [15:0] ram_data;

/* VGA */
reg         vga_access;
reg         vga_ack;
reg  [15:0] vga_data;

always@(posedge sys_clk)
begin
	port_access = 0;
	if(d_io && data_m_access)
		port_access = 1;

	ram_access = 0;
	vga_access = 0;
	if(q_m_access)
	begin
		unique casez ({q_m_addr, 1'b0})
			{20'b1010_????_????_????_????}: vga_access = 1;
			default: ram_access = 1;
		endcase
	end
end

/**************/
/* MemArbiter */
/**************/
							
reg grant_to_b;
reg grant_active;

assign q_b = (grant_active && grant_to_b) || (!grant_active && (data_m_access & ~d_io));

assign q_m_addr = q_b ? data_m_addr : instr_m_addr;
assign q_m_data_out = q_b ? data_m_data_out : 0;
assign q_m_access = ~q_m_ack & ((data_m_access & ~d_io) | instr_m_access);
assign q_m_wr_en = q_b ? data_m_wr_en : 0;
assign q_m_bytesel = q_b ? data_m_bytesel : 2'b11;

assign instr_m_data_in = grant_active & ~grant_to_b ? q_m_data_in : 16'b0;
assign instr_m_ack = grant_active & ~grant_to_b & q_m_ack;
assign mem_data = grant_active & grant_to_b ? q_m_data_in : 16'b0;
assign data_mem_ack = grant_active & grant_to_b & q_m_ack;

always@(posedge sys_clk) begin
	if(q_m_ack)
		grant_active <= 0;
	else if(!grant_active && ((data_m_access & ~d_io) || instr_m_access)) begin
		grant_active <= 1;
		grant_to_b <= (data_m_access & ~d_io);
	end
end

/*******/
/* RAM */
/*******/

wire wr_en = q_m_access & ram_access & q_m_wr_en;
wire [15:0] q;
assign ram_data = ram_ack ? q : 16'b0;

always@(posedge sys_clk)
	ram_ack <= ram_access & q_m_access;

altsyncram altsyncram_component_RAM(
	.address_a(q_m_addr[$clog2(32768):1]),
	.byteena_a(q_m_bytesel),
	.clock0(sys_clk),
	.data_a(q_m_data_out),
	.wren_a(wr_en),
	.q_a(q),
	.aclr0(1'b0),
	.aclr1(1'b0),
	.address_b(1'b1),
	.addressstall_a(1'b0),
	.addressstall_b(1'b0),
	.byteena_b(1'b1),
	.clock1(1'b1),
	.clocken0(1'b1),
	.clocken1(1'b1),
	.clocken2(1'b1),
	.clocken3(1'b1),
	.data_b(1'b1),
	.eccstatus(),
	.q_b(),
	.rden_a(1'b1),
	.rden_b(1'b1),
	.wren_b(1'b0));
defparam
	altsyncram_component_RAM.byte_size = 8,
	altsyncram_component_RAM.clock_enable_input_a = "BYPASS",
	altsyncram_component_RAM.clock_enable_output_a = "BYPASS",
	altsyncram_component_RAM.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
	altsyncram_component_RAM.lpm_type = "altsyncram",
	altsyncram_component_RAM.numwords_a = 32768,
	altsyncram_component_RAM.operation_mode = "SINGLE_PORT",
	altsyncram_component_RAM.outdata_aclr_a = "NONE",
	altsyncram_component_RAM.outdata_reg_a = "UNREGISTERED",
	altsyncram_component_RAM.power_up_uninitialized = "FALSE",
	altsyncram_component_RAM.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
	altsyncram_component_RAM.widthad_a = $clog2(32768),
	altsyncram_component_RAM.width_a = 16,
	altsyncram_component_RAM.width_byteena_a = 2,
	altsyncram_component_RAM.init_file = "bios.mif";

/*******/
/* VGA */
/*******/
 
reg  [9:0] cntx;
reg  [9:0] cnty;
reg  [7:0] pixel_value;
reg [15:0] pix_address;

wire vga_wr_en = q_m_access & vga_access & q_m_wr_en;

always@(posedge sys_clk)
	vga_ack <= vga_access & q_m_access;
	 
always@(posedge vga_clk)
begin
	pix_address <= (cntx>>1) + (cnty>>1)*320;
	cntx <= cntx + 1;
	if(cntx==799)
	begin
		cntx <= 0;
		cnty <= cnty + 1;
	end

	if(cnty==448)
		cnty <= 0;

	vga_hsync <= (cntx>639+16 & cntx<639+16+96);
	vga_vsync <= (cnty>399+12 & cnty<399+12+2);
		
	if(cntx>639|cnty>399)
	begin
		vga_r <= 0;
		vga_g <= 0;
		vga_b <= 0;
	end
	else
	begin
		vga_r <= pixel_value[3:0];
		vga_g <= pixel_value[3:0];
		vga_b <= pixel_value[3:0];
	end
end

altsyncram altsyncram_component_VGA (
	.address_a(q_m_addr[15:1]),
	.address_b(pix_address[15:0]),
	.byteena_a(q_m_bytesel),
	.clock0(sys_clk),
	.clock1(vga_clk),
	.data_a(q_m_data_out),
	.data_b(data_b),
	.wren_a(vga_wr_en),
	.wren_b(0),
	.q_a(vga_data),
	.q_b(pixel_value),
	.aclr0(1'b0),
	.aclr1(1'b0),
	.addressstall_a(1'b0),
	.addressstall_b(1'b0),
	.byteena_b (1'b1),
	.clocken0(1'b1),
	.clocken1(1'b1),
	.clocken2(1'b1),
	.clocken3(1'b1),
	.eccstatus(),
	.rden_a(0),
	.rden_b(1));
defparam
	altsyncram_component_VGA.address_reg_b = "CLOCK1",
	altsyncram_component_VGA.byte_size = 8,
	altsyncram_component_VGA.clock_enable_input_a = "BYPASS",
	altsyncram_component_VGA.clock_enable_input_b = "BYPASS",
	altsyncram_component_VGA.clock_enable_output_a = "BYPASS",
	altsyncram_component_VGA.clock_enable_output_b = "BYPASS",
	altsyncram_component_VGA.indata_reg_b = "CLOCK1",
	altsyncram_component_VGA.intended_device_family = "Cyclone V",
	altsyncram_component_VGA.lpm_type = "altsyncram",
	altsyncram_component_VGA.numwords_a = 32768,
	altsyncram_component_VGA.numwords_b = 65536,
	altsyncram_component_VGA.operation_mode = "BIDIR_DUAL_PORT",
	altsyncram_component_VGA.outdata_aclr_a = "NONE",
	altsyncram_component_VGA.outdata_aclr_b = "NONE",
	altsyncram_component_VGA.outdata_reg_a = "UNREGISTERED",
	altsyncram_component_VGA.outdata_reg_b = "UNREGISTERED",
	altsyncram_component_VGA.power_up_uninitialized = "FALSE",
	altsyncram_component_VGA.ram_block_type = "M10K",
	altsyncram_component_VGA.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
	altsyncram_component_VGA.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
	altsyncram_component_VGA.widthad_a = 15,
	altsyncram_component_VGA.widthad_b = 16,
	altsyncram_component_VGA.width_a = 16,
	altsyncram_component_VGA.width_b = 8,
	altsyncram_component_VGA.width_byteena_a = 2,
	altsyncram_component_VGA.width_byteena_b = 1,
	altsyncram_component_VGA.wrcontrol_wraddress_reg_b = "CLOCK1";

/*********/
/* PORTS */
/*********/

always@(posedge sys_clk)
begin
	if(port_access && data_m_access && data_m_bytesel[1] && data_m_wr_en)
		leds[9:8] <= data_m_data_out[9:8];
	if(port_access && data_m_access && data_m_bytesel[0] && data_m_wr_en)
		leds[7:0] <= data_m_data_out[7:0];
	port_data <= port_access & data_m_access ? 16'(leds) : 16'b0;
	port_ack <= port_access & data_m_access;
end  

/********/
/* CORE */
/********/

Core Core(.reset(0), .clk(sys_clk), .*);

/*******/
/* PLL */
/*******/

PLL PLL(
	.refclk(clk),
	.outclk_0(sys_clk),
	.outclk_1(vga_clk)
	);		

endmodule