`include "common_base_test.svh"

task equate_values(logic [63:0] act_data, exp_data, logic [63:0] addr);
   if(act_data !== exp_data) begin
      $error("[%t] ***ERROR*** : Data Mismatch Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
      error_count ++;
   end
   else begin
      $display("[%t]: Data Matched Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
   end
endtask

task negate_values(logic [63:0] act_data, exp_data, logic [63:0] addr);
   if(act_data == exp_data) begin
      $error("[%t] ***ERROR*** : Data Matched Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
      error_count ++;
   end
   else begin
      $display("[%t]: ***INFO*** Data Mismatch Addr: %0h. Actual Data:%0h <==> Expected Data: %0h", $realtime, addr, act_data, exp_data);
   end
endtask


module cl_agent_config_test();
   import tb_type_defines_pkg::*;

   SoftwareInterfacePkg::FullAgentConfigStore store_write, store_read;
   logic [63:0]  addr, start_addr;
   logic [63:0]  read_data;
   AgentPkg::GateConfig agent_configs [0:4];
   ShufflePkg::Targets targets;
   ShufflePkg::Controls controls;
   ShufflePkg::ActiveWire active_wire;

   initial begin
      $dumpfile("config_probe.vcd");
      $dumpvars (0, tb.card.fpga.CL);
      tb.power_up(.clk_recipe_a(ClockRecipe::A0),
                  .clk_recipe_b(ClockRecipe::B0),
                  .clk_recipe_c(ClockRecipe::C0));
    

    // Reference gate configurations
      agent_configs[0].gateSelect = 4'd2;
      agent_configs[0].cSelect = 4'd1;
      agent_configs[0].bSelect = 4'd2;
      agent_configs[0].aSelect = 4'd8;

      agent_configs[1].gateSelect = 4'd3;
      agent_configs[1].cSelect = 4'd3;
      agent_configs[1].bSelect = 4'd4;
      agent_configs[1].aSelect = 4'd9;

      agent_configs[2].gateSelect = 4'd9;
      agent_configs[2].cSelect = 4'd5;
      agent_configs[2].bSelect = 4'd6;
      agent_configs[2].aSelect = 4'd10;

      agent_configs[3].gateSelect = 4'd6;
      agent_configs[3].cSelect = 4'd7;
      agent_configs[3].bSelect = 4'd8;
      agent_configs[3].aSelect = 4'd0;

      agent_configs[4].gateSelect = 4'd5;
      agent_configs[4].cSelect = 4'd3;
      agent_configs[4].bSelect = 4'd7;
      agent_configs[4].aSelect = 4'd2;

      store_write.configValue.configValue.gateConfigs[0] = agent_configs[0];
      store_write.configValue.configValue.gateConfigs[1] = agent_configs[1];
      store_write.configValue.configValue.gateConfigs[2] = agent_configs[2];
      store_write.configValue.configValue.gateConfigs[3] = agent_configs[3];
      store_write.configValue.configValue.gateConfigs[4] = agent_configs[4];

    // Active wire lists
    active_wire.position = 4'd0;
    active_wire.present = 1'b0;
    targets.row[0] = active_wire;
    controls.row[0][0] = {0};
    controls.row[0][1] = {0};

    active_wire.position = 4'd3;
    active_wire.present = 1'b1;
    targets.row[1] = active_wire;
    controls.row[1][0] = {0};
    controls.row[1][1] = {0};

    targets.row[2] = {0};
    controls.row[2][0] = {0};
    controls.row[2][1] = {0};

    targets.row[3] = {0};
    controls.row[3][0] = {0};
    controls.row[3][1] = {0};

    targets.row[4] = {0};
    active_wire.position = 4'd7;
    active_wire.present = 1'b1;
    controls.row[4][0] = active_wire;
    active_wire.position = 4'd3;
    active_wire.present = 1'b1;
    controls.row[4][1] = active_wire;

    $display("The active wire of the target are = ", controls.row);

    for (int i=0; i<5; i++) begin
      $display("The active wire of the target[%0d] is %0d", i, targets.row[i].position);
      $display("The active wire of the control[%0d][0] is %0d", i, controls.row[i][0].position);
      $display("The active wire of the control[%0d][1] is %0d", i, controls.row[i][1].position);
        store_write.configValue.configValue.shuffleWires[0][i] = targets.row[i];
        store_write.configValue.configValue.shuffleWires[1][i] = controls.row[i][0];
        store_write.configValue.configValue.shuffleWires[2][i] = controls.row[i][1];
        store_write.configValue.configValue.sampleLfsrSeeds[i] = {10'd123, 10'd123};
    end
        store_write.configValue.configValue.shuffleLfsrSeeds = {32'd74328, 32'd66844};
     store_write.configValue.pad = 1'b0;

    start_addr = 64'd0;
    for (int i=1; i<=10; i++) begin
        addr = start_addr + (i << 2);
        tb.poke_ocl(.addr(addr), .data(store_write.data[i - 1]));
    end

    #10ns;
    // Enabling design
    tb.poke_ocl(.addr(start_addr), .data(32'd3));

    #100ns;
    tb.peek_ocl(.addr(start_addr), .data(read_data));
    negate_values(.act_data(read_data), .exp_data(32'd3), .addr(start_addr));

      #500ns;
      tb.power_down();

      report_pass_fail_status();

      $finish;
   end
endmodule