
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

module cl_adder_peek_poke_test();
   import tb_type_defines_pkg::*;

   logic [63:0]  addr;
   logic [63:0]  read_data;

   initial begin
    $dumpfile("waves.vcd");
    $dumpvars (0, tb.card.fpga.CL);

      tb.power_up();
      
      addr = 63'd0;
      tb.poke_ocl(.addr(addr), .data(32'd1));

      #30ns;
      tb.peek_ocl(.addr(addr), .data(read_data));
      compare_values(.act_data(read_data), .exp_data(64'd1), .addr(addr));

      addr = 63'd1 << 2;
      tb.poke_ocl(.addr(addr), .data(32'd2));

      #30ns;
      tb.peek_ocl(.addr(addr), .data(read_data));
      compare_values(.act_data(read_data), .exp_data(64'd2), .addr(addr));

      #30ns;
      addr = 63'd2 << 2;
      tb.peek_ocl(.addr(addr), .data(read_data));
      compare_values(.act_data(read_data), .exp_data(64'd3), .addr(addr));

      #500ns;
      tb.power_down();

      report_pass_fail_status();

      $finish;
   end
endmodule