library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity operations is
    port (
        opcode : in std_logic_vector(2 downto 0);
        A, B : in std_logic_vector(3 downto 0);
        result : out std_logic_vector(7 downto 0)
    );
end operations;

architecture Behavioral of operations is
begin
    process(opcode, A, B)
        variable r, bb : std_logic_vector(3 downto 0);
        variable n, v, c, z, next_c : std_logic;
        variable amount : integer range 0 to 3;
    begin
        r := "0000";
        bb := B;
        n := '0'; v := '0'; c := '0'; z := '0';
        next_c := '0';
        amount := 0;

        case opcode is
            when "000" => -- Addition
                for i in 0 to 3 loop
                    r(i) := A(i) xor B(i) xor c;
                    next_c := (A(i) and B(i)) or (A(i) and c) or (B(i) and c);
                    c := next_c;
                end loop;
                if A(3) = B(3) and r(3) /= A(3) then
                    v := '1';
                end if;

            when "001" => -- Subtraction: A + NOT B + 1
                bb := not B;
                c := '1';
                for i in 0 to 3 loop
                    r(i) := A(i) xor bb(i) xor c;
                    next_c := (A(i) and bb(i)) or (A(i) and c) or (bb(i) and c);
                    c := next_c;
                end loop;
                if A(3) /= B(3) and r(3) /= A(3) then
                    v := '1';
                end if;

            when "010" => -- Signed comparison
                if signed(A) > signed(B) then
                    r := "0001";
                elsif signed(A) < signed(B) then
                    r := "0010";
                else
                    r := "0100";
                end if;

            when "011" => r := A xor B;

            when "100" => -- B: fill, direction, count (two bits)
                amount := to_integer(unsigned(B(1 downto 0)));
                r := A;
                for i in 1 to 3 loop
                    if i <= amount then
                        if B(2) = '0' then
                            r := r(2 downto 0) & B(3);
                        else
                            r := B(3) & r(3 downto 1);
                        end if;
                    end if;
                end loop;

            when "101" => -- Absolute value of A; B is ignored
                if A(3) = '1' then
                    r := std_logic_vector(unsigned(not A) + to_unsigned(1, 4));
                else
                    r := A;
                end if;
                if A = "1000" then v := '1'; end if;

            when "110" => r := A and B;
            when "111" => r := A or B;
            when others => null;
        end case;

        -- LED order: N V C Z R3 R2 R1 R0.
        n := r(3);
        if r = "0000" then z := '1'; end if;
        result <= n & v & c & z & r;
    end process;
end Behavioral;
