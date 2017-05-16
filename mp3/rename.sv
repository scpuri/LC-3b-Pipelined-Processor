module rename
(
    input clk,
    input enable,
    input lc3b_reg dest_in,
    input lc3b_reg sr1_in,
    input lc3b_reg sr2_in,
    input new_free,
    input phys_reg new_free_reg,
    output phys_reg dest_out,
    output phys_reg sr1_out,
    output phys_reg sr2_out,
    output logic no_free_stall
);
    // assuming 32 physical registers
    phys_reg RAT [7:0]; // register alias table
    phys_reg free [31:0]; // free reg list same size as physical reg file
    phys_reg free_head, free_tail; 

    initial
    begin
        // alias each register to same numbered phys register
        for (int i = 0; i < $size(RAT); i++)
        begin
            RAT[i] = i; 
        end

        // put every phys register into free list
        for (int i = 0; i < $size(free); i++)
        begin
            free[i] = i;
        end

        free_head = 1;
        free_tail = 0;
    end

    always_ff @(posedge clk)
    begin
        if(enable)
        begin
            sr1_out <= RAT[sr1_in];
            sr2_out <= RAT[sr2_in];

            RAT[dest_in] <= free[free_head];
            dest_out <= free[free_head];
            free_head <= free_head + 1;
        end

        if(new_free)
        begin
            free[free_tail] <= new_free_reg;
            free_tail <= free_tail + 1;
        end

        if(free_tail == free_head)
            no_free_stall <= 1;
        else
            no_free_stall <= 0;
    end

endmodule : rename

