`timescale 1ns/1ps
module spi_master_apb #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 8
)(
    input  logic                  pclk,
    input  logic                  presetn,

    // APB interface
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,

    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr,

    // SPI interface
    output logic                  spi_sclk,
    output logic                  spi_mosi,
    input  logic                  spi_miso,
    output logic                  spi_cs_n
);

    // APB register map
    localparam logic [7:0] ADDR_DATA   = 8'h00;
    localparam logic [7:0] ADDR_STATUS = 8'h04;
    localparam logic [7:0] ADDR_CLKDIV = 8'h08;

    // 50 MHz / (2 * 25) = 1 MHz SPI clock
    localparam logic [31:0] DEFAULT_CLKDIV = 32'd25;

    typedef enum logic {
        SPI_IDLE,
        SPI_TRANSFER
    } spi_state_t;

    spi_state_t spi_state;

    // Seven remaining TX bits after the first MSB
    logic [6:0] tx_shift;
    logic [7:0] rx_shift;
    logic [7:0] rx_data_reg;

    logic [3:0] bit_count;

    logic [31:0] clkdiv_reg;
    logic [31:0] clk_count;

    logic spi_busy;
    logic spi_done;

    logic apb_access;
    logic spi_start;

    assign apb_access = psel && penable;
    assign spi_busy = (spi_state == SPI_TRANSFER);
    assign pready = 1'b1;

    // APB error detection
    always @(*) begin
        pslverr = 1'b0;

        if (apb_access) begin
            case (paddr)

                ADDR_DATA: begin
                    if (pwrite) begin
                        if (spi_busy)
                            pslverr = 1'b1;

                        if (|pwdata[DATA_WIDTH-1:8])
                            pslverr = 1'b1;
                    end
                end

                ADDR_STATUS: begin
                    if (pwrite)
                        pslverr = 1'b1;
                end

                ADDR_CLKDIV: begin
                    if (pwrite && (pwdata == 32'd0))
                        pslverr = 1'b1;
                end

                default:
                    pslverr = 1'b1;

            endcase
        end
    end

    // SPI transfer start
    assign spi_start = apb_access &&
                       pwrite &&
                       (paddr == ADDR_DATA) &&
                       !spi_busy &&
                       !pslverr;

    // APB read data
    always @(*) begin
        prdata = '0;

        if (apb_access && !pwrite) begin
            case (paddr)

                ADDR_DATA:
                    prdata[7:0] = rx_data_reg;

                ADDR_STATUS: begin
                    prdata[0] = spi_busy;
                    prdata[1] = spi_done;
                end

                ADDR_CLKDIV:
                    prdata = clkdiv_reg;

                default:
                    prdata = '0;

            endcase
        end
    end

    // Clock divider register
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            clkdiv_reg <= DEFAULT_CLKDIV;
        end
        else if (apb_access &&
                 pwrite &&
                 (paddr == ADDR_CLKDIV) &&
                 !pslverr &&
                 !spi_busy) begin
            clkdiv_reg <= pwdata;
        end
    end

    // SPI Mode 0: CPOL = 0, CPHA = 0
    // MSB first
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            spi_state   <= SPI_IDLE;

            spi_sclk    <= 1'b0;
            spi_mosi    <= 1'b0;
            spi_cs_n    <= 1'b1;

            tx_shift    <= 7'd0;
            rx_shift    <= 8'd0;
            rx_data_reg <= 8'd0;

            bit_count   <= 4'd0;
            clk_count   <= 32'd0;

            spi_done    <= 1'b0;
        end
        else begin
            case (spi_state)

                SPI_IDLE: begin
                    spi_sclk  <= 1'b0;
                    spi_cs_n  <= 1'b1;
                    clk_count <= 32'd0;

                    if (spi_start) begin
                        // Send first bit directly
                        spi_mosi <= pwdata[7];

                        // Store remaining seven bits
                        tx_shift <= pwdata[6:0];

                        rx_shift <= 8'd0;
                        bit_count <= 4'd0;

                        spi_cs_n <= 1'b0;
                        spi_done <= 1'b0;

                        spi_state <= SPI_TRANSFER;
                    end
                end

                SPI_TRANSFER: begin
                    if (clk_count == clkdiv_reg - 1'b1) begin
                        clk_count <= 32'd0;

                        // Rising edge: sample MISO
                        if (spi_sclk == 1'b0) begin
                            spi_sclk <= 1'b1;

                            rx_shift <= {
                                rx_shift[6:0],
                                spi_miso
                            };
                        end

                        // Falling edge: update MOSI
                        else begin
                            spi_sclk <= 1'b0;

                            if (bit_count == 4'd7) begin
                                rx_data_reg <= rx_shift;

                                spi_state <= SPI_IDLE;
                                spi_cs_n  <= 1'b1;
                                spi_done  <= 1'b1;
                                spi_mosi  <= 1'b0;
                            end
                            else begin
                                bit_count <= bit_count + 1'b1;

                                spi_mosi <= tx_shift[6];

                                tx_shift <= {
                                    tx_shift[5:0],
                                    1'b0
                                };
                            end
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    spi_state <= SPI_IDLE;
                end

            endcase
        end
    end

endmodule
