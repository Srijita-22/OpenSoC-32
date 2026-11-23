
`timescale 1ns/1ps

module timer_apb #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32
) (
    // Clock and reset
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

    // Timer interrupt output
    output logic                  timer_irq
);

    // Register addresses
    localparam logic [7:0] CTRL_ADDR   = 8'h00;
    localparam logic [7:0] LOAD_ADDR   = 8'h04;
    localparam logic [7:0] VALUE_ADDR  = 8'h08;
    localparam logic [7:0] STATUS_ADDR = 8'h0C;

    // Internal registers
    logic [31:0] ctrl_reg;
    logic [31:0] load_reg;
    logic [31:0] counter_reg;
    logic        irq_pending;

    logic apb_access;

    assign apb_access = psel && penable;

    // Zero-wait APB response
    assign pready = 1'b1;

    // APB error generation
    always @(*) begin
        pslverr = 1'b0;

        if (apb_access && pwrite) begin
            case (paddr[7:0])
                CTRL_ADDR,
                LOAD_ADDR,
                STATUS_ADDR: pslverr = 1'b0;

                VALUE_ADDR: pslverr = 1'b1;

                default: pslverr = 1'b1;
            endcase
        end
        else if (apb_access && !pwrite) begin
            case (paddr[7:0])
                CTRL_ADDR,
                LOAD_ADDR,
                VALUE_ADDR,
                STATUS_ADDR: pslverr = 1'b0;

                default: pslverr = 1'b1;
            endcase
        end
    end

    // APB read-data multiplexer
    always @(*) begin
        prdata = '0;

        if (psel) begin
            case (paddr[7:0])
                CTRL_ADDR:
                    prdata = ctrl_reg;

                LOAD_ADDR:
                    prdata = load_reg;

                VALUE_ADDR:
                    prdata = counter_reg;

                STATUS_ADDR:
                    prdata = {31'b0, irq_pending};

                default:
                    prdata = '0;
            endcase
        end
    end

    // Timer register and counter logic
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            ctrl_reg    <= 32'b0;
            load_reg    <= 32'b0;
            counter_reg <= 32'b0;
            irq_pending <= 1'b0;
            timer_irq   <= 1'b0;
        end
        else begin
            // Interrupt is a one-clock-cycle pulse
            timer_irq <= 1'b0;

            // APB write operation
            if (apb_access && pwrite && !pslverr) begin
                case (paddr[7:0])

                    CTRL_ADDR: begin
                        ctrl_reg <= pwdata & 32'h0000_0003;
                    end

                    LOAD_ADDR: begin
                        load_reg    <= pwdata;
                        counter_reg <= pwdata;
                    end

                    STATUS_ADDR: begin
                        // Write 1 to clear interrupt pending
                        if (pwdata[0])
                            irq_pending <= 1'b0;
                    end

                    default: begin
                        // No operation
                    end
                endcase
            end

            // Countdown operation
            else if (ctrl_reg[0] && counter_reg != 32'b0) begin

                if (counter_reg > 32'd1) begin
                    counter_reg <= counter_reg - 1'b1;
                end
                else begin
                    // Timer expired
                    counter_reg <= load_reg;
                    irq_pending <= 1'b1;

                    // Generate interrupt pulse if enabled
                    if (ctrl_reg[1])
                        timer_irq <= 1'b1;
                end
            end
        end
    end

endmodule
