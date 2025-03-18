`ifndef AXIL_ADDER
 `define AXIL_ADDER


module axil_adder (
  input wire clk,
  input wire resetn,
  input  logic  [31:0]  axil_awaddr,
  input  logic  [54:0]  axil_awuser,
  input  logic          axil_awvalid,
  output logic          axil_awready,

  input  logic  [31:0]  axil_wdata,
  input  logic   [3:0]  axil_wstrb,
  input  logic          axil_wvalid,
  output logic          axil_wready,

  output logic   [1:0]  axil_bresp,
  output logic          axil_bvalid,
  input  logic          axil_bready,

  input  logic  [31:0]  axil_araddr,
  input  logic  [54:0]  axil_aruser,
  input  logic          axil_arvalid,
  output logic          axil_arready,

  output logic  [31:0]  axil_rdata,
  output logic   [1:0]  axil_rresp,
  output logic          axil_rvalid,
  input  logic          axil_rready,
);

///////////////////////////////////////////////////////////////////////////
// operands for addition
///////////////////////////////////////////////////////////////////////////
logic [31:0] operand_1, operand_2;
logic [31:0] result;


///////////////////////////////////////////////////////////////////////////
// writing operands
///////////////////////////////////////////////////////////////////////////
logic [1:0] write_addr;
logic mask_enable;
assign axil_awready = 1;

always_ff @ (posedge clk)
begin
if(resetn)
begin
    if(axil_awvalid)
    begin
        mask_enable <= | axil_awaddr[31:4];
        write_addr <= axil_awaddr[3:2];
    end
end
else
begin
  mask_enable <= 0;
  write_addr <= 0;
end
end

///////////////////////////////////////////////////////////////////////////
// writing operands
///////////////////////////////////////////////////////////////////////////
assign axil_wready = 1;
always_ff @ (posedge clk)
begin
if(resetn)
begin
  if (axil_wvalid & (~mask_enable))
  begin
    case (write_addr[0])
        1'b0:
        begin
            for ( integer byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
	        if ( axil_wstrb[byte_index] == 1 ) 
            begin
	          // Respective byte enables are asserted as per write strobes
	          // Slave register 0
	          operand_1[(byte_index*8) +: 8] <= axil_wdata[(byte_index*8) +: 8];
	        end
        end
        1'b1:
        begin
            for ( integer byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
	        if ( axil_wstrb[byte_index] == 1 ) 
            begin
	          // Respective byte enables are asserted as per write strobes
	          // Slave register 0
	          operand_2[(byte_index*8) +: 8] <= axil_wdata[(byte_index*8) +: 8];
	        end
        end
    endcase
  end
end
else
begin
  operand_1 <= 0;
  operand_2 <= 0;
end
end

///////////////////////////////////////////////////////////////////////////
// write response
///////////////////////////////////////////////////////////////////////////
assign axil_bresp = 0;
always_ff @ (posedge clk)
begin
if(resetn)
begin
  axil_bvalid <= axil_bready;
end
else
begin
  axil_bvalid <= 0;
end
end

///////////////////////////////////////////////////////////////////////////
// operation
///////////////////////////////////////////////////////////////////////////

assign result = operand_1 + operand_2;

///////////////////////////////////////////////////////////////////////////
// reading operands and result
///////////////////////////////////////////////////////////////////////////
logic [1:0] read_addr;
logic read_mask_enable;
assign axil_arready = 1;

always_ff @ (posedge clk)
begin
if(resetn)
begin
    if(axil_arvalid)
    begin
        read_mask_enable <= | axil_araddr[31:4];
        read_addr <= axil_araddr[3:2];
    end
end
else
begin
  read_mask_enable <= 0;
  read_addr <= 0;
end
end

///////////////////////////////////////////////////////////////////////////
// reading operands
///////////////////////////////////////////////////////////////////////////
assign axil_rresp = 0;
always_ff @ (posedge clk)
begin
if(resetn)
begin
  if (axil_rready)
  begin
     axil_rvalid <= 1;
     if (mask_enable)
      axil_rdata <= 0;
     else
     begin
      case (read_addr)
        2'b00:
         axil_rdata <= operand_1;
        2'b01:
         axil_rdata <= operand_2;
        2'b10:
         axil_rdata <= result;
        default:
         axil_rdata <= 0;
      endcase
     end
  end
  else
  begin
    axil_rdata <= 0;
    axil_rvalid <= 0;
  end
end
else
begin
  axil_rdata <= 0;
  axil_rvalid <= 0;
end
end


endmodule


`endif