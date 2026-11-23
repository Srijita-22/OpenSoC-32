
module uart_apb #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 9600,
    parameter integer ADDR_WIDTH  = 8,
    parameter integer DATA_WIDTH  = 32
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

    // UART serial interface
    output logic                  uart_tx,
    input  logic                  uart_rx
);

    // ------------------------------------------------
    // Register Map
    // ------------------------------------------------

    localparam logic [7:0] ADDR_DATA     = 8'h00;
    localparam logic [7:0] ADDR_STATUS   = 8'h04;
    localparam logic [7:0] ADDR_BAUD_DIV = 8'h08;

    localparam logic [31:0] DEFAULT_BAUD_DIV =
                                      CLK_FREQ_HZ / BAUD_RATE;

    // ------------------------------------------------
    // TX State Machine
    // ------------------------------------------------

    typedef enum logic [1:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_STOP
    } tx_state_t;

    tx_state_t tx_state;

    logic [7:0] tx_shift;
    logic [3:0] tx_bit_index;

    logic [31:0] tx_baud_count;

    logic tx_busy;
    logic tx_done;
    logic tx_start;

    // ------------------------------------------------
    // RX State Machine
    // ------------------------------------------------

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    rx_state_t rx_state;

    logic [7:0] rx_shift;
    logic [7:0] rx_data_reg;

    logic [3:0] rx_bit_index;

    logic [31:0] rx_baud_count;

    logic rx_valid;
    logic rx_frame_error;

    // Two-flop synchronizer for asynchronous RX input
    logic rx_meta;
    logic rx_sync;
    logic rx_previous;

    // ------------------------------------------------
    // Common Registers
    // ------------------------------------------------

    logic [31:0] baud_div_reg;
    logic apb_access;

    assign apb_access = psel && penable;
    assign tx_busy = (tx_state != TX_IDLE);

    assign pready = 1'b1;

    // ------------------------------------------------
    // APB Error Detection
    // ------------------------------------------------

    always @(*) begin

        pslverr = 1'b0;

        if (apb_access) begin

            case (paddr)

                ADDR_DATA: begin

                    if (pwrite) begin

                        if (tx_busy)
                            pslverr = 1'b1;

                        if (|pwdata[DATA_WIDTH-1:8])
                            pslverr = 1'b1;

                    end

                end

                ADDR_STATUS: begin

                    if (pwrite)
                        pslverr = 1'b1;

                end

                ADDR_BAUD_DIV: begin

                    if (pwrite && (pwdata < 32'd4))
                        pslverr = 1'b1;

                end

                default: pslverr = 1'b1;

            endcase

        end

    end

    // ------------------------------------------------
    // APB TX Start
    // ------------------------------------------------

    assign tx_start = apb_access &&
                      pwrite &&
                      (paddr == ADDR_DATA) &&
                      !tx_busy &&
                      !pslverr;

    // ------------------------------------------------
    // APB Read Data
    // ------------------------------------------------

    always @(*) begin

        prdata = '0;

        if (apb_access && !pwrite) begin

            case (paddr)

                ADDR_DATA:
                    prdata[7:0] = rx_data_reg;

                ADDR_STATUS: begin

                    prdata[0] = tx_busy;
                    prdata[1] = tx_done;
                    prdata[2] = rx_valid;
                    prdata[3] = rx_frame_error;

                end

                ADDR_BAUD_DIV:
                    prdata = baud_div_reg;

                default:
                    prdata = '0;

            endcase

        end

    end

    // ------------------------------------------------
    // Baud Divider Register
    // ------------------------------------------------

    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin

            baud_div_reg <= DEFAULT_BAUD_DIV;

        end

        else if (apb_access &&
                 pwrite &&
                 (paddr == ADDR_BAUD_DIV) &&
                 !pslverr) begin

            baud_div_reg <= pwdata;

        end

    end

    // ------------------------------------------------
    // UART TX State Machine
    // ------------------------------------------------

    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin

            tx_state      <= TX_IDLE;
            tx_shift      <= 8'd0;
            tx_bit_index  <= 4'd0;
            tx_baud_count <= 32'd0;
            tx_done       <= 1'b0;

        end

        else begin

            case (tx_state)

                TX_IDLE: begin

                    tx_baud_count <= 32'd0;

                    if (tx_start) begin

                        tx_shift      <= pwdata[7:0];
                        tx_bit_index  <= 4'd0;
                        tx_state      <= TX_START;
                        tx_done       <= 1'b0;

                    end

                end

                TX_START: begin

                    if (tx_baud_count == baud_div_reg - 1'b1) begin

                        tx_baud_count <= 32'd0;
                        tx_state      <= TX_DATA;

                    end

                    else begin

                        tx_baud_count <= tx_baud_count + 1'b1;

                    end

                end

                TX_DATA: begin

                    if (tx_baud_count == baud_div_reg - 1'b1) begin

                        tx_baud_count <= 32'd0;
                        tx_shift      <= tx_shift >> 1;

                        if (tx_bit_index == 4'd7) begin

                            tx_state <= TX_STOP;

                        end

                        else begin

                            tx_bit_index <= tx_bit_index + 1'b1;

                        end

                    end

                    else begin

                        tx_baud_count <= tx_baud_count + 1'b1;

                    end

                end

                TX_STOP: begin

                    if (tx_baud_count == baud_div_reg - 1'b1) begin

                        tx_baud_count <= 32'd0;
                        tx_state      <= TX_IDLE;
                        tx_done       <= 1'b1;

                    end

                    else begin

                        tx_baud_count <= tx_baud_count + 1'b1;

                    end

                end

                default: tx_state <= TX_IDLE;

            endcase

        end

    end

    // ------------------------------------------------
    // UART TX Output
    // ------------------------------------------------

    always @(*) begin

        case (tx_state)

            TX_IDLE:  uart_tx = 1'b1;
            TX_START: uart_tx = 1'b0;
            TX_DATA:  uart_tx = tx_shift[0];
            TX_STOP:  uart_tx = 1'b1;

            default:  uart_tx = 1'b1;

        endcase

    end

    // ------------------------------------------------
    // RX Input Synchronizer
    // ------------------------------------------------

    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin

            rx_meta <= 1'b1;
            rx_sync <= 1'b1;

        end

        else begin

            rx_meta <= uart_rx;
            rx_sync <= rx_meta;

        end

    end

    // ------------------------------------------------
    // UART RX State Machine
    // ------------------------------------------------

    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin

            rx_state       <= RX_IDLE;
            rx_shift       <= 8'd0;
            rx_data_reg    <= 8'd0;
            rx_bit_index   <= 4'd0;
            rx_baud_count  <= 32'd0;

            rx_previous    <= 1'b1;
            rx_valid       <= 1'b0;
            rx_frame_error <= 1'b0;

        end

        else begin

            rx_previous <= rx_sync;

            case (rx_state)

                // ------------------------------------
                // RX IDLE
                // ------------------------------------

                RX_IDLE: begin

                    rx_baud_count <= 32'd0;

                    if (rx_previous && !rx_sync) begin

                        rx_state       <= RX_START;
                        rx_bit_index   <= 4'd0;
                        rx_shift       <= 8'd0;
                        rx_valid       <= 1'b0;
                        rx_frame_error <= 1'b0;

                    end

                end

                // ------------------------------------
                // RX START BIT VALIDATION
                // ------------------------------------

                RX_START: begin

                    if (rx_baud_count >=
                        (baud_div_reg / 2) - 1'b1) begin

                        rx_baud_count <= 32'd0;

                        if (!rx_sync) begin

                            rx_state <= RX_DATA;

                        end

                        else begin

                            // False start bit
                            rx_state <= RX_IDLE;

                        end

                    end

                    else begin

                        rx_baud_count <= rx_baud_count + 1'b1;

                    end

                end

                // ------------------------------------
                // RX DATA BITS
                // ------------------------------------

                RX_DATA: begin

                    if (rx_baud_count == baud_div_reg - 1'b1) begin

                        rx_baud_count <= 32'd0;

                        // Shift incoming bits, LSB first
                        rx_shift <= {rx_sync, rx_shift[7:1]};

                        if (rx_bit_index == 4'd7) begin

                            rx_state <= RX_STOP;

                        end

                        else begin

                            rx_bit_index <= rx_bit_index + 1'b1;

                        end

                    end

                    else begin

                        rx_baud_count <= rx_baud_count + 1'b1;

                    end

                end

                // ------------------------------------
                // RX STOP BIT VALIDATION
                // ------------------------------------

                RX_STOP: begin

                    if (rx_baud_count == baud_div_reg - 1'b1) begin

                        rx_baud_count <= 32'd0;
                        rx_state      <= RX_IDLE;

                        if (rx_sync) begin

                            rx_data_reg <= rx_shift;
                            rx_valid    <= 1'b1;

                        end

                        else begin

                            rx_valid       <= 1'b0;
                            rx_frame_error <= 1'b1;

                        end

                    end

                    else begin

                        rx_baud_count <= rx_baud_count + 1'b1;

                    end

                end

                default: rx_state <= RX_IDLE;

            endcase

            // Reading DATA clears RX valid
            if (apb_access &&
                !pwrite &&
                (paddr == ADDR_DATA)) begin

                rx_valid <= 1'b0;

            end

        end

    end

endmodule
