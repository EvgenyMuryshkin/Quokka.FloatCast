/*
 *  64 bit integer to float converter
 *
 *  Copyright (C) 2019  Evgeny Muryshkin <evmuryshkin@gmail.com>
 *
 *  Part of Quokka FPGA toolkit
 *  https://github.com/EvgenyMuryshkin/QuokkaEvaluation
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
module IntToFloat(
	input clk, inTrigger, inIsSigned,
	input [63:0] inData,
	output [31:0] outData,
	output outReady
);
	// checks
	wire isZero = inData == 0;
	wire isNegative = inIsSigned & inData[63];
	
	// set and assign outputs
	reg ready = 1;
	assign outReady = ready;

	reg [31:0] result = 0;
	assign outData = result;

	// converter state
	reg sign = 0;
	reg [63: 0] buff = 0;
	reg [6:0] shift = 0;
	
  	wire roundingType1 = buff[39:0] > 40'h80_00_00_00_00;
  	wire roundingType2 = buff[40:39] == 2'b11;
	wire [23:0] mantissa = buff[62:40] + (roundingType1 | roundingType2); // with rounding
	wire [7:0] 	exponent = 8'h7F + shift + mantissa[23]; // with mantissa overflow
	wire [30:0] value = {exponent, mantissa[22:0]};
	wire canFastShift = buff[63:60] == 0;
	
	always @ (posedge clk)
	begin
		if (inTrigger)
			begin
				ready <= isZero;
				result <= 0;
				shift <= 6'h3F;
				sign <= isNegative;
				buff <= isNegative ? (~inData[63:0]) + 1 : inData;
			end
		else if (!ready)
			begin
				ready <= buff[63];
				result <= {sign, value};
				shift <= canFastShift ? shift - 3'b100 : shift - 1'b1;
				buff <= canFastShift ? {buff[59:0], 4'b0000} : {buff[62:0], 1'b0};
			end
	end

endmodule