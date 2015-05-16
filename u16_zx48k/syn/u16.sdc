set_time_format -unit ns -decimal_places 3
create_clock -name {CLK_50MHZ} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK_50MHZ}]
derive_pll_clocks
derive_clock_uncertainty
