LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;

ENTITY int2ascii IS
    PORT (
        i_number : IN INTEGER RANGE 0 TO 59;
        o_ascii0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_ascii1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END ENTITY int2ascii;

ARCHITECTURE behavioral OF int2ascii IS
    SIGNAL s_bcd0 : unsigned(3 DOWNTO 0);
    SIGNAL s_bcd1 : unsigned(3 DOWNTO 0);
BEGIN
    PROCESS (i_number)
        VARIABLE v_bcd0 : unsigned(3 DOWNTO 0);
        VARIABLE v_bcd1 : unsigned(3 DOWNTO 0);
        VARIABLE v_number : unsigned(7 DOWNTO 0);
    BEGIN
        v_bcd0 := "0000";
        v_bcd1 := "0000";
        v_number := to_unsigned(i_number, v_number'length);

        -- low = lowest value of type (0 in this case), length is 8 in this case, try using 'high
        FOR i IN v_number'low TO v_number'length - 1 LOOP

            -- Check for v_bcd greater 4
            -- bcd0
            IF (v_bcd0 > 4) THEN
                v_bcd0 := v_bcd0 + 3; -- Add 3
            END IF;

            --bcd1
            IF (v_bcd1 > 4) THEN
                v_bcd1 := v_bcd1 + 3; -- Add 3
            END IF;

            -- Shift left
            v_bcd1 := v_bcd1 SLL 1; -- Alternative: SHIFT_LEFT(v_bcd1, 1)
            v_bcd1(0) := v_bcd0(3);
            v_bcd0 := v_bcd0 SLL 1; -- Alternative: SHIFT_LEFT(v_bcd0, 1)

            v_bcd0(0) := v_number(v_number'length - i); -- try using 'high

        END LOOP;

        s_bcd0 <= v_bcd0;
        s_bcd1 <= v_bcd1;
    END PROCESS;
    o_ascii0 <= STD_LOGIC_VECTOR("0011" & s_bcd0);
    o_ascii1 <= STD_LOGIC_VECTOR("0011" & s_bcd1);
END ARCHITECTURE behavioral;