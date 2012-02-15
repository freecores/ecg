`include "inc.v"

/* add two points on the elliptic curve $y^2=x^3-x+1$ over a Galois field GF(3^M)
 * whose irreducible polynomial is $x^97 + x^12 + 2$. */

/* $P3(x3,y3) == P1 + P2$ for any points $P1(x1,y1),P2(x2,y2)$ */
module point_add(clk, reset, x1, y1, zero1, x2, y2, zero2, done, x3, y3, zero3);
    input clk, reset;
    input [`WIDTH:0] x1, y1, x2, y2;
    input zero1; // asserted if P1 == 0
    input zero2; // asserted if P2 == 0
    output reg done;
    output reg [`WIDTH:0] x3, y3;
    output reg zero3; // asserted if P3 == 0
    wire [`WIDTH:0] x3a, x3b, y3a, y3b;
    wire zero3a,
         use1,  // asserted if $ins1$ do work
         done2; // asserted if $ins2$ finished
    
    assign use1 = zero1 | zero2;
    
    func9
        ins9 (x1, y1, zero1, x2, y2, zero2, x3a, y3a, zero3a);
    func10
        ins10 (clk, reset, x1, y1, x2, y2, done2, x3b, y3b);
        
    always @ (posedge clk)
        zero3 <= use1 & zero3a;
    
    always @ (posedge clk)
        if (reset)
            done <= 0;
        else
            done <= use1 ? 1 : done2;
    
    always @ (posedge clk)
        if (reset)
          begin 
            x3 <= 0; y3 <= 0; 
          end
        else
          begin 
            x3 <= use1 ? x3a : x3b;
            y3 <= use1 ? y3a : y3b;
          end
endmodule

/* $P1$ and/or $P2$ is the infinite point */
module func9(x1, y1, zero1, x2, y2, zero2, x3, y3, zero3);
    input [`WIDTH:0] x1, y1, x2, y2;
    input zero1; // asserted if P1 == 0
    input zero2; // asserted if P2 == 0
    output [`WIDTH:0] x3, y3;
    output zero3; // asserted if P3 == 0
    
    assign zero3 = zero1 & zero2;
    
    genvar i;
    generate
        for (i=0; i<=`WIDTH; i=i+1)
          begin:label
            assign x3[i] = (x1[i] & zero1) | (x2[i] & zero2);
            assign y3[i] = (y1[i] & zero1) | (y2[i] & zero2);
          end
    endgenerate
endmodule

/* $P1$ or $P2$ is not the infinite point */
module func10(clk, reset, x1, y1, x2, y2, done, x3, y3);
    input clk, reset;
    input [`WIDTH:0] x1, y1, x2, y2;
    output done;
    output [`WIDTH:0] x3, y3;
    
    assign x3 = x1;
    assign y3 = y1;
    assign done = 1;
endmodule
