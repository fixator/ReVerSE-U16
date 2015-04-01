asmi_inst : asmi PORT MAP (
		addr	 => addr_sig,
		asmi_dataout	 => asmi_dataout_sig,
		clkin	 => clkin_sig,
		rden	 => rden_sig,
		read	 => read_sig,
		reset	 => reset_sig,
		asmi_dataoe	 => asmi_dataoe_sig,
		asmi_dclk	 => asmi_dclk_sig,
		asmi_scein	 => asmi_scein_sig,
		asmi_sdoin	 => asmi_sdoin_sig,
		busy	 => busy_sig,
		data_valid	 => data_valid_sig,
		dataout	 => dataout_sig
	);
