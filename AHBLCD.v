module AHBLCD (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire [31:0] HWDATA,
    input  wire        HWRITE,
    input  wire        HSEL,
    input  wire        HREADY,
    output wire        HREADYOUT,
    output wire [31:0] HRDATA,
    output reg         LCD_RS,
    output reg         LCD_RW,
    output reg         LCD_E,
    output reg [3:0]   LCD_DB
);

    localparam [7:0] CMD_ADDR  = 8'h00;
    localparam [7:0] DATA_ADDR = 8'h04;

    reg [31:0] HADDR_reg;
    reg [1:0]  HTRANS_reg;
    reg        HWRITE_reg;
    reg        HSEL_reg;

    always @(posedge HCLK) begin
        if (HREADY) begin
            HADDR_reg  <= HADDR;
            HTRANS_reg <= HTRANS;
            HWRITE_reg <= HWRITE;
            HSEL_reg   <= HSEL;
        end
    end

    assign HREADYOUT = 1'b1;
    assign HRDATA    = 32'h0;

    reg [7:0] lcd_byte;
    reg       lcd_is_data;

    reg [3:0] state;
    localparam S_IDLE       = 4'd0;
    localparam S_SETUP      = 4'd1;
    localparam S_LOAD_HIGH  = 4'd2;
    localparam S_EH_HIGH    = 4'd3;
    localparam S_EL_HIGH    = 4'd4;
    localparam S_LOAD_LOW   = 4'd5;
    localparam S_EH_LOW     = 4'd6;
    localparam S_EL_LOW     = 4'd7;

    reg [7:0] clk_cnt;
    wire      tick;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) clk_cnt <= 8'd0;
        else if (state != S_IDLE) clk_cnt <= clk_cnt + 8'd1;
        else clk_cnt <= 8'd0;
    end

    assign tick = (clk_cnt == 8'd50);

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state       <= S_IDLE;
            LCD_RS      <= 1'b0;
            LCD_RW      <= 1'b0;
            LCD_E       <= 1'b0;
            LCD_DB      <= 4'h0;
            lcd_byte    <= 8'h00;
            lcd_is_data <= 1'b0;
        end else begin
            if (HSEL_reg && HWRITE_reg && HTRANS_reg[1] && (state == S_IDLE)) begin
                case (HADDR_reg[7:0])
                    CMD_ADDR: begin
                        lcd_byte    <= HWDATA[7:0];
                        lcd_is_data <= 1'b0;
                        state       <= S_SETUP;
                    end
                    DATA_ADDR: begin
                        lcd_byte    <= HWDATA[7:0];
                        lcd_is_data <= 1'b1;
                        state       <= S_SETUP;
                    end
                    default: begin
                        state <= S_IDLE;
                    end
                endcase
            end else if (state != S_IDLE && tick) begin
                case (state)
                    S_SETUP: begin
                        LCD_RS <= lcd_is_data;
                        LCD_RW <= 1'b0;
                        state  <= S_LOAD_HIGH;
                    end
                    S_LOAD_HIGH: begin
                        LCD_DB <= lcd_byte[7:4];
                        state  <= S_EH_HIGH;
                    end
                    S_EH_HIGH: begin
                        LCD_E <= 1'b1;
                        state <= S_EL_HIGH;
                    end
                    S_EL_HIGH: begin
                        LCD_E <= 1'b0;
                        state <= S_LOAD_LOW;
                    end
                    S_LOAD_LOW: begin
                        LCD_DB <= lcd_byte[3:0];
                        state  <= S_EH_LOW;
                    end
                    S_EH_LOW: begin
                        LCD_E <= 1'b1;
                        state <= S_EL_LOW;
                    end
                    S_EL_LOW: begin
                        LCD_E <= 1'b0;
                        state <= S_IDLE;
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule
