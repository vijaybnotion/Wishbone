//////////////////////////////////////////////////////////////////////
////                                                              ////
////  can_defines.v                                               ////
////                                                              ////
////                                                              ////
////  This file is part of the CAN Protocol Controller            ////
////  http://www.opencores.org/projects/can/                      ////
////                                                              ////
////                                                              ////
////  Author(s):                                                  ////
////       Igor Mohor                                             ////
////       igorm@opencores.org                                    ////
////                                                              ////
////                                                              ////
////  All additional information is available in the README.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002, 2003, 2004 Authors                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//// The CAN protocol is developed by Robert Bosch GmbH and       ////
//// protected by patents. Anybody who wants to implement this    ////
//// CAN IP core on silicon has to obtain a CAN protocol license  ////
//// from Bosch.                                                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


// Uncomment following line if you want to use WISHBONE interface. Otherwise
// 8051 interface is used.
`define   CAN_WISHBONE_IF

// Uncomment following line if you want to use CAN in Actel APA devices (embedded memory used)
// `define   ACTEL_APA_RAM

// Uncomment following line if you want to use CAN in Altera devices (embedded memory used)
// `define   ALTERA_RAM

// Uncomment following line if you want to use CAN in Xilinx devices (embedded memory used)
// `define   XILINX_RAM

// Uncomment the line for the ram used in ASIC implementation
// `define   VIRTUALSILICON_RAM
// `define   ARTISAN_RAM

// Uncomment the following line when RAM BIST is needed (ASIC implementation)
//`define CAN_BIST                    // Bist (for ASIC implementation)

/* width of MBIST control bus */
//`define CAN_MBIST_CTRL_WIDTH 3
