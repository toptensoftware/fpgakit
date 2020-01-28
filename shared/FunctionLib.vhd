--------------------------------------------------------------------------
--
-- FunctionLib
--
-- Miscellaneous Utility Functions
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package FunctionLib is

    -- Find the base-2 log of a number
    function Log2(v : in natural) return natural;

    -- Select one of two integers based on a Boolean.
    function IntSelect(s : in boolean; a : in integer; b : in integer) return integer;

    -- Find the maximum of two integers.
    function IntMax(a : in integer; b : in integer) return integer;

    -- Find the minimum of two integers.
    function IntMin(a : in integer; b : in integer) return integer;

    function format_std_logic_vector( a: std_logic_vector) return string;

end package;



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package body FunctionLib is

-- Find the base 2 log of a number.
function Log2(v : in natural) return natural is
    variable n    : natural;
    variable logn : natural;
begin
    n := 1;
    for i in 0 to 128 loop
        logn := i;
        exit when (n >= v);
        n := n * 2;
    end loop;
    return logn;
end function Log2;

-- Select one of two integers based on a Boolean.
function IntSelect(s : in boolean; a : in integer; b : in integer) return integer is
begin
    if s then
        return a;
    else
        return b;
    end if;
end function IntSelect;

-- Find the maximum of two integers.
function IntMax(a : in integer; b : in integer) return integer is
begin
    if a > b then
        return a;
    else
        return b;
    end if;
end function IntMax;
  
  -- Find the minimum of two integers.
function IntMin(a : in integer; b : in integer) return integer is
begin
    if a > b then
        return a;
    else
        return b;
    end if;
end function IntMin;
  
function format_std_logic_vector( a: std_logic_vector) return string is
    variable b : string (a'length downto 1) := (others => NUL);
begin
        for i in a'length-1 downto 0 loop
        b(i+1) := std_logic'image(a((i)))(2);
        end loop;
    return b;
end function;

end package body;
