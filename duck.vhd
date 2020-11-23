--Duck in the Hudson based off of helicopter game built by Tom Dale,Davis Mariotti, Andrew Peacock
--
--includes: calculates position of duck and walls, communicates with users button, vga_sync, and font_unit
--manages collisions, timer, reset, gameOver, and freeze

library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity duck_top is
    Port (
        clk, reset: in std_logic;
        hsync, vsync: out std_logic;
        red: out std_logic_vector(3 downto 0);
        green: out std_logic_vector(3 downto 0);
        blue: out std_logic_vector(3 downto 0);
        btn: in std_logic;
        playAgain, freeze: in std_logic
    );
end duck_top;

architecture duck_top of duck_top is

    constant TVU: integer := 7;  -- Terminal velocity up
    constant TVD: integer:= 7;   -- Terminal velocity down
   
    type wall_data is array(0 to 31) of integer range 0 to 240;

    signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
    signal general_up: std_logic := '0'; -- walls will genrally move up the screen if true
    signal wall_width: integer := 400;
    signal general_width_up: std_logic := '0';
    signal video_on, pixel_tick: std_logic;
    signal red_reg, red_next: std_logic_vector(3 downto 0) := (others => '0');
    signal green_reg, green_next: std_logic_vector(3 downto 0) := (others => '0');
    signal blue_reg, blue_next: std_logic_vector(3 downto 0) := (others => '0'); 
    signal x : integer := 115; --constant duck x position
    signal y : integer := 150; --initial duck y position
    signal velocity_y : integer := 0;
    signal duck_top, duck_bottom, duck_left, duck_right : integer := 0; 
    signal update_pos, update_vel, update_walls : std_logic := '0'; 
    signal walls: wall_data;
    signal game_over_pause: std_logic := '0'; --true when game is over. press reset to play again
    signal start_pause: std_logic := '1';
    signal row_offset: integer := 0;
    signal column_offset: integer := 0;
    signal number: integer := 0;
    signal score: integer range 0 to 999 := 0;
    signal score1: integer range 0 to 9 := 0;--single character portions of total score
    signal score2: integer range 0 to 9 := 0;
    signal score3: integer range 0 to 9 := 0;
    signal score4: integer range 0 to 9 := 0;
    signal number_return_data: std_logic;
begin
   -- instantiate VGA sync circuit
vga_sync_unit: entity work.vga_sync
    port map(clk=>clk, btn=> btn,playAgain => playAgain, reset=>reset, hsync=>hsync,
            vsync=>vsync, video_on=>video_on,
            pixel_x=>pixel_x, pixel_y=>pixel_y,
            p_tick=>pixel_tick);
--font_unit: entity work.font_rom
  --port map(data=>number_return_data, column_offset=>column_offset, number=>number, row_offset=>row_offset);
                       
    duck_left <= x;--duck doesnt move in x direction, only up and down
    duck_right <= x + 23;            
    duck_top <= y;
    duck_bottom <= y + 16;
    
    -- process to generate update position, velocity, walls, and increment score
    process ( video_on )
        variable counter : integer := 0;
        variable vel_counter : integer := 0;
        variable wall_counter: integer := 0;
        variable score_counter: integer := 0;
        variable game_over_counter: integer := 0;
    begin
        if game_over_pause = '1' then
            score <= 0;
        elsif (rising_edge(video_on) and freeze = '0') and game_over_pause = '0' then
            if start_pause = '0' then
                counter := counter + 1;
                vel_counter := vel_counter + 1;
                wall_counter := wall_counter + 1;
                score_counter := score_counter + 1;
                
                if counter > 1000 then --update postion every 2000 clocks
                    counter := 0;
                    update_pos <= '1';
                else
                    update_pos <= '0';
                end if;
                if vel_counter > 2000 then --update velocity every 2000 clocks
                    vel_counter := 0;
                    update_vel <= '1';
                else
                    update_vel <= '0';
                end if;
                if wall_counter > 10000 then --walls increment every 10000 clocks
                    wall_counter := 0;
                    update_walls <= '1';
                else
                    update_walls <= '0';
                end if;
                if score_counter > 5000 then --scores incrment every 5000 clocks
                    score <= score + 1;
                    score1 <= score mod 10;
                    score2 <= (score / 10) mod 10;
                    score3 <= (score / 100) mod 10;
                    score4 <= (score / 1000) mod 10;
                    score_counter := 0;
                end if;
            elsif btn = '1' then
                start_pause <= '0';
            end if;
         end if;
    end process;

    -- compute the duck's position
    process (playAgain, update_pos, video_on)
    begin
        if game_over_pause = '1' and playAgain = '1' then
            game_over_pause <= '0';
        elsif game_over_pause = '1' and playAgain = '0' then
        elsif rising_edge(update_pos) then
            y <= y + velocity_y;
            if (duck_bottom >= wall_width + walls(6)) then -- calculate collision with walls
                y <= walls(7) + 50;
                game_over_pause <= '1';
            elsif (duck_top <= walls(6))then
                y <= walls(7) + 50;
                game_over_pause <= '1';
            end if;
        end if; 
    end process;
    

    -- compute the duck's velocity
    process (update_vel)
    begin
        if rising_edge(update_pos) then
            if btn = '1' then
                if velocity_y > -TVU then
                    velocity_y <= velocity_y - 1;
                end if;
            else
                if velocity_y < TVD then
                    velocity_y <= velocity_y + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Shift walls and compute psuedo-psuedo-random new wall
    process (update_walls)
    begin
        if rising_edge(update_walls)  then
            if (wall_width < 100) then--randomly change difficulty by changing wall_width
                wall_width <= 105;
                general_width_up <= '1';
            elsif (wall_width > 300) then
                wall_width <= 295;
                general_width_up <= '0';
            elsif (general_width_up = '1') then 
                wall_width <= wall_width + 1;
            else
                wall_width <= wall_width - 1;
            end if;
            for i in 1 to 31 loop
                walls(i - 1) <= walls(i);
            end loop;
            --calculate random change in far right wall
            if(walls(31) < 31) then 
                general_up <= '1';
                walls(31) <= 35;
            elsif (walls(31) >= 230) then
                general_up <= '0';
                 walls(31) <= 225;
            elsif(general_up = '1')then --should walls generally move up or down
                 walls(31) <= walls(31)+ ((walls(2) * walls(19) + walls(25) * 13) mod 40) -10; --add value between -10 and 30
                 if((duck_top + walls(2))*13 mod 10 = 1) then--10 % of the time change general wall direction
                    general_up <= '0';
                    end if;
            else
                walls(31) <= walls(31)- ((walls(2) * walls(19) + walls(25) * 13) mod 40) +10; --add value between -30 and 10
                if((duck_top + walls(2))*13 mod 10 = 1) then --10 % of the time change general wall direction
                    general_up <= '1';
                    end if;
           end if;
        end if;
    end process;      
    
    -- process to generate next colors     
    process (pixel_x, pixel_y)        
    type duck_sprite is array (0 to 55) of std_logic_vector(0 to 70);
    
    variable duck_data : duck_sprite := (-- helicopter bits
      
        "00000000000000000000000000000000000000000000111111110000000000000000000",
        "00000000000000000000000000000000000000000110000000001100000000000000000",
        "00000000000000000000000000000000000000001000000000000011000000000000000",
        "00000000000000000000000000010000000000010000000000000001100000000000000",
        "00000000000000000000000001111111000000000000000000000000110000000000000",
        "00000000000000000000000110110111000110000000000000000000011000000000000",
        "00000000000000000000001000000011100111001000000000000000001000000000000",
        "00000000000000000000010000000001101001011000000011000000011100000000000",
        "00000000000000000000100000000001110011010000001111000000011000000000000",
        "00000000000000000001000000000001011111000000010001000000001000000000000",
        "00000000000000000001000000000011001111110000101000100000001000000000000",
        "00000000000000000010000000000001000111111111101100100000011000000000000",
        "00000000000000000110000000001111100000111111111100000000011100000000000",
        "00000000000000000100000000011111111000000000111001000000010000000000000",
        "00000000000000000100000000011111001100000000011111100000010000000000000",
        "00000000000000001000000010011111110110000000000001110001110000111000000",
        "00000000000000010000000001011001011001000000011111011011100011001100000",
        "00000000000000100000000001001111111100000000111000101111101000000100000",
        "00000000000001000000000011000000011010000011100001101110010000000010000",
        "00000000000001000000000110000000001101111111001110011110010010000001000",
        "00000000000001000000000110000000000110111111111000111010011100000000100",
        "00000000000000111000000100000000000001111111111111100011011100010000010",
        "00000000000000011100001100000111111100011100011100000011100110100000001",
        "00000000000000000010111000011100000011000000000000000011110011000000001",
        "00000000000000000001111000110000000001100000000000000011010001001110010",
        "00000000000000000000010001000000000000110000000000000010001001100010010",
        "00000000000000000000100010000000000000010000000000000010001100100010100",
        "00000000000011000011100100010000000000111100000000000110000011110100100",
        "00000000000011111110001000100000000001111110000000111111000011111000100",
        "00000000001110000000000001000000000111001110000111100011000001000000100",
        "00000000000111000000000011000000001100111111111100011101100000000000100",
        "00000000000111000000000010000000011001111111111111111111100000000000100",
        "00000000001101000000000110000000110111111111111111111111100000000000100",
        "00000000001110000000000100110001101111111111111111111111111110000001100",
        "00000000000100000000000111100011011111111111111111111110000010000001000",
        "00000000000100000000001111111110111111111111111111111111110001110001000",
        "00000000000010000000001111111101111111111111111111111111111100111111000",
        "00000000000011000000000100011011111111111111111111111111111110011110000",
        "00000000000001100000001110110111111111111111111111111111111110000000000",
        "00000000000001110000001101101111111111111111111111111111111110000000000",
        "00000000000011111000011111011111111111111111111111111111111000000000000",
        "00000000000110100111010110011111111111111111111111111111100000000000000",
        "00000000001100100011110100111111111111111111111111111100000000000000000",
        "00000000011000011000101101111111111111111111111111100000000000000000000",
        "00000000110110011111111011111111111111111111111100000000000000000000000",
        "00000001000110011011110111111111111111111111100000000000000000000000000",
        "00000110000111111001100111111111111111111000000000000000000000000000000",
        "00001100000101110001101111111111111111000000000000000000000000000000000",
        "00010000000101100011011111111111110000000000000000000000000000000000000",
        "01100001001001100011111111111111100000000000000000000000000000000000000",
        "11000010001000100010111111111111000000000000000000000000000000000000000",
        "01100110010000100111111111100110000000000000000000000000000000000000000",
        "00111100010000011111111110011000000000000000000000000000000000000000000",
        "00011100110000001111111001110000000000000000000000000000000000000000000",
        "00011110100000000111111110000000000000000000000000000000000000000000000",
        "00000001100000000110000000000000000000000000000000000000000000000000000"
    );
    variable pos_in_duck_x: integer := to_integer(signed(pixel_x)) - duck_left;
    variable pos_in_duck_y: integer := to_integer(signed(pixel_y)) - duck_top;
    variable draw_pixel: std_logic := '0';
    begin
        draw_pixel := '0';
        if (unsigned(pixel_x) >= duck_left) and (unsigned(pixel_x) < duck_right) and
        (unsigned(pixel_y) >= duck_top) and (unsigned(pixel_y) < (duck_bottom)) and
        (duck_data(pos_in_duck_y)(pos_in_duck_x) = '1') then
            red_next <= "1111"; -- yellow duck
            green_next <= "1111";
            blue_next <= "0000";
        else    
            -- background color blue
            red_next <= "0000";
            green_next <= "0000";
            blue_next <= "1111";
        end if;
        -- calculate where to draw walls
        for I in 0 to 31 loop
            if ((unsigned(pixel_x) < 23*I)and (unsigned(pixel_x) >= 23*(I-1))) and ((unsigned(pixel_y) < walls(I) or (unsigned(pixel_y) > wall_width +  walls(I)))) then
                red_next <= "0000";
                green_next <= "1111";
                blue_next <= "0000";
            end if;
        end loop;
        --draw scores to screen, must be separated by individual digits
        if (unsigned(pixel_x) >= 520) and (unsigned(pixel_y) > 456) then
            row_offset <= to_integer(signed(pixel_y)) - 460;
            if (unsigned(pixel_x) >= 627) and (unsigned(pixel_x) < 635) and -- Score far right
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 627;
                number <= score1;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 617) and (unsigned(pixel_x) < 625) and -- Score second right
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 617;
                number <= score2;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 607) and (unsigned(pixel_x) < 615) and -- Score third right
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 607;
                number <= score3;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 597) and (unsigned(pixel_x) < 605) and -- Score far left
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 597;
                number <= score4;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
                --below is "score:" printed to screen
            elsif (unsigned(pixel_x) >= 582) and (unsigned(pixel_x) < 590) and -- :
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 582;
                number <= 15;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 572) and (unsigned(pixel_x) < 580) and -- e
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 572;
                number <= 14;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 562) and (unsigned(pixel_x) < 570) and -- r
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 562;
                number <= 13;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 552) and (unsigned(pixel_x) < 560) and -- o
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 552;
                number <= 12;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 542) and (unsigned(pixel_x) < 550) and -- c
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 542;
                number <= 11;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 532) and (unsigned(pixel_x) < 540) and -- S
                (unsigned(pixel_y) >= 460) and (unsigned(pixel_y) < 476) then
                column_offset <= to_integer(signed(pixel_x)) - 532;
                number <= 10;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            end if;
            if (draw_pixel = '1') then
                -- RED
                red_next <= "1111"; 
                green_next <= "0010";
                blue_next <= "0010";
            else
                red_next <= "0000";
                green_next <= "0000";
                blue_next <= "0000";
            end if;
            --draw game over
        elsif (unsigned(pixel_x) >= 272) and (unsigned(pixel_x) < 365) and -- game over screen center
            (unsigned(pixel_y) > 228) and (unsigned(pixel_y) < 252) and game_over_pause = '1' then
            row_offset <= to_integer(signed(pixel_y)) - 232;
            if (unsigned(pixel_x) >= 276) and (unsigned(pixel_x) < 284) and -- r
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 276;
                number <= 16;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 286) and (unsigned(pixel_x) < 294) and -- e
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 286;
                number <= 17;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 296) and (unsigned(pixel_x) < 304) and -- v
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 296;
                number <= 18;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 306) and (unsigned(pixel_x) < 314) and -- O
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 306;
                number <= 19;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 320) and (unsigned(pixel_x) < 328) and -- E
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 320;
                number <= 20;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 330) and (unsigned(pixel_x) < 338) and -- M
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 330;
                number <= 21;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 340) and (unsigned(pixel_x) < 348) and -- A
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 340;
                number <= 19;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            elsif (unsigned(pixel_x) >= 350) and (unsigned(pixel_x) < 358) and -- G
                (unsigned(pixel_y) >= 232) and (unsigned(pixel_y) < 248) then
                column_offset <= to_integer(signed(pixel_x)) - 350;
                number <= 22;
                if number_return_data = '1' then
                    draw_pixel := '1';
                end if;
            end if;
            if (draw_pixel = '1') then
                -- RED
                red_next <= "1111"; 
                green_next <= "0010";
                blue_next <= "0010";
            else
                red_next <= "0000";
                green_next <= "0000";
                blue_next <= "0000";
            end if;
        end if;
    end process;

  -- generate r,g,b registers
   process ( video_on, pixel_tick, red_next, green_next, blue_next)
   begin
      if rising_edge(pixel_tick) then
          if (video_on = '1') then
            red_reg <= red_next;
            green_reg <= green_next;
            blue_reg <= blue_next;   
          else
            red_reg <= "0000";
            green_reg <= "0000";
            blue_reg <= "0000";                    
          end if;
      end if;
   end process;
   
   red <= STD_LOGIC_VECTOR(red_reg);
   green <= STD_LOGIC_VECTOR(green_reg); 
   blue <= STD_LOGIC_VECTOR(blue_reg);
   
--   function in_wall_section(px : integer) return std_logic is
--   begin
   
--   end in_wall_section;

end duck_top;