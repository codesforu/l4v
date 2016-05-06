(*
 * Copyright 2014, General Dynamics C4 Systems
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(GD_GPL)
 *)

(* 
  VSpace lookup code.
*)

theory ArchVSpace_H
imports
  "../CNode_H"
  "../KI_Decls_H"
  ArchVSpaceDecls_H
begin

context X64 begin

#INCLUDE_HASKELL SEL4/Kernel/VSpace/X64.lhs CONTEXT X64 bodies_only ArchInv=ArchRetypeDecls_H NOT checkPDAt checkPTAt setCurrentVSpaceRoot checkValidMappingSize asidInvalidate

defs checkValidMappingSize_def:
  "checkValidMappingSize sz \<equiv> stateAssert
    (\<lambda>s. 2 ^ pageBitsForSize sz <= gsMaxObjectSize s) []"

defs asidInvalidate_def:
"asidInvalidate asid \<equiv> doMachineOp $ hwASIDInvalidate asid"

defs setCurrentVSpaceRoot_def:
"setCurrentVSpaceRoot addr asid \<equiv> archSetCurrentVSpaceRoot addr asid"

end (* context X64 *) 

end
