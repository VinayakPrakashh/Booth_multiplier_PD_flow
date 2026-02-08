###############  SDC CONSTRAINTS   ############

##### PARAMETERS #####
set_units -time 1.0ns
set_units -capacitance 1.0pF

set CLOCK_PERIOD 20
set CLOCK_NAME core_clk

set SKEW_setup  [expr $CLOCK_PERIOD*0.025]
set SKEW_hold   [expr $CLOCK_PERIOD*0.025]
set MINRISE     [expr $CLOCK_PERIOD*0.125]
set MAXRISE     [expr $CLOCK_PERIOD*0.2]
set MINFALL     [expr $CLOCK_PERIOD*0.125]
set MAXFALL     [expr $CLOCK_PERIOD*0.2]

set MIN_PORT 1
set MAX_PORT 2.5


####### CLOCK CONSTRAINTS #########

create_clock -name "$CLOCK_NAME" \
    -period "$CLOCK_PERIOD" \
    -waveform "0 [expr $CLOCK_PERIOD/2]" \
    [get_ports "clk_pad"]

## Virtual Clock
create_clock -name vir_clk_i -period $CLOCK_PERIOD


## Clock source latency
set_clock_latency -source -max 1.25 -late  [get_clocks core_clk]
set_clock_latency -source -min 0.75 -late  [get_clocks core_clk]
set_clock_latency -source -max 1.0  -early [get_clocks core_clk]
set_clock_latency -source -min 1.25 -early [get_clocks core_clk]


# Clock transition
set_clock_transition -rise -min $MINRISE [get_clocks core_clk]
set_clock_transition -rise -max $MAXRISE [get_clocks core_clk]
set_clock_transition -fall -min $MINFALL [get_clocks core_clk]
set_clock_transition -fall -max $MAXFALL [get_clocks core_clk]


# Clock uncertainty
set_clock_uncertainty -setup $SKEW_setup [get_clocks core_clk]
set_clock_uncertainty -hold  $SKEW_hold  [get_clocks core_clk]


####### INPUT TRANSITIONS ########

set_input_transition -max $MAX_PORT [get_ports {a_pad[*] b_pad[*] start_pad}]
set_input_transition -min $MIN_PORT [get_ports {a_pad[*] b_pad[*] start_pad}]


####### INPUT DELAYS ########

set_input_delay -add_delay -clock vir_clk_i -max 7.75 [get_ports {a_pad[*] b_pad[*] start_pad}]
set_input_delay -add_delay -clock vir_clk_i -min 2.25 [get_ports {a_pad[*] b_pad[*] start_pad}]


####### OUTPUT DELAYS ########

set_output_delay -clock vir_clk_i -max 3.931 [get_ports {data_out_pad[*] done_pad}] -add_delay
set_output_delay -clock vir_clk_i -min 2.628 [get_ports {data_out_pad[*] done_pad}] -add_delay


####### LOAD SPECIFICATIONS ########

set_load 5 [get_ports {data_out_pad[*] done_pad}]


########## FALSE PATHS ###########

# async reset
set_false_path -from [get_ports rst_pad] -to [all_registers]
set_false_path -from [all_registers] -to [get_ports rst_pad]

########## GROUP PATHS #########

group_path -name I2R -from [all_inputs]    -to [all_registers]
group_path -name R2O -from [all_registers] -to [all_outputs]
group_path -name R2R -from [all_registers] -to [all_registers]
group_path -name I2O -from [all_inputs]    -to [all_outputs]
