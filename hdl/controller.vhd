LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY controller IS
  PORT (
    btn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sw : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    o_mins, o_secs, o_wmins : OUT INTEGER RANGE 0 TO 59;
    o_hours, o_whours : OUT INTEGER RANGE 0 TO 23;
    alarm : OUT STD_LOGIC;
    state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC
  );
END controller;

ARCHITECTURE Behavioral OF controller IS

  COMPONENT trigger_gen IS
    GENERIC (Delta : INTEGER);
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      trigger : OUT STD_LOGIC
    );
  END COMPONENT trigger_gen;

  -- pro Viertelsekunde einen Takt lang '1'
  SIGNAL fasttrigger : STD_LOGIC;
  -- fasttrigger wird zurueckgesetzt, wenn BTN2 oder BTN3 gedrueckt werden
  SIGNAL fasttimer_reset : STD_LOGIC;
  -- pro Sekunde einen Takt lang '1'
  SIGNAL sectrigger : STD_LOGIC;

  SIGNAL hours, whours : INTEGER RANGE 0 TO 23;
  SIGNAL secs, mins, wmins : INTEGER RANGE 0 TO 59;

  -- fuer Flankenerkennung der Taster
  SIGNAL btn_shift : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL btn_triggered : STD_LOGIC_VECTOR(3 DOWNTO 0);

  TYPE state_type IS (NTIME, SET_TIME, SET_ALARM, error);
  SIGNAL current_state : state_type;

BEGIN
  fasttimer_reset <= reset OR
    btn_triggered(2) OR btn_triggered(3);

  fasttimer : trigger_gen
  GENERIC MAP(11)
  PORT MAP(clk, fasttimer_reset, fasttrigger);

  sectimer : trigger_gen
  GENERIC MAP(13)
  PORT MAP(clk, reset, sectrigger);

  FSM : PROCESS (clk, reset)
    VARIABLE next_state : state_type;
  BEGIN
    IF reset = '1' THEN
      hours <= 0;
      mins <= 0;
      secs <= 0;
      whours <= 0;
      wmins <= 0;
      alarm <= '0';
      current_state <= NTIME;
    ELSIF clk'event AND clk = '1' THEN
      FOR i IN 0 TO 3 LOOP
        btn_shift(i) <= btn(i);
        btn_triggered(i) <= NOT btn_shift(i) AND btn(i);
      END LOOP;

      -- TODO: Zaehle Uhr hoch
      IF (sectrigger = '1') THEN

        IF (secs = 59) THEN
          -- reset secs to 0
          secs <= 0;

          IF (mins = 59) THEN
            -- reset mins to 0
            mins <= 0;

            IF (hours = 23) THEN
              -- reset hours to 0
              hours <= 0;
            ELSE
              -- add one hour
              hours <= hours + 1;
            END IF;
          ELSE
            -- add one minute
            mins <= mins + 1;
          END IF;

        ELSE
          -- add one second
          secs <= secs + 1;
        END IF;

      END IF;

      -- TODO: Pruefe, ob Alarm ausgeloest werden muss
      IF (sw(0) = '1') THEN -- Only trigger if alarm switch is on
        IF (mins = wmins AND hours = whours) THEN -- Compare current to set time
          alarm <= '1'; -- Trigger alarm
        END IF;
      END IF;

      CASE current_state IS
          -- Zustand Time
        WHEN NTIME =>
          -- TODO: Setze naechsten Zustand
          IF (btn_triggered(0) = '1' AND btn_triggered(1) = '0') THEN
            next_state := SET_TIME; -- BTN0 -> SetTime
          END IF;

          IF (btn_triggered(0) = '0' AND btn_triggered(1) = '1') THEN
            next_state := SET_ALARM; -- BTN1 -> SetAlarm
          END IF;

          -- Zustand SetTime
        WHEN SET_TIME =>
          -- TODO: Setze naechsten Zustand
          IF (btn_triggered(0) = '1' AND btn_triggered(1) = '0') THEN
            next_state := NTIME; -- BTN0 -> Time
          END IF;

          IF (btn_triggered(0) = '0' AND btn_triggered(1) = '1') THEN
            next_state := SET_ALARM; -- BTN 1 -> SetAlarm
          END IF;

          -- TODO: Setze Minute und Stunde mit BTN(2) bzw. BTN(3)

          -- Minutes
          IF (fasttrigger = '1' AND btn_triggered(2) = '1') THEN
            IF (mins = 59) THEN
              mins <= 0;
            ELSE
              mins <= mins + 1; -- increment
            END IF;
          END IF;

          -- Hours
          IF (fasttrigger = '1' AND btn_triggered(3) = '1') THEN
            IF (hours = 23) THEN
              hours <= 0;
            ELSE
              hours <= hours + 1; -- increment
            END IF;
          END IF;

          -- Zustand SetAlarm
        WHEN SET_ALARM =>
          -- TODO: Setze naechsten Zustand
          IF btn_triggered(0) = '1' AND btn_triggered(1) = '0' THEN
            next_state := SET_TIME; -- BTN0 -> SetTime
          END IF;

          IF btn_triggered(0) = '0' AND btn_triggered(1) = '1' THEN
            next_state := NTIME; -- BTN1 -> Time
          END IF;

          -- TODO: Setze Minute und Stunde mit BTN(2) bzw. BTN(3)
          -- Minutes
          IF (fasttrigger = '1' AND btn_triggered(2) = '1') THEN
            IF (wmins = 59) THEN
              wmins <= 0;
            ELSE
              wmins <= wmins + 1; -- increment
            END IF;
          END IF;

          -- Hours
          IF (fasttrigger = '1' AND btn_triggered(3) = '1') THEN
            IF (whours = 23) THEN
              whours <= 0;
            ELSE
              whours <= hours + 1; -- increment
            END IF;
          END IF;

          -- Illegale Zustaende
        WHEN OTHERS =>
          next_state := NTIME;
      END CASE;

      current_state <= next_state;
    END IF;
  END PROCESS FSM;

  o_hours <= hours;
  o_mins <= mins;
  o_secs <= secs;
  o_whours <= whours;
  o_wmins <= wmins;

  WITH current_state SELECT
    state <= "00" WHEN NTIME,
    "01" WHEN SET_TIME,
    "10" WHEN SET_ALARM,
    "11" WHEN OTHERS;
END ARCHITECTURE Behavioral;