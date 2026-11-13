library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ULA_debounce is
    generic (
        STABLE_CYCLES : positive := 500000; -- 10 ms at 50 MHz
        ACTIVE_LEVEL : std_logic := '1'
    );
    port (
        clk, rst, input : in std_logic;
        debounce : out std_logic
    );
end ULA_debounce;

architecture Behavioral of ULA_debounce is
    signal button_meta, button_sync : std_logic := not ACTIVE_LEVEL;
    signal warmup : integer range 0 to 2 := 0;
    signal armed : std_logic := '0';
    signal count : integer range 0 to STABLE_CYCLES - 1 := 0;
    signal pulse : std_logic := '0';
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of button_meta, button_sync : signal is "TRUE";
begin
    debounce <= pulse;

    process(clk)
    begin
        if rising_edge(clk) then
            pulse <= '0';
            if rst = '1' then
                button_meta <= not ACTIVE_LEVEL;
                button_sync <= not ACTIVE_LEVEL;
                warmup <= 0;
                armed <= '0';
                count <= 0;
            else
                -- Two flip-flops for the button.
                button_meta <= input;
                button_sync <= button_meta;
                if warmup < 2 then
                    warmup <= warmup + 1;
                    count <= 0;
                elsif armed = '0' then
                    -- Wait for a stable release, also at startup.
                    if button_sync = not ACTIVE_LEVEL then
                        if count = STABLE_CYCLES - 1 then
                            armed <= '1';
                            count <= 0;
                        else
                            count <= count + 1;
                        end if;
                    else
                        count <= 0;
                    end if;
                else
                    -- One pulse after a stable press.
                    if button_sync = ACTIVE_LEVEL then
                        if count = STABLE_CYCLES - 1 then
                            pulse <= '1';
                            armed <= '0';
                            count <= 0;
                        else
                            count <= count + 1;
                        end if;
                    else
                        count <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
