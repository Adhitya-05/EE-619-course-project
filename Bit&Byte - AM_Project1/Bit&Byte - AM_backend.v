//declaring module and the input and output ports
module backend( i_resetbAll,
		i_clk,
		i_sclk,
		i_sdin,
		i_vco_clk,
		o_ready,
		o_resetb1,
		o_gainA1,
		o_resetb2,
		o_gainA2,
		o_resetbvco);

input i_resetbAll, i_clk, i_sclk, i_sdin, i_vco_clk;
output reg o_ready, o_resetb1, o_resetb2, o_resetbvco;
output reg [1:0] o_gainA1;
output reg [2:0] o_gainA2;

reg present_sclk; //storing the current value of i_sclk
reg previous_sclk; //storing the previous value of i_Sclk to find kind of edge
reg risingedge_sclk; //to store if its a positive edge or negative edge in i_sclk
reg [4:0]wait_counter; //to count the cycles whenever required
reg [1:0]state; //declaring number of states in the FSM for the case block
reg [2:0]bit_counter; //to count number of bits we got from i_sdin
reg [4:0]data; //to store the bits coming from i_sdin

always@(posedge(i_clk) or negedge(i_resetbAll)) //to trigger based on i_clk and i_resetbAll
begin
    if(!i_resetbAll) //To reset everything whenever neg edge of i_resetbAll appears
    begin
        o_resetb1 <= 0;
        o_resetb2 <= 0;
        o_resetbvco <= 0;
        o_ready <= 0;
        o_gainA1 <= 0;
        o_gainA2 <= 0;
        present_sclk <= 0;
        previous_sclk <= 0;
        risingedge_sclk <= 0;
        wait_counter <= 0;
        state <= 0;
        bit_counter <= 0;
        data <= 0;
    end
    else
    begin
        //storing the data in the falling edge giving time for the data to settle which came at rising edge
        present_sclk <= i_sclk; //storing the present i_sclk value
        previous_sclk <= present_sclk; //pushing the present_sclk to previous_sclk in the next cycle
        risingedge_sclk <= (present_sclk == 0 && previous_sclk == 1); //storing the edge in i_sclk
        case(state) //declaring the states based on wait_counter and bit_counter               
        1:begin //state to wait for 2 cycles when bit_counter reaches 5
              if(wait_counter == 2)
	      begin
                  o_resetbvco <= 1;
                  wait_counter <= wait_counter + 1;
                  state <= 2;
              end
              else
              begin
                  wait_counter <= wait_counter + 1;
              end
          end  
        2:begin //state to wait for 10 cycles after o_resetbvco is set to 1
              if(wait_counter == 12)
              begin
                  o_resetb1 <= 1;
                  o_resetb2 <= 1;
                  wait_counter <= wait_counter + 1;
                  state <= 3;
              end
              else
              begin
                  wait_counter <= wait_counter + 1;
              end
          end   
        3:begin //state to wait for 10 cycles after o_resetb1 and o_resetb2 are set to 1
              if(wait_counter == 22)
              begin
                  o_ready <= 1;
              end
              else
              begin
                  wait_counter <= wait_counter + 1;
              end
          end
        default:begin //initial state to enter which receiving data i_sdin based on i_sclk
                    if(risingedge_sclk)
                    begin
                        data[bit_counter] <= i_sdin;
                        bit_counter <= bit_counter + 1;
                    end
                    if(bit_counter == 5) //If bit counter = 5 assign the gains to the amplifiers
                    begin
                        o_gainA1 <= data[1:0];
                        o_gainA2 <= data[4:2];
                        wait_counter <= wait_counter + 1;
                        state <= 1;
                    end
                end
        endcase
    end
end


endmodule

