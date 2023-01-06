library ieee ;
use ieee.std_logic_1164.all;


package uart_aes_sim is

  generic (
    period_ns : time
  );

  procedure uart_send (       data : in std_logic_vector(7 downto 0);
                       signal   tx : out std_logic);

  procedure uart_recv (       data : out std_logic_vector(7 downto 0);
                       signal   rx : in  std_logic);

  procedure aes_setup (         key : in  std_logic_vector(0 to 127);
                              nonce : in  std_logic_vector(0 to 95);
                       signal    tx : out std_logic);

  procedure aes_write (        data : in  std_logic_vector(0 to 127);
                       signal    tx : out std_logic);

  procedure aes_read (        data : out std_logic_vector(0 to 127);
                      signal    tx : out std_logic;
                      signal    rx : in  std_logic);

  procedure aes_crypt (signal    tx : out std_logic;
                       signal    rx : in  std_logic);

end package;

package body uart_aes_sim is

  procedure uart_send (       data : in std_logic_vector(7 downto 0);
                       signal   tx : out std_logic) is
  begin
    report "UART send: 0x" & to_hstring(data);
    wait for period_ns;
    tx <= '0';
    wait for period_ns;
    for i in 0 to 7 loop
      tx <= data(i);
      wait for period_ns;
    end loop;
    tx <= '1';
    wait for 0 ns;
  end procedure;

  procedure uart_recv (       data : out std_logic_vector(7 downto 0);
                       signal   rx : in  std_logic) is
  begin
    wait until not rx;
    wait for period_ns;   -- Skip start bit
    wait for period_ns/2;
    for i in 0 to 7 loop
      data(i) := rx;
      wait for period_ns;
    end loop;
    report "UART recv: 0x" & to_hstring(data);
  end procedure;

  procedure aes_setup (         key : in  std_logic_vector(0 to 127);
                              nonce : in  std_logic_vector(0 to 95);
                       signal    tx : out std_logic) is
  begin
    -- Reset control register
    uart_send(x"01", tx);
    uart_send(x"01", tx);
    -- Write key register
    for i in 0 to 15 loop
      uart_send(x"11", tx);
      uart_send(key(i*8 to i*8+7), tx);
    end loop;
    -- Write nonce register
    for i in 0 to 11 loop
      uart_send(x"21", tx);
      uart_send(nonce(i*8 to i*8+7), tx);
    end loop;
    -- Set control registers CTR_START bit
    uart_send(x"01", tx);
    uart_send(x"02", tx);
  end procedure;

  procedure aes_write (        data : in  std_logic_vector(0 to 127);
                       signal    tx : out std_logic) is
  begin
    -- Write din register
    for i in 0 to 15 loop
      uart_send(x"31", tx);
      uart_send(data(i*8 to i*8+7), tx);
    end loop;
  end procedure;

  procedure aes_read (        data : out std_logic_vector(0 to 127);
                      signal    tx : out std_logic;
                      signal    rx : in  std_logic) is
    variable v_data : std_logic_vector(7 downto 0);
  begin
    -- Check for valid AES output data
    loop
      uart_send(x"00", tx);
      uart_recv(v_data, rx);
      exit when v_data(3);
    end loop;
    -- Read dout register
    for i in 0 to 15 loop
      uart_send(x"40", tx);
      uart_recv(data(i*8 to i*8+7), rx);
    end loop;
  end procedure;

  procedure aes_crypt (signal    tx : out std_logic;
                       signal    rx : in  std_logic) is
    variable v_data : std_logic_vector(7 downto 0);
  begin
    uart_send(x"00", tx);
    uart_recv(v_data, rx);
    v_data(2) := '1';
    -- Set control registers CTR_START bit
    uart_send(x"01", tx);
    uart_send(v_data, tx);
  end procedure;

end package body;
