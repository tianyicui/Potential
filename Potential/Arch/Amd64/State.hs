{-# LANGUAGE
	TemplateHaskell,
	MultiParamTypeClasses,
	FlexibleContexts,
	FlexibleInstances,
	TypeFamilies #-}
module Potential.Arch.Amd64.State
	( Reg(..), MS
	, rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp, rflags
	, rip, r08, r09, r10, r11, r12, r13, r14, r15
	, rcmp, ralloc
	) where

import Prelude
import Potential.Arch.Builder

data Reg =
    Rax | Rbx | Rcx | Rdx
  | Rsi | Rdi | Rbp | Rsp
  | Rflags | Rip
  | R08 | R09 | R10 | R11
  | R12 | R13 | R14 | R15
  | Rcmp | Ralloc -- a hack


data MS rax rbx rcx rdx rsi rdi rbp rsp rflags
	rip r08 r09 r10 r11 r12 r13 r14 r15 alloc cmp =
     MS { ms_rax :: rax	-- return value
	, ms_rbx :: rbx	-- caller
	, ms_rcx :: rcx	-- arg 3
	, ms_rdx :: rdx	-- arg 2
	, ms_rsi :: rsi	-- arg 1
	, ms_rdi :: rdi	-- arg 0
	, ms_rbp :: rbp	-- caller
	, ms_rsp :: rsp
	, ms_rflags :: rflags
	, ms_rip :: rip
	, ms_r08 :: r08	-- arg 4
	, ms_r09 :: r09	-- arg 5
	, ms_r10 :: r10
	, ms_r11 :: r11
	, ms_r12 :: r12	-- caller
	, ms_r13 :: r13	-- caller
	, ms_r14 :: r14	-- caller
	, ms_r15 :: r15	-- caller
	, ms_ralloc :: alloc -- the memory allocator
	, ms_rcmp :: cmp -- the last cmp
	}

defineRegisters ''MS ''Reg
		[ "ax", "bx", "cx", "dx", "si", "di", "bp", "sp", "flags"
		, "ip", "08", "09", "10", "11", "12", "13", "14", "15"
		, "alloc", "cmp"]
