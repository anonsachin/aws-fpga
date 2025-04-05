`include "common_base_test.svh"

task compare_values(logic [63:0] act_data, exp_data, logic [63:0] addr);
   if(act_data !== exp_data) begin
      $error("[%t] ***ERROR*** : Data Mismatch Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
      error_count ++;
   end
   else begin
      $display("[%t]: Data Matched Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
   end
endtask

module cl_gate_peek_poke_test();
   import tb_type_defines_pkg::*;

   logic [63:0]  addr;
   logic [63:0]  read_data;
   localparam NUMBER_OF_STAGES = 2;
   AgentPkg::GateConfig agent_confgs [0:NUMBER_OF_STAGES - 1];
   AXILitePkg::GateConfigStore store;

   assign store.configValue[0] = agent_confgs[0];
   assign store.configValue[1] = agent_confgs[1];

   initial begin
    $dumpfile("waves.vcd");
    $dumpvars (0, tb.card.fpga.CL);

      tb.power_up();
      
      addr = 63'd0;
      tb.poke_ocl(.addr(addr), .data(store.data[0]));

      #60ns;
      tb.peek_ocl(.addr(addr), .data(read_data));
      compare_values(.act_data(read_data), .exp_data(store.data[0]), .addr(addr));

      addr = 63'd1 << 2;
      tb.poke_ocl(.addr(addr), .data(32'd3));

      #60ns;
      tb.peek_ocl(.addr(addr), .data(read_data));
      compare_values(.act_data(read_data), .exp_data(64'd3), .addr(addr));

      #1500ns;
      tb.power_down();

      report_pass_fail_status();

      $finish;
   end
endmodule
