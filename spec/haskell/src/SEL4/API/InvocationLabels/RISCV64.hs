-- Copyright 2018, Data61, CSIRO
--
-- This software may be distributed and modified according to the terms of
-- the GNU General Public License version 2. Note that NO WARRANTY is provided.
-- See "LICENSE_GPLv2.txt" for details.
--
-- @TAG(DATA61_GPL)

-- This module defines the machine-specific invocations for RISCV 64bit.

{-# LANGUAGE EmptyDataDecls #-}

module SEL4.API.InvocationLabels.RISCV64 where

-- FIXME RISCV unchecked copypasta
data ArchInvocationLabel
        = RISCVPageDirectoryMap
        | RISCVPageDirectoryUnmap
        | RISCVPageTableMap
        | RISCVPageTableUnmap
        | RISCVPageMap
        | RISCVPageRemap
        | RISCVPageUnmap
        | RISCVPageGetAddress
        | RISCVFIXME -- FIXME RISCV TODO
        deriving (Show, Eq, Enum, Bounded)