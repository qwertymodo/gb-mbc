//******************************************************************************
//* mbc5.v
//* 
//* GameBoy memory bank controller
//* Max ROM size: 64Mbit
//* Max SRAM size: 1Mbit
//* 
//* $0000-3FFF  (R): ROM Bank 0
//* $4000-7FFF  (R): ROM Bank $00-1FF
//* $A000-BFFF (RW): RAM Bank $00-0F (Unlike MBC1, Bank $00 is actually $00)
//* $0000-1FFF  (W): RAM Enable ($0A = Enable, anything else = Disable)
//* $2000-2FFF  (W): ROM Bank, low 8 bits
//* $3000-3FFF  (W): ROM Bank, high bit
//* $4000-5FFF  (W): RAM Bank
//******************************************************************************

module mbc5(
    input [15:12] addr,
    input [7:0] data,
    input cs,
    input phi,		// Not used on the original MBC5, only needed for FRAM support
    input rd,		// Not used on the original MBC5, only needed for FRAM support
    input wr,
    input rst,
    output [22:14] roma,
    output reg [16:13] rama,
    output ramsel
    );

reg [22:14] romb;
reg ramen;

assign roma = addr[14] ? romb : 9'd0;

// The final || phi || (rd && wr) does not match the original behavior. It
// is included to support FRAM which requires /CS to toggle on every access.
assign ramsel = cs || !ramen || addr[15:13] != 3'b101 || phi || (rd && wr);

always @(negedge rst or posedge wr)
begin
    if(!rst)
    begin
        romb = 9'd1;
        rama = 4'd0;
        ramen = 1'b0;
    end
    else
        casex(addr)
            4'b000x:    // $0000-1FFF: RAM enable, $0A = On, Anything else = Off
            begin
                if(data == 8'h0A)
                begin
                    romb = romb;
                    rama = rama;
                    ramen = 1'b1;
                end
                else
                begin
                    romb = romb;
                    rama = rama;
                    ramen = 1'b0;
                end
            end
            
            4'b0010:    // $2000-2FFF: Low 8 bits of ROM Bank
            begin
                romb = {romb[22], data};
                rama = rama;
                ramen = ramen;
            end
            
            4'b0011:    // $3000-3FFF: High bit of ROM Bank
            begin
                romb = {data[0], romb[21:14]};
                rama = rama;
                ramen = ramen;
            end
            
            4'b010x:    // $4000-5FFF: RAM Bank
            begin
                romb = romb;
                rama = data;
                ramen = ramen;
            end
            
            default:
            begin
                romb = romb;
                rama = rama;
                ramen = ramen;
            end
        endcase
end

endmodule
