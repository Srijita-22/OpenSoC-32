
module gpio_apb #(
    parameter int GPIO_WIDTH = 8,
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32
) (
    // APB interface
    input  logic                  pclk,
    input  logic                  presetn,
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr,

    // GPIO interface
    input  logic [GPIO_WIDTH-1:0] gpio_in,
    output logic [GPIO_WIDTH-1:0] gpio_out,
    output logic [GPIO_WIDTH-1:0] gpio_oe
);

    // Register addresses
    localparam logic [ADDR_WIDTH-1:0] ADDR_DIR = 'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_OUT = 'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_IN  = 'h08;

    // Internal registers
    logic [GPIO_WIDTH-1:0] gpio_dir;
    logic [GPIO_WIDTH-1:0] gpio_out_reg;

    // APB access condition
    logic apb_access;

    assign apb_access = psel && penable;

    // Zero-wait-state APB slave
    assign pready = 1'b1;

    // GPIO output connections
    assign gpio_out = gpio_out_reg;
    assign gpio_oe  = gpio_dir;

    // Error generation
        always @(*) begin
        pslverr = 1'b0;

        if (apb_access) begin
            case (paddr)

                ADDR_DIR, ADDR_OUT: begin
                    // Upper data bits must be zero for writes
                    if (pwrite &&
                        (|pwdata[DATA_WIDTH-1:GPIO_WIDTH])) begin
                        pslverr = 1'b1;
                    end
                end

                ADDR_IN: begin
                    // Input register is read-only
                    if (pwrite) begin
                        pslverr = 1'b1;
                    end
                end

                default: begin
                    // Invalid address
                    pslverr = 1'b1;
                end

            endcase
        end
    end

    // APB write logic
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            gpio_dir     <= '0;
            gpio_out_reg <= '0;
        end
        else if (apb_access && pready && pwrite && !pslverr) begin
            case (paddr)

                ADDR_DIR:
                    gpio_dir <= pwdata[GPIO_WIDTH-1:0];

                ADDR_OUT:
                    gpio_out_reg <= pwdata[GPIO_WIDTH-1:0];

                default: begin
                    // No operation
                end

            endcase
        end
    end

    // APB read logic
    always @(*) begin
        prdata = '0;

        if (apb_access && !pwrite) begin
            case (paddr)

                ADDR_DIR:
                    prdata[GPIO_WIDTH-1:0] = gpio_dir;

                ADDR_OUT:
                    prdata[GPIO_WIDTH-1:0] = gpio_out_reg;

                ADDR_IN:
                    prdata[GPIO_WIDTH-1:0] = gpio_in;

                default:
                    prdata = '0;

            endcase
        end
    end

endmodule

