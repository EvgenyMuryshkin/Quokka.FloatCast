/*
 *  Float to 64 bit integer converter
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
module FloatToInt(
	input clk, inTrigger,
	input [31:0] inData,
	output outReady,
	output outException,
	output [63:0] outData
);
	wire isZero = inData == 0;
	wire isInvalid = inData[30:23] == 8'hFF; // NaN and Infinities
	wire isLessThenOne = inData[30:23] < 8'h7F; // exponent should be >= 127
	
	// state
	reg ready = 1;
	reg [63:0] result = 0;
	reg nextBit = 0;
	reg isNegative = 0;
	reg [7:0] exponent = 0;
	reg [22:0] mantissa = 0;
	
	wire [64:0] complement = ~result + 1;
	
	// outputs
	assign outData = isNegative ? {complement[64], complement[62:0]} : result[63:0];
	assign outException = isInvalid;
	assign outReady = ready;
	
	wire skipConvert = isZero | isInvalid | isLessThenOne;
	always @ (posedge clk)
		begin
			if (inTrigger)
				begin
					ready <= skipConvert;
					isNegative <= inData[31];
					exponent <= inData[30:23];
					mantissa <= inData[22:0];
					result <= isInvalid ? {1'b1, 63'h0} : 0;
					nextBit <= !skipConvert;
				end
			else if (!ready)
				begin
					ready <= exponent == 8'h7F;
					exponent <= exponent - 1'b1;
					result <= {result[62:0], nextBit};
					nextBit <= mantissa[22];
					mantissa <= {mantissa[21:0], 1'b0};
				end
		end
endmodule
