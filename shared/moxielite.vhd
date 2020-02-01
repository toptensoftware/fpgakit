--------------------------------------------------------------------------
--
-- MoxieLite wrapper directives
--
-- Directives for xilt to import moxielite cpu core
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------


--xilt:require:./moxie-cores/cores/MoxieLite/moxielite.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_alu.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_alu2.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_decode.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_divider.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_lshift.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_multiplier.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_package.vhd
--xilt:require:./moxie-cores/cores/MoxieLite/moxielite_rshift.vhd


entity moxielite_unused is
PORT
(
    unused : in boolean
);
end moxielite_unused;

architecture behavior of moxielite_unused is
begin
end behavior;

