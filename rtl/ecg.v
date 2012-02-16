`include "inc.v"

/* add two points on the elliptic curve $y^2=x^3-x+1$ over a Galois field GF(3^M)
 * whose irreducible polynomial is $x^97 + x^12 + 2$. */

/* $P3(x3,y3) == P1 + P2$ for any points $P1(x1,y1),P2(x2,y2)$ */
module point_add(clk, reset, x1, y1, zero1, x2, y2, zero2, done, x3, y3, zero3);
    input clk, reset;
    input [`WIDTH:0] x1, y1; // this guy is $P1$
    input zero1; // asserted if P1 == 0
    input [`WIDTH:0] x2, y2; // and this guy is $P2$
    input zero2; // asserted if P2 == 0
    output reg done;
    output reg [`WIDTH:0] x3, y3; // ha ha, this guy is $P3$
    output reg zero3; // asserted if P3 == 0
    wire [`WIDTH:0] x3a, x3b, x3c,
                    y3a, y3b, y3c,
                    ny2;
    wire zero3a,
         use1,  // asserted if $ins9$ did the work
         done10, // asserted if $ins10$ finished
         done11, 
         cond1,
         cond2,
         cond3,
         cond4,
         cond5;
    
    assign use1 = zero1 | zero2;
    assign cond1 = (~use1) && cond2 && cond4; // asserted if $P1 == -P2$
    assign cond2 = (x1 == x2);
    assign cond3 = (y1 == y2);
    assign cond4 = (y1 == ny2);
    assign cond5 = (~use1) && cond2 && cond3; // asserted if $P1 == P2$
    
    f3m_neg 
        ins1 (y2, ny2); // ny2 == -y2
    func9
        ins9 (x1, y1, zero1, x2, y2, zero2, x3a, y3a, zero3a);
    func10
        ins10 (clk, reset, x1, y1, done10, x3b, y3b);
    func11
        ins11 (clk, reset, x1, y1, x2, y2, done11, x3c, y3c);
        
    always @ (posedge clk)
        if (reset)
            zero3 <= 0;
        else
            zero3 <= (use1 & zero3a) | cond1; // if both of $P1$ and $P2$ are inf point, or $P1 == -P2$, then $P3$ is inf point
    
    always @ (posedge clk)
        if (reset)
            done <= 0;
        else
            done <= (use1 | cond1) ? 1 : (cond5 ? done10 : done11);
    
    always @ (posedge clk)
        if (reset)
          begin 
            x3 <= 0; y3 <= 0; 
          end
        else
          begin 
            x3 <= use1 ? x3a : (cond5 ? x3b : x3c);
            y3 <= use1 ? y3a : (cond5 ? y3b : y3c);
          end
endmodule

/* $P3 == P1+P2$ */
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
            assign x3[i] = (x2[i] & zero1) | (x1[i] & zero2);
            assign y3[i] = (y2[i] & zero1) | (y1[i] & zero2);
          end
    endgenerate
endmodule

/* $P3 == P1+P2$ */
/* $P1$ or $P2$ is not the infinite point. $P1 == P2$ */
module func10(clk, reset, x1, y1, done, x3, y3);
    input clk, reset;
    input [`WIDTH:0] x1, y1;
    output reg done;
    output reg [`WIDTH:0] x3, y3;
    wire [`WIDTH:0] v1, v2, v3, v4, v5, v6;
    wire rst2, done1, done2;
    reg [2:0] K;
    
    f3m_inv
        ins1 (clk, reset, y1, v1, done1); // v1 == inv y1
    f3m_mult
        ins2 (clk, rst2, v1, v1, v2, done2); // v2 == v1^2
    f3m_cubic
        ins3 (v1, v3); // v3 == v1^3
    f3m_add
        ins4 (x1, v2, v4), // v4 == x1+v2 == x1 + (inv y1)^2
        ins5 (y1, v3, v5); // v5 == y1+v3 == y1 + (inv y1)^3
    f3m_neg
        ins6 (v5, v6); // v6 == -[y1 + (inv y1)^3]
    func6
        ins7 (clk, reset, done1, rst2);
    
    always @ (posedge clk)
        if (reset)
            K <= 3'b100;
        else if ((K[2]&rst2)|(K[1]&done2)|K[0])
            K <= K >> 1;
            
    always @ (posedge clk)
        if (reset)
          begin
            done <= 0; x3 <= 0; y3 <= 0;
          end
        else if (K[0])
          begin
            done <= 1; x3 <= v4; y3 <= v6;
          end
endmodule

/* $P3 == P1+P2$ */
/* $P1$ or $P2$ is not the infinite point. $P1 != P2, and P1 != -P2$ */
module func11(clk, reset, x1, y1, x2, y2, done, x3, y3);
    input clk, reset;
    input [`WIDTH:0] x1, y1, x2, y2;
    output reg done;
    output reg [`WIDTH:0] x3, y3;
    wire [`WIDTH:0] v1, v2, v3, v4, v5, v6, v7, v8, v9, v10;
    wire rst2, rst3, done1, done2, done3;
    reg [3:0] K;

    f3m_sub
        ins1 (x2, x1, v1), // v1 == x2-x1
        ins2 (y2, y1, v2); // v2 == y2-y1
    f3m_inv
        ins3 (clk, reset, v1, v3, done1); // v3 == inv v1 == inv(x2-x1)
    f3m_mult
        ins4 (clk, rst2, v2, v3, v4, done2), // v4 == v2*v3 == (y2-y1)/(x2-x1)
        ins5 (clk, rst3, v4, v4, v5, done3); // v5 == v4^2
    f3m_cubic
        ins6 (v4, v6); // v6 == v4^3
    f3m_add
        ins7 (x1, x2, v7), // v7 == x1+x2
        ins8 (y1, y2, v8); // v8 == y1+y2
    f3m_sub
        ins9 (v5, v7, v9), // v9 == v5-v7 == v4^2 - (x1+x2)
        ins10 (v8, v6, v10); // v10 == (y1+y2) - v4^3
    func6
        ins11 (clk, reset, done1, rst2),
        ins12 (clk, reset, done2, rst3);

    always @ (posedge clk)
        if (reset)
            K <= 4'b1000;
        else if ((K[3]&rst2)|(K[2]&rst3)|(K[1]&done3)|K[0])
            K <= K >> 1;
            
    always @ (posedge clk)
        if (reset)
          begin
            done <= 0; x3 <= 0; y3 <= 0;
          end
        else if (K[0])
          begin
            done <= 1; x3 <= v9; y3 <= v10;
          end
endmodule
