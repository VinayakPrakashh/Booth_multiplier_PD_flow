
module top (
    input clk_pad, rst_pad, start_pad,
    input [3:0] a_pad, b_pad,
    output [7:0] data_out_pad,
    output done_pad
);

wire clk, rst, start;
wire [3:0] a, b;
wire [7:0] data_out;
wire done;

wire clk_w;

wire sftA, clrA, ldA;
wire sftQ, clrQ, ldQ;
wire ldM, clrff, add_sub;
wire ldC, dec, enf;
wire q0, q1, eqz;
//input clock pad
pc3d01 pc3d01_1(.PAD (clk_pad), .CIN (clk_w)); 
pc3c01 pc3c01_1(.CCLK (clk_w), .CP (clk));
//input pads
pc3d01 pc3d01_2(.PAD (rst_pad), .CIN (rst));
pc3d01 pc3d01_3(.PAD (start_pad), .CIN (start));
pc3d01 pc3d01_4(.PAD (a_pad[3]), .CIN (a[3]));
pc3d01 pc3d01_5(.PAD (a_pad[2]), .CIN (a[2]));
pc3d01 pc3d01_6(.PAD (a_pad[1]), .CIN (a[1]));
pc3d01 pc3d01_7(.PAD (a_pad[0]), .CIN (a[0]));
pc3d01 pc3d01_8(.PAD (b_pad[3]), .CIN (b[3]));
pc3d01 pc3d01_9(.PAD (b_pad[2]), .CIN (b[2]));
pc3d01 pc3d01_10(.PAD (b_pad[1]), .CIN (b[1]));
pc3d01 pc3d01_11(.PAD (b_pad[0]), .CIN (b[0]));
//output pads
pc3o05 pc3o05_1(.I (data_out[7]), .PAD (data_out_pad[7]));
pc3o05 pc3o05_2(.I (data_out[6]), .PAD (data_out_pad[6]));
pc3o05 pc3o05_3(.I (data_out[5]), .PAD (data_out_pad[5]));
pc3o05 pc3o05_4(.I (data_out[4]), .PAD (data_out_pad[4]));
pc3o05 pc3o05_5(.I (data_out[3]), .PAD (data_out_pad[3]));
pc3o05 pc3o05_6(.I (data_out[2]), .PAD (data_out_pad[2]));
pc3o05 pc3o05_7(.I (data_out[1]), .PAD (data_out_pad[1]));
pc3o05 pc3o05_8(.I (data_out[0]), .PAD (data_out_pad[0]));
pc3o05 pc3o05_9(.I (done), .PAD (done_pad));

datapath dp (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .sftA(sftA),
    .clrA(clrA),
    .ldA(ldA),
    .sftQ(sftQ),
    .clrQ(clrQ),
    .ldQ(ldQ),
    .ldM(ldM),
    .clrff(clrff),
    .add_sub(add_sub),
    .ldC(ldC),
    .dec(dec),
    .enf(enf),
    .q0(q0),
    .q1(q1),
    .eqz(eqz),
    .data_out(data_out)
);

controller c (
    .clk(clk),
    .rst(rst),
    .q0(q0),
    .q1(q1),
    .eqz(eqz),
    .start(start),
    .ldA(ldA),
    .clrA(clrA),
    .sftA(sftA),
    .ldQ(ldQ),
    .clrQ(clrQ),
    .sftQ(sftQ),
    .ldM(ldM),
    .clrff(clrff),
    .add_sub(add_sub),
    .ldC(ldC),
    .dec(dec),
    .enf(enf),
    .done(done)
);

endmodule

module controller (
    input  clk, rst,
    input  q0, q1, eqz, start,
    output reg ldA, clrA, sftA,
    output reg ldQ, clrQ, sftQ,
    output reg ldM, clrff,
    output reg add_sub,
    output reg ldC,
    output reg dec,
    output reg enf,
    output reg done
);

    localparam S0 = 3'b000,
               S1 = 3'b001,
               S2 = 3'b010,
               S3 = 3'b011,
               S4 = 3'b100,
               S5 = 3'b101,
               S6 = 3'b110;

    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        ldA     = 1'b0;
        clrA    = 1'b0;
        sftA    = 1'b0;

        ldQ     = 1'b0;
        clrQ    = 1'b0;
        sftQ    = 1'b0;

        ldM     = 1'b0;
        clrff   = 1'b0;

        add_sub = 1'b0;
        ldC     = 1'b0;
        dec     = 1'b0;
        enf     = 1'b0;
        done    = 1'b0;

        case (state)
            S0: begin
                if (start)
                    next_state = S1;
            end

            S1: begin
                next_state = S2;
                clrA  = 1'b1;
                clrff = 1'b1;
                ldC   = 1'b1;
                ldM   = 1'b1;
                ldQ   = 1'b1;
            end

            S2: begin
                if ({q1, q0} == 2'b01)
                    next_state = S3;
                else if ({q1, q0} == 2'b10)
                    next_state = S4;
                else
                    next_state = S5;
            end

            S3: begin
                next_state = S5;
                ldA     = 1'b1;
                add_sub = 1'b0;
            end

            S4: begin
                next_state = S5;
                ldA     = 1'b1;
                add_sub = 1'b1;
            end

            S5: begin
                if (!eqz)
                    next_state = S2;
                else
                    next_state = S6;

                sftA = 1'b1;
                sftQ = 1'b1;
                dec  = 1'b1;
                enf  = 1'b1;
            end

            S6: begin
                next_state = S0;
                done = 1'b1;
            end

            default: begin
                next_state = S0;
            end
        endcase
    end

endmodule

module datapath (
    input clk, rst,
    input [3:0] a,
    input [3:0] b,
    input sftA, clrA, ldA,
    input sftQ, clrQ, ldQ,
    input ldM, clrff,
    input add_sub,
    input ldC, dec, enf,
    output q0, q1,
    output eqz,
    output [7:0] data_out
);

wire [3:0] M, Q, A;
wire [3:0] alu_out;
wire [3:0] counter;

pipo M_reg(clk, rst, ldM, a, M);
shiftreg Q_reg(clk, rst, sftQ, clrQ, ldQ, A[0], b, Q);
shiftreg A_reg(clk, rst, sftA, clrA, ldA, A[3], alu_out, A);
alu ALU(A, M, add_sub, alu_out);
dff q0_ff(clk, rst, clrff, enf, Q[0], q0);
counter count(clk, rst, ldC, dec, counter);

assign eqz = (counter == 0) ? 1 : 0;
assign data_out = {A, Q};
assign q1 = Q[0];

endmodule

module counter (
    input clk, rst, ld, dec,
    output reg [3:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0000;
        else if(ld)
            data_out <= 4'd3;
        else if(dec)
            data_out <= data_out - 1;
    end
endmodule

module alu (
    input [3:0] a, b,
    input sel,
    output reg [3:0] y
);
    always @(*) begin
        if(sel) y = a - b;
        else    y = a + b;
    end
endmodule

module pipo (
    input clk, rst, ld,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0000;
        else if(ld)
            data_out <= data_in;
    end
endmodule

module shiftreg (
    input clk, rst, sft, clr, ld, s_in,
    input [3:0] data_in,
    output reg [3:0] data_out
);

    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0000;
        else if(clr)
            data_out <= 4'b0000;
        else if(ld)
            data_out <= data_in;
        else if(sft)
            data_out <= {s_in, data_out[3:1]};
    end

endmodule

module dff (
    input clk, rst, clr, en,
    input d,
    output reg q
);
    wire d_in = clr ? 1'b0 : (en ? d : q);
    
    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d_in;
    end
endmodule