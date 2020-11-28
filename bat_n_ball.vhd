--bat_n_ball final draft

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;



ENTITY bat_n_ball IS
	PORT (
		v_sync : IN STD_LOGIC;
		pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		bat_x : IN STD_LOGIC_VECTOR (10 DOWNTO 0); -- current bat x position
		serve : IN STD_LOGIC; -- initiates serve
		red : OUT STD_LOGIC;
		green : OUT STD_LOGIC;
		blue : OUT STD_LOGIC
	);
END bat_n_ball;

ARCHITECTURE Behavioral OF bat_n_ball IS
	SIGNAL gapsize : INTEGER := 60; -- ball size in pixels
	CONSTANT bat_w : INTEGER := 6; -- bat width in pixels
	CONSTANT bat_h : INTEGER := 6; -- bat height in pixels
	CONSTANT wall_h : INTEGER := 4; -- thickness of the wall
	signal duck_x : integer := 115; --constant duck x position
    signal duck_y : integer := 150; --initial duck y position
	SIGNAL score : integer :=0; -- score;+1for each wall passed
	-- distance ball moves each frame
	SIGNAL ball_speed : STD_LOGIC_VECTOR (9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (5, 10);
	SIGNAL wall_on : STD_LOGIC; -- indicates whether wall is at current pixel position
	SIGNAL bat_on : STD_LOGIC; -- indicates whether bat at over current pixel position
	SIGNAL game_on : STD_LOGIC := '0'; -- indicates whether ball is in play
	-- current ball position - intitialized to center of screen
	SIGNAL gap_x : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(320, 10);
	SIGNAL wall_y : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(5, 10);-- might need to mess around with the height
	-- bat vertical position
	CONSTANT bat_y : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400, 10);
	-- current ball motion - initialized to (+ ball_speed) pixels/frame in both X and Y directions
	SIGNAL wall_y_motion : STD_LOGIC_VECTOR(9 DOWNTO 0) := ball_speed;
	SIGNAL x : integer :=320;
	SIGNAL flag : integer :=0;
	 signal duck_top, duck_bottom, duck_left, duck_right : integer := 0; 

BEGIN
    duck_left <= duck_x;--duck doesnt move in x direction, only up and down
    duck_right <=  duck_x + 71;            
    duck_top <= duck_y;
    duck_bottom <=  duck_y + 56;

	red <= NOT bat_on; -- color setup for red ball and cyan bat on white background
	green <= wall_on;
	blue <= NOT wall_on;
	-- process to draw gap
	-- set ball_on if current pixel address is covered by ball position
	balldraw : PROCESS (wall_y, gap_x, pixel_row, pixel_col) IS
		VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
	BEGIN
        IF ((pixel_col >= gap_x - gapsize/2) OR (gap_x <= gapsize/2)) AND
		 pixel_col <= gap_x + gapsize/2 AND
			 pixel_row >= wall_y - wall_h AND
			 pixel_row <= wall_y + wall_h THEN
				wall_on <= '1';
		ELSE
			wall_on <= '0';
		END IF;
	END PROCESS;
	-- process to draw bat
	-- set bat_on if current pixel address is covered by bat position
	
--	batdraw : PROCESS (bat_x, pixel_row, pixel_col) IS
--		VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
--	BEGIN
--		IF ((pixel_col >= bat_x - bat_w) OR (bat_x <= bat_w)) AND
--		 pixel_col <= bat_x + bat_w AND
--			 pixel_row >= bat_y - bat_h AND
--			 pixel_row <= bat_y + bat_h THEN
--				bat_on <= '1';
--		ELSE
--			bat_on <= '0';
--		END IF;
	--	END PROCESS;
		-- process to move ball once every frame (i.e. once every vsync pulse)
		
	duckdraw : PROCESS (bat_x, pixel_row, pixel_col)
	type duck_sprite is array (0 to 55) of std_logic_vector(0 to 70);
	 
    variable duck_data : duck_sprite := (     
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
    variable pos_in_duck_x: integer := conv_integer(signed(pixel_row)) - duck_left;
    variable pos_in_duck_y: integer := conv_integer(signed(pixel_col)) - duck_top;
    variable draw_pixel: std_logic := '0';
	begin
	 draw_pixel := '0';
        if (unsigned(pixel_row) >= duck_left) and (unsigned(pixel_row) < duck_right) and
        (unsigned(pixel_col) >= duck_top) and (unsigned(pixel_col) < (duck_bottom)) and
        (duck_data(pos_in_duck_y)(pos_in_duck_x) = '1') then
        		bat_on <= '1';
    	ELSE
			bat_on <= '0';
		end if;
        
	end process;
		
		mball : PROCESS
			VARIABLE temp : STD_LOGIC_VECTOR (10 DOWNTO 0);
		BEGIN
			WAIT UNTIL rising_edge(v_sync);
			IF serve = '1' AND game_on = '0' THEN -- test for new serve
			    score<=0;
			    gapsize<=60;
			    ball_speed<=CONV_STD_LOGIC_VECTOR (5, 10);
				game_on <= '1';
				wall_y_motion <= (ball_speed); -- set vspeed to (- ball_speed) pixels
			ELSIF wall_y + wall_h/2 >= 480 THEN -- if ball meets bottom wall
			    IF flag=0 THEN
			    score <= score+1;
			    flag <=1;
			    END IF;
			    --gapsize is decreased and speed is increased;
			    --if '=' doesn't work try '<' and work from 5 to 15 to 25
			    --IF score=5 THEN
			    --    gapsize<=70;
			    --    ball_speed<=CONV_STD_LOGIC_VECTOR (6, 10);
			    --ELSIF score=15 THEN
			    --    gapsize<=60;
			    --    ball_speed<=CONV_STD_LOGIC_VECTOR (5, 10);
			    --ELSIF score=25 THEN
			    --    gapsize<=50;
			    --    ball_speed<=CONV_STD_LOGIC_VECTOR (6, 10);
			    --END IF;
			    --wall_y_motion<=ball_speed;
			    --get a new x-position for the gap with each reset
			    --x <=((abs(320-x))+(123*(score**2)) mod 560)+40;
			    --trying without the initial abs(320-x);
			    --This somehow creates a random number, don't ask me how
			    x <=((123*(score**2)) mod 560)+40;
			    IF x<40 THEN
			    x <=40;
			    ELSIF x>600 THEN
			    x <=600;
			    END IF;
			    gap_x <= CONV_STD_LOGIC_VECTOR(x, 10);
				wall_y <= CONV_STD_LOGIC_VECTOR(5, 10);
				flag<=0;
			END IF;
			-- landed within the gap
			IF wall_y <= bat_y + bat_h/2 AND
			 wall_y >= bat_y - bat_h/2 THEN
                IF (bat_x + bat_w/2) <= (gap_x + gapsize/2) AND
                 (bat_x - bat_w/2) >= (gap_x - gapsize/2) Then
                     --(bat_y + bat_h/2) >= (wall_y - wall_h) AND
                     --(bat_y - bat_h/2) <= (wall_y + wall_h) THEN
                     --nothing, it's all good   
                ELSE
                -- hit the wall you lose
                game_on <= '0';
                gap_x <= CONV_STD_LOGIC_VECTOR(320, 10);
                gapsize<=60;
			    ball_speed<=CONV_STD_LOGIC_VECTOR (5, 10);
			    wall_y_motion<=ball_speed;
                END IF;
            END IF;
			
			-- compute next ball vertical position
			-- variable temp adds one more bit to calculation to fix unsigned underflow problems
			-- when ball_y is close to zero and ball_y_motion is negative(This is not needed)
			temp := ('0' & wall_y) + (wall_y_motion(9) & wall_y_motion);
			IF game_on = '0' THEN
				wall_y <= CONV_STD_LOGIC_VECTOR(5, 10);
			ELSIF temp(10) = '1' THEN
				wall_y <= (OTHERS => '0');
			ELSE wall_y <= temp(9 DOWNTO 0);
			END IF;
			
			END PROCESS;
END Behavioral;