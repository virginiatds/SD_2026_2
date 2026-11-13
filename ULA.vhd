library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ULA is
    generic (
        DEBOUNCE_CYCLES : positive := 500000;
        BUTTON_ACTIVE_LEVEL : std_logic := '1'
    );
    port (
        clk, button : in std_logic;
        switches : in std_logic_vector(3 downto 0);
        leds_out : out std_logic_vector(7 downto 0)
    );
end ULA;

architecture Behavioral of ULA is
    -- 0: operation, 1: A, 2: B, 3: result
    signal state : integer range 0 to 3 := 0;
    signal opcode : std_logic_vector(2 downto 0) := "000";
    signal a_reg, b_reg : std_logic_vector(3 downto 0) := "0000";
    signal sw_meta, sw_sync : std_logic_vector(3 downto 0) := "0000";
    signal result, leds : std_logic_vector(7 downto 0) := "00000000";
    signal press_pulse : std_logic;
    signal startup_reset : std_logic := '1';
    signal startup_count : integer range 0 to 15 := 0;
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sw_meta, sw_sync : signal is "TRUE";
begin
    leds_out <= leds;

    deb_dut : entity work.ULA_debounce
        generic map (STABLE_CYCLES => DEBOUNCE_CYCLES,
                     ACTIVE_LEVEL => BUTTON_ACTIVE_LEVEL)
        port map (clk => clk, rst => startup_reset,
                  input => button, debounce => press_pulse);

    op_dut : entity work.operations
        port map (opcode => opcode, A => a_reg, B => b_reg, result => result);

    -- Reset after loading the FPGA.
    process(clk)
    begin
        if rising_edge(clk) then
            if startup_count < 15 then
                startup_count <= startup_count + 1;
            else
                startup_reset <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            sw_meta <= switches;
            sw_sync <= sw_meta;

            if startup_reset = '1' then
                state <= 0;
                opcode <= "000";
                a_reg <= "0000";
                b_reg <= "0000";
                leds <= "00000000";
            elsif state = 3 then
                -- B was saved on the previous clock.
                leds <= result;
                state <= 0;
            elsif press_pulse = '1' then
                case state is
                    when 0 =>
                        -- Only 0000 to 0111 are valid operations.
                        if sw_sync(3) = '0' then
                            opcode <= sw_sync(2 downto 0);
                            a_reg <= "0000";
                            b_reg <= "0000";
                            leds <= "0000" & sw_sync;
                            state <= 1;
                        end if;
                    when 1 =>
                        a_reg <= sw_sync;
                        leds <= "0000" & sw_sync;
                        state <= 2;
                    when 2 =>
                        b_reg <= sw_sync;
                        state <= 3;
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
