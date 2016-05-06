(*
 * Copyright 2014, General Dynamics C4 Systems
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(GD_GPL)
 *)

chapter "Retyping Objects"

theory ArchRetypeDecls_H
imports
  "../FaultMonad_H"
  "../EndpointDecls_H"
  "../KernelInitMonad_H"
  "../PSpaceFuns_H"
  ArchObjInsts_H
begin

context X64 begin

datatype pdptinvocation =
    PDPTUnmap arch_capability machine_word
  | PDPTMap capability machine_word pml4e machine_word

primrec
  pdptMapCap :: "pdptinvocation \<Rightarrow> capability"
where
  "pdptMapCap (PDPTMap v0 v1 v2 v3) = v0"

primrec
  pdptMapPML4Slot :: "pdptinvocation \<Rightarrow> machine_word"
where
  "pdptMapPML4Slot (PDPTMap v0 v1 v2 v3) = v3"

primrec
  pdptUnmapCap :: "pdptinvocation \<Rightarrow> arch_capability"
where
  "pdptUnmapCap (PDPTUnmap v0 v1) = v0"

primrec
  pdptMapCTSlot :: "pdptinvocation \<Rightarrow> machine_word"
where
  "pdptMapCTSlot (PDPTMap v0 v1 v2 v3) = v1"

primrec
  pdptMapPML4E :: "pdptinvocation \<Rightarrow> pml4e"
where
  "pdptMapPML4E (PDPTMap v0 v1 v2 v3) = v2"

primrec
  pdptUnmapCapSlot :: "pdptinvocation \<Rightarrow> machine_word"
where
  "pdptUnmapCapSlot (PDPTUnmap v0 v1) = v1"

primrec
  pdptMapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptMapCap_update f (PDPTMap v0 v1 v2 v3) = PDPTMap (f v0) v1 v2 v3"

primrec
  pdptMapPML4Slot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptMapPML4Slot_update f (PDPTMap v0 v1 v2 v3) = PDPTMap v0 v1 v2 (f v3)"

primrec
  pdptUnmapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptUnmapCap_update f (PDPTUnmap v0 v1) = PDPTUnmap (f v0) v1"

primrec
  pdptMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptMapCTSlot_update f (PDPTMap v0 v1 v2 v3) = PDPTMap v0 (f v1) v2 v3"

primrec
  pdptMapPML4E_update :: "(pml4e \<Rightarrow> pml4e) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptMapPML4E_update f (PDPTMap v0 v1 v2 v3) = PDPTMap v0 v1 (f v2) v3"

primrec
  pdptUnmapCapSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> pdptinvocation \<Rightarrow> pdptinvocation"
where
  "pdptUnmapCapSlot_update f (PDPTUnmap v0 v1) = PDPTUnmap v0 (f v1)"

abbreviation (input)
  PDPTUnmap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> pdptinvocation" ("PDPTUnmap'_ \<lparr> pdptUnmapCap= _, pdptUnmapCapSlot= _ \<rparr>")
where
  "PDPTUnmap_ \<lparr> pdptUnmapCap= v0, pdptUnmapCapSlot= v1 \<rparr> == PDPTUnmap v0 v1"

abbreviation (input)
  PDPTMap_trans :: "(capability) \<Rightarrow> (machine_word) \<Rightarrow> (pml4e) \<Rightarrow> (machine_word) \<Rightarrow> pdptinvocation" ("PDPTMap'_ \<lparr> pdptMapCap= _, pdptMapCTSlot= _, pdptMapPML4E= _, pdptMapPML4Slot= _ \<rparr>")
where
  "PDPTMap_ \<lparr> pdptMapCap= v0, pdptMapCTSlot= v1, pdptMapPML4E= v2, pdptMapPML4Slot= v3 \<rparr> == PDPTMap v0 v1 v2 v3"

definition
  isPDPTUnmap :: "pdptinvocation \<Rightarrow> bool"
where
 "isPDPTUnmap v \<equiv> case v of
    PDPTUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPDPTMap :: "pdptinvocation \<Rightarrow> bool"
where
 "isPDPTMap v \<equiv> case v of
    PDPTMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype page_directory_invocation =
    PageDirectoryUnmap arch_capability machine_word
  | PageDirectoryMap capability machine_word pdpte machine_word

primrec
  pdMapCTSlot :: "page_directory_invocation \<Rightarrow> machine_word"
where
  "pdMapCTSlot (PageDirectoryMap v0 v1 v2 v3) = v1"

primrec
  pdUnmapCap :: "page_directory_invocation \<Rightarrow> arch_capability"
where
  "pdUnmapCap (PageDirectoryUnmap v0 v1) = v0"

primrec
  pdMapPDPTE :: "page_directory_invocation \<Rightarrow> pdpte"
where
  "pdMapPDPTE (PageDirectoryMap v0 v1 v2 v3) = v2"

primrec
  pdMapCap :: "page_directory_invocation \<Rightarrow> capability"
where
  "pdMapCap (PageDirectoryMap v0 v1 v2 v3) = v0"

primrec
  pdMapPDPTSlot :: "page_directory_invocation \<Rightarrow> machine_word"
where
  "pdMapPDPTSlot (PageDirectoryMap v0 v1 v2 v3) = v3"

primrec
  pdUnmapCapSlot :: "page_directory_invocation \<Rightarrow> machine_word"
where
  "pdUnmapCapSlot (PageDirectoryUnmap v0 v1) = v1"

primrec
  pdMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdMapCTSlot_update f (PageDirectoryMap v0 v1 v2 v3) = PageDirectoryMap v0 (f v1) v2 v3"

primrec
  pdUnmapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdUnmapCap_update f (PageDirectoryUnmap v0 v1) = PageDirectoryUnmap (f v0) v1"

primrec
  pdMapPDPTE_update :: "(pdpte \<Rightarrow> pdpte) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdMapPDPTE_update f (PageDirectoryMap v0 v1 v2 v3) = PageDirectoryMap v0 v1 (f v2) v3"

primrec
  pdMapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdMapCap_update f (PageDirectoryMap v0 v1 v2 v3) = PageDirectoryMap (f v0) v1 v2 v3"

primrec
  pdMapPDPTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdMapPDPTSlot_update f (PageDirectoryMap v0 v1 v2 v3) = PageDirectoryMap v0 v1 v2 (f v3)"

primrec
  pdUnmapCapSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_directory_invocation \<Rightarrow> page_directory_invocation"
where
  "pdUnmapCapSlot_update f (PageDirectoryUnmap v0 v1) = PageDirectoryUnmap v0 (f v1)"

abbreviation (input)
  PageDirectoryUnmap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> page_directory_invocation" ("PageDirectoryUnmap'_ \<lparr> pdUnmapCap= _, pdUnmapCapSlot= _ \<rparr>")
where
  "PageDirectoryUnmap_ \<lparr> pdUnmapCap= v0, pdUnmapCapSlot= v1 \<rparr> == PageDirectoryUnmap v0 v1"

abbreviation (input)
  PageDirectoryMap_trans :: "(capability) \<Rightarrow> (machine_word) \<Rightarrow> (pdpte) \<Rightarrow> (machine_word) \<Rightarrow> page_directory_invocation" ("PageDirectoryMap'_ \<lparr> pdMapCap= _, pdMapCTSlot= _, pdMapPDPTE= _, pdMapPDPTSlot= _ \<rparr>")
where
  "PageDirectoryMap_ \<lparr> pdMapCap= v0, pdMapCTSlot= v1, pdMapPDPTE= v2, pdMapPDPTSlot= v3 \<rparr> == PageDirectoryMap v0 v1 v2 v3"

definition
  isPageDirectoryUnmap :: "page_directory_invocation \<Rightarrow> bool"
where
 "isPageDirectoryUnmap v \<equiv> case v of
    PageDirectoryUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageDirectoryMap :: "page_directory_invocation \<Rightarrow> bool"
where
 "isPageDirectoryMap v \<equiv> case v of
    PageDirectoryMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype page_table_invocation =
    PageTableUnmap arch_capability machine_word
  | PageTableMap capability machine_word pde machine_word

primrec
  ptMapPDSlot :: "page_table_invocation \<Rightarrow> machine_word"
where
  "ptMapPDSlot (PageTableMap v0 v1 v2 v3) = v3"

primrec
  ptUnmapCapSlot :: "page_table_invocation \<Rightarrow> machine_word"
where
  "ptUnmapCapSlot (PageTableUnmap v0 v1) = v1"

primrec
  ptMapCTSlot :: "page_table_invocation \<Rightarrow> machine_word"
where
  "ptMapCTSlot (PageTableMap v0 v1 v2 v3) = v1"

primrec
  ptUnmapCap :: "page_table_invocation \<Rightarrow> arch_capability"
where
  "ptUnmapCap (PageTableUnmap v0 v1) = v0"

primrec
  ptMapPDE :: "page_table_invocation \<Rightarrow> pde"
where
  "ptMapPDE (PageTableMap v0 v1 v2 v3) = v2"

primrec
  ptMapCap :: "page_table_invocation \<Rightarrow> capability"
where
  "ptMapCap (PageTableMap v0 v1 v2 v3) = v0"

primrec
  ptMapPDSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptMapPDSlot_update f (PageTableMap v0 v1 v2 v3) = PageTableMap v0 v1 v2 (f v3)"

primrec
  ptUnmapCapSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptUnmapCapSlot_update f (PageTableUnmap v0 v1) = PageTableUnmap v0 (f v1)"

primrec
  ptMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptMapCTSlot_update f (PageTableMap v0 v1 v2 v3) = PageTableMap v0 (f v1) v2 v3"

primrec
  ptUnmapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptUnmapCap_update f (PageTableUnmap v0 v1) = PageTableUnmap (f v0) v1"

primrec
  ptMapPDE_update :: "(pde \<Rightarrow> pde) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptMapPDE_update f (PageTableMap v0 v1 v2 v3) = PageTableMap v0 v1 (f v2) v3"

primrec
  ptMapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> page_table_invocation \<Rightarrow> page_table_invocation"
where
  "ptMapCap_update f (PageTableMap v0 v1 v2 v3) = PageTableMap (f v0) v1 v2 v3"

abbreviation (input)
  PageTableUnmap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> page_table_invocation" ("PageTableUnmap'_ \<lparr> ptUnmapCap= _, ptUnmapCapSlot= _ \<rparr>")
where
  "PageTableUnmap_ \<lparr> ptUnmapCap= v0, ptUnmapCapSlot= v1 \<rparr> == PageTableUnmap v0 v1"

abbreviation (input)
  PageTableMap_trans :: "(capability) \<Rightarrow> (machine_word) \<Rightarrow> (pde) \<Rightarrow> (machine_word) \<Rightarrow> page_table_invocation" ("PageTableMap'_ \<lparr> ptMapCap= _, ptMapCTSlot= _, ptMapPDE= _, ptMapPDSlot= _ \<rparr>")
where
  "PageTableMap_ \<lparr> ptMapCap= v0, ptMapCTSlot= v1, ptMapPDE= v2, ptMapPDSlot= v3 \<rparr> == PageTableMap v0 v1 v2 v3"

definition
  isPageTableUnmap :: "page_table_invocation \<Rightarrow> bool"
where
 "isPageTableUnmap v \<equiv> case v of
    PageTableUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageTableMap :: "page_table_invocation \<Rightarrow> bool"
where
 "isPageTableMap v \<equiv> case v of
    PageTableMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype iopage_table_invocation =
    IOPageTableUnmap arch_capability machine_word
  | IOPageTableMap arch_capability machine_word iopte machine_word
  | IOPageTableMapContext arch_capability machine_word iocte machine_word

primrec
  ioptMapCap :: "iopage_table_invocation \<Rightarrow> arch_capability"
where
  "ioptMapCap (IOPageTableMap v0 v1 v2 v3) = v0"
| "ioptMapCap (IOPageTableMapContext v0 v1 v2 v3) = v0"

primrec
  ioptMapCxtTableSlot :: "iopage_table_invocation \<Rightarrow> machine_word"
where
  "ioptMapCxtTableSlot (IOPageTableMapContext v0 v1 v2 v3) = v3"

primrec
  ioptUnmapCap :: "iopage_table_invocation \<Rightarrow> arch_capability"
where
  "ioptUnmapCap (IOPageTableUnmap v0 v1) = v0"

primrec
  ioptMapPT :: "iopage_table_invocation \<Rightarrow> iopte"
where
  "ioptMapPT (IOPageTableMap v0 v1 v2 v3) = v2"

primrec
  ioptMapCxtTableEntry :: "iopage_table_invocation \<Rightarrow> iocte"
where
  "ioptMapCxtTableEntry (IOPageTableMapContext v0 v1 v2 v3) = v2"

primrec
  ioptMapCTSlot :: "iopage_table_invocation \<Rightarrow> machine_word"
where
  "ioptMapCTSlot (IOPageTableMap v0 v1 v2 v3) = v1"
| "ioptMapCTSlot (IOPageTableMapContext v0 v1 v2 v3) = v1"

primrec
  ioptMapPTSlot :: "iopage_table_invocation \<Rightarrow> machine_word"
where
  "ioptMapPTSlot (IOPageTableMap v0 v1 v2 v3) = v3"

primrec
  ioptUnmapCapSlot :: "iopage_table_invocation \<Rightarrow> machine_word"
where
  "ioptUnmapCapSlot (IOPageTableUnmap v0 v1) = v1"

primrec
  ioptMapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapCap_update f (IOPageTableMap v0 v1 v2 v3) = IOPageTableMap (f v0) v1 v2 v3"
| "ioptMapCap_update f (IOPageTableMapContext v0 v1 v2 v3) = IOPageTableMapContext (f v0) v1 v2 v3"

primrec
  ioptMapCxtTableSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapCxtTableSlot_update f (IOPageTableMapContext v0 v1 v2 v3) = IOPageTableMapContext v0 v1 v2 (f v3)"

primrec
  ioptUnmapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptUnmapCap_update f (IOPageTableUnmap v0 v1) = IOPageTableUnmap (f v0) v1"

primrec
  ioptMapPT_update :: "(iopte \<Rightarrow> iopte) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapPT_update f (IOPageTableMap v0 v1 v2 v3) = IOPageTableMap v0 v1 (f v2) v3"

primrec
  ioptMapCxtTableEntry_update :: "(iocte \<Rightarrow> iocte) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapCxtTableEntry_update f (IOPageTableMapContext v0 v1 v2 v3) = IOPageTableMapContext v0 v1 (f v2) v3"

primrec
  ioptMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapCTSlot_update f (IOPageTableMap v0 v1 v2 v3) = IOPageTableMap v0 (f v1) v2 v3"
| "ioptMapCTSlot_update f (IOPageTableMapContext v0 v1 v2 v3) = IOPageTableMapContext v0 (f v1) v2 v3"

primrec
  ioptMapPTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptMapPTSlot_update f (IOPageTableMap v0 v1 v2 v3) = IOPageTableMap v0 v1 v2 (f v3)"

primrec
  ioptUnmapCapSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> iopage_table_invocation \<Rightarrow> iopage_table_invocation"
where
  "ioptUnmapCapSlot_update f (IOPageTableUnmap v0 v1) = IOPageTableUnmap v0 (f v1)"

abbreviation (input)
  IOPageTableUnmap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> iopage_table_invocation" ("IOPageTableUnmap'_ \<lparr> ioptUnmapCap= _, ioptUnmapCapSlot= _ \<rparr>")
where
  "IOPageTableUnmap_ \<lparr> ioptUnmapCap= v0, ioptUnmapCapSlot= v1 \<rparr> == IOPageTableUnmap v0 v1"

abbreviation (input)
  IOPageTableMap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> (iopte) \<Rightarrow> (machine_word) \<Rightarrow> iopage_table_invocation" ("IOPageTableMap'_ \<lparr> ioptMapCap= _, ioptMapCTSlot= _, ioptMapPT= _, ioptMapPTSlot= _ \<rparr>")
where
  "IOPageTableMap_ \<lparr> ioptMapCap= v0, ioptMapCTSlot= v1, ioptMapPT= v2, ioptMapPTSlot= v3 \<rparr> == IOPageTableMap v0 v1 v2 v3"

abbreviation (input)
  IOPageTableMapContext_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> (iocte) \<Rightarrow> (machine_word) \<Rightarrow> iopage_table_invocation" ("IOPageTableMapContext'_ \<lparr> ioptMapCap= _, ioptMapCTSlot= _, ioptMapCxtTableEntry= _, ioptMapCxtTableSlot= _ \<rparr>")
where
  "IOPageTableMapContext_ \<lparr> ioptMapCap= v0, ioptMapCTSlot= v1, ioptMapCxtTableEntry= v2, ioptMapCxtTableSlot= v3 \<rparr> == IOPageTableMapContext v0 v1 v2 v3"

definition
  isIOPageTableUnmap :: "iopage_table_invocation \<Rightarrow> bool"
where
 "isIOPageTableUnmap v \<equiv> case v of
    IOPageTableUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isIOPageTableMap :: "iopage_table_invocation \<Rightarrow> bool"
where
 "isIOPageTableMap v \<equiv> case v of
    IOPageTableMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isIOPageTableMapContext :: "iopage_table_invocation \<Rightarrow> bool"
where
 "isIOPageTableMapContext v \<equiv> case v of
    IOPageTableMapContext v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype page_invocation =
    PageGetAddr machine_word
  | PageRemap "(vmpage_entry * vmpage_entry_ptr)"
  | PageMap asid capability machine_word "(vmpage_entry * vmpage_entry_ptr)"
  | PageUnmap arch_capability machine_word
  | PageIOMap capability machine_word iopte machine_word
  | PageIOUnmap capability machine_word

primrec
  pageIOUnmapCTSlot :: "page_invocation \<Rightarrow> machine_word"
where
  "pageIOUnmapCTSlot (PageIOUnmap v0 v1) = v1"

primrec
  pageMapCap :: "page_invocation \<Rightarrow> capability"
where
  "pageMapCap (PageMap v0 v1 v2 v3) = v1"

primrec
  pageUnmapCapSlot :: "page_invocation \<Rightarrow> machine_word"
where
  "pageUnmapCapSlot (PageUnmap v0 v1) = v1"

primrec
  pageIOMapCTSlot :: "page_invocation \<Rightarrow> machine_word"
where
  "pageIOMapCTSlot (PageIOMap v0 v1 v2 v3) = v1"

primrec
  pageUnmapCap :: "page_invocation \<Rightarrow> arch_capability"
where
  "pageUnmapCap (PageUnmap v0 v1) = v0"

primrec
  pageIOMapEntryPtr :: "page_invocation \<Rightarrow> machine_word"
where
  "pageIOMapEntryPtr (PageIOMap v0 v1 v2 v3) = v3"

primrec
  pageIOUnmapCap :: "page_invocation \<Rightarrow> capability"
where
  "pageIOUnmapCap (PageIOUnmap v0 v1) = v0"

primrec
  pageRemapEntries :: "page_invocation \<Rightarrow> (vmpage_entry * vmpage_entry_ptr)"
where
  "pageRemapEntries (PageRemap v0) = v0"

primrec
  pageMapASID :: "page_invocation \<Rightarrow> asid"
where
  "pageMapASID (PageMap v0 v1 v2 v3) = v0"

primrec
  pageIOMapCap :: "page_invocation \<Rightarrow> capability"
where
  "pageIOMapCap (PageIOMap v0 v1 v2 v3) = v0"

primrec
  pageGetBasePtr :: "page_invocation \<Rightarrow> machine_word"
where
  "pageGetBasePtr (PageGetAddr v0) = v0"

primrec
  pageIOMapEntry :: "page_invocation \<Rightarrow> iopte"
where
  "pageIOMapEntry (PageIOMap v0 v1 v2 v3) = v2"

primrec
  pageMapEntries :: "page_invocation \<Rightarrow> (vmpage_entry * vmpage_entry_ptr)"
where
  "pageMapEntries (PageMap v0 v1 v2 v3) = v3"

primrec
  pageMapCTSlot :: "page_invocation \<Rightarrow> machine_word"
where
  "pageMapCTSlot (PageMap v0 v1 v2 v3) = v2"

primrec
  pageIOUnmapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOUnmapCTSlot_update f (PageIOUnmap v0 v1) = PageIOUnmap v0 (f v1)"

primrec
  pageMapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageMapCap_update f (PageMap v0 v1 v2 v3) = PageMap v0 (f v1) v2 v3"

primrec
  pageUnmapCapSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageUnmapCapSlot_update f (PageUnmap v0 v1) = PageUnmap v0 (f v1)"

primrec
  pageIOMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOMapCTSlot_update f (PageIOMap v0 v1 v2 v3) = PageIOMap v0 (f v1) v2 v3"

primrec
  pageUnmapCap_update :: "(arch_capability \<Rightarrow> arch_capability) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageUnmapCap_update f (PageUnmap v0 v1) = PageUnmap (f v0) v1"

primrec
  pageIOMapEntryPtr_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOMapEntryPtr_update f (PageIOMap v0 v1 v2 v3) = PageIOMap v0 v1 v2 (f v3)"

primrec
  pageIOUnmapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOUnmapCap_update f (PageIOUnmap v0 v1) = PageIOUnmap (f v0) v1"

primrec
  pageRemapEntries_update :: "(((vmpage_entry * vmpage_entry_ptr)) \<Rightarrow> ((vmpage_entry * vmpage_entry_ptr))) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageRemapEntries_update f (PageRemap v0) = PageRemap (f v0)"

primrec
  pageMapASID_update :: "(asid \<Rightarrow> asid) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageMapASID_update f (PageMap v0 v1 v2 v3) = PageMap (f v0) v1 v2 v3"

primrec
  pageIOMapCap_update :: "(capability \<Rightarrow> capability) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOMapCap_update f (PageIOMap v0 v1 v2 v3) = PageIOMap (f v0) v1 v2 v3"

primrec
  pageGetBasePtr_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageGetBasePtr_update f (PageGetAddr v0) = PageGetAddr (f v0)"

primrec
  pageIOMapEntry_update :: "(iopte \<Rightarrow> iopte) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageIOMapEntry_update f (PageIOMap v0 v1 v2 v3) = PageIOMap v0 v1 (f v2) v3"

primrec
  pageMapEntries_update :: "(((vmpage_entry * vmpage_entry_ptr)) \<Rightarrow> ((vmpage_entry * vmpage_entry_ptr))) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageMapEntries_update f (PageMap v0 v1 v2 v3) = PageMap v0 v1 v2 (f v3)"

primrec
  pageMapCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> page_invocation \<Rightarrow> page_invocation"
where
  "pageMapCTSlot_update f (PageMap v0 v1 v2 v3) = PageMap v0 v1 (f v2) v3"

abbreviation (input)
  PageGetAddr_trans :: "(machine_word) \<Rightarrow> page_invocation" ("PageGetAddr'_ \<lparr> pageGetBasePtr= _ \<rparr>")
where
  "PageGetAddr_ \<lparr> pageGetBasePtr= v0 \<rparr> == PageGetAddr v0"

abbreviation (input)
  PageRemap_trans :: "((vmpage_entry * vmpage_entry_ptr)) \<Rightarrow> page_invocation" ("PageRemap'_ \<lparr> pageRemapEntries= _ \<rparr>")
where
  "PageRemap_ \<lparr> pageRemapEntries= v0 \<rparr> == PageRemap v0"

abbreviation (input)
  PageMap_trans :: "(asid) \<Rightarrow> (capability) \<Rightarrow> (machine_word) \<Rightarrow> ((vmpage_entry * vmpage_entry_ptr)) \<Rightarrow> page_invocation" ("PageMap'_ \<lparr> pageMapASID= _, pageMapCap= _, pageMapCTSlot= _, pageMapEntries= _ \<rparr>")
where
  "PageMap_ \<lparr> pageMapASID= v0, pageMapCap= v1, pageMapCTSlot= v2, pageMapEntries= v3 \<rparr> == PageMap v0 v1 v2 v3"

abbreviation (input)
  PageUnmap_trans :: "(arch_capability) \<Rightarrow> (machine_word) \<Rightarrow> page_invocation" ("PageUnmap'_ \<lparr> pageUnmapCap= _, pageUnmapCapSlot= _ \<rparr>")
where
  "PageUnmap_ \<lparr> pageUnmapCap= v0, pageUnmapCapSlot= v1 \<rparr> == PageUnmap v0 v1"

abbreviation (input)
  PageIOMap_trans :: "(capability) \<Rightarrow> (machine_word) \<Rightarrow> (iopte) \<Rightarrow> (machine_word) \<Rightarrow> page_invocation" ("PageIOMap'_ \<lparr> pageIOMapCap= _, pageIOMapCTSlot= _, pageIOMapEntry= _, pageIOMapEntryPtr= _ \<rparr>")
where
  "PageIOMap_ \<lparr> pageIOMapCap= v0, pageIOMapCTSlot= v1, pageIOMapEntry= v2, pageIOMapEntryPtr= v3 \<rparr> == PageIOMap v0 v1 v2 v3"

abbreviation (input)
  PageIOUnmap_trans :: "(capability) \<Rightarrow> (machine_word) \<Rightarrow> page_invocation" ("PageIOUnmap'_ \<lparr> pageIOUnmapCap= _, pageIOUnmapCTSlot= _ \<rparr>")
where
  "PageIOUnmap_ \<lparr> pageIOUnmapCap= v0, pageIOUnmapCTSlot= v1 \<rparr> == PageIOUnmap v0 v1"

definition
  isPageGetAddr :: "page_invocation \<Rightarrow> bool"
where
 "isPageGetAddr v \<equiv> case v of
    PageGetAddr v0 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageRemap :: "page_invocation \<Rightarrow> bool"
where
 "isPageRemap v \<equiv> case v of
    PageRemap v0 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageMap :: "page_invocation \<Rightarrow> bool"
where
 "isPageMap v \<equiv> case v of
    PageMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageUnmap :: "page_invocation \<Rightarrow> bool"
where
 "isPageUnmap v \<equiv> case v of
    PageUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageIOMap :: "page_invocation \<Rightarrow> bool"
where
 "isPageIOMap v \<equiv> case v of
    PageIOMap v0 v1 v2 v3 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isPageIOUnmap :: "page_invocation \<Rightarrow> bool"
where
 "isPageIOUnmap v \<equiv> case v of
    PageIOUnmap v0 v1 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype asidcontrol_invocation =
    MakePool machine_word machine_word machine_word asid

primrec
  makePoolSlot :: "asidcontrol_invocation \<Rightarrow> machine_word"
where
  "makePoolSlot (MakePool v0 v1 v2 v3) = v1"

primrec
  makePoolFrame :: "asidcontrol_invocation \<Rightarrow> machine_word"
where
  "makePoolFrame (MakePool v0 v1 v2 v3) = v0"

primrec
  makePoolBase :: "asidcontrol_invocation \<Rightarrow> asid"
where
  "makePoolBase (MakePool v0 v1 v2 v3) = v3"

primrec
  makePoolParent :: "asidcontrol_invocation \<Rightarrow> machine_word"
where
  "makePoolParent (MakePool v0 v1 v2 v3) = v2"

primrec
  makePoolSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> asidcontrol_invocation \<Rightarrow> asidcontrol_invocation"
where
  "makePoolSlot_update f (MakePool v0 v1 v2 v3) = MakePool v0 (f v1) v2 v3"

primrec
  makePoolFrame_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> asidcontrol_invocation \<Rightarrow> asidcontrol_invocation"
where
  "makePoolFrame_update f (MakePool v0 v1 v2 v3) = MakePool (f v0) v1 v2 v3"

primrec
  makePoolBase_update :: "(asid \<Rightarrow> asid) \<Rightarrow> asidcontrol_invocation \<Rightarrow> asidcontrol_invocation"
where
  "makePoolBase_update f (MakePool v0 v1 v2 v3) = MakePool v0 v1 v2 (f v3)"

primrec
  makePoolParent_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> asidcontrol_invocation \<Rightarrow> asidcontrol_invocation"
where
  "makePoolParent_update f (MakePool v0 v1 v2 v3) = MakePool v0 v1 (f v2) v3"

abbreviation (input)
  MakePool_trans :: "(machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (asid) \<Rightarrow> asidcontrol_invocation" ("MakePool'_ \<lparr> makePoolFrame= _, makePoolSlot= _, makePoolParent= _, makePoolBase= _ \<rparr>")
where
  "MakePool_ \<lparr> makePoolFrame= v0, makePoolSlot= v1, makePoolParent= v2, makePoolBase= v3 \<rparr> == MakePool v0 v1 v2 v3"

lemma makePoolSlot_makePoolSlot_update [simp]:
  "makePoolSlot (makePoolSlot_update f v) = f (makePoolSlot v)"
  by (cases v) simp

lemma makePoolSlot_makePoolFrame_update [simp]:
  "makePoolSlot (makePoolFrame_update f v) = makePoolSlot v"
  by (cases v) simp

lemma makePoolSlot_makePoolBase_update [simp]:
  "makePoolSlot (makePoolBase_update f v) = makePoolSlot v"
  by (cases v) simp

lemma makePoolSlot_makePoolParent_update [simp]:
  "makePoolSlot (makePoolParent_update f v) = makePoolSlot v"
  by (cases v) simp

lemma makePoolFrame_makePoolSlot_update [simp]:
  "makePoolFrame (makePoolSlot_update f v) = makePoolFrame v"
  by (cases v) simp

lemma makePoolFrame_makePoolFrame_update [simp]:
  "makePoolFrame (makePoolFrame_update f v) = f (makePoolFrame v)"
  by (cases v) simp

lemma makePoolFrame_makePoolBase_update [simp]:
  "makePoolFrame (makePoolBase_update f v) = makePoolFrame v"
  by (cases v) simp

lemma makePoolFrame_makePoolParent_update [simp]:
  "makePoolFrame (makePoolParent_update f v) = makePoolFrame v"
  by (cases v) simp

lemma makePoolBase_makePoolSlot_update [simp]:
  "makePoolBase (makePoolSlot_update f v) = makePoolBase v"
  by (cases v) simp

lemma makePoolBase_makePoolFrame_update [simp]:
  "makePoolBase (makePoolFrame_update f v) = makePoolBase v"
  by (cases v) simp

lemma makePoolBase_makePoolBase_update [simp]:
  "makePoolBase (makePoolBase_update f v) = f (makePoolBase v)"
  by (cases v) simp

lemma makePoolBase_makePoolParent_update [simp]:
  "makePoolBase (makePoolParent_update f v) = makePoolBase v"
  by (cases v) simp

lemma makePoolParent_makePoolSlot_update [simp]:
  "makePoolParent (makePoolSlot_update f v) = makePoolParent v"
  by (cases v) simp

lemma makePoolParent_makePoolFrame_update [simp]:
  "makePoolParent (makePoolFrame_update f v) = makePoolParent v"
  by (cases v) simp

lemma makePoolParent_makePoolBase_update [simp]:
  "makePoolParent (makePoolBase_update f v) = makePoolParent v"
  by (cases v) simp

lemma makePoolParent_makePoolParent_update [simp]:
  "makePoolParent (makePoolParent_update f v) = f (makePoolParent v)"
  by (cases v) simp

datatype asidpool_invocation =
    Assign asid machine_word machine_word

primrec
  assignASIDPool :: "asidpool_invocation \<Rightarrow> machine_word"
where
  "assignASIDPool (Assign v0 v1 v2) = v1"

primrec
  assignASIDCTSlot :: "asidpool_invocation \<Rightarrow> machine_word"
where
  "assignASIDCTSlot (Assign v0 v1 v2) = v2"

primrec
  assignASID :: "asidpool_invocation \<Rightarrow> asid"
where
  "assignASID (Assign v0 v1 v2) = v0"

primrec
  assignASIDPool_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> asidpool_invocation \<Rightarrow> asidpool_invocation"
where
  "assignASIDPool_update f (Assign v0 v1 v2) = Assign v0 (f v1) v2"

primrec
  assignASIDCTSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> asidpool_invocation \<Rightarrow> asidpool_invocation"
where
  "assignASIDCTSlot_update f (Assign v0 v1 v2) = Assign v0 v1 (f v2)"

primrec
  assignASID_update :: "(asid \<Rightarrow> asid) \<Rightarrow> asidpool_invocation \<Rightarrow> asidpool_invocation"
where
  "assignASID_update f (Assign v0 v1 v2) = Assign (f v0) v1 v2"

abbreviation (input)
  Assign_trans :: "(asid) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> asidpool_invocation" ("Assign'_ \<lparr> assignASID= _, assignASIDPool= _, assignASIDCTSlot= _ \<rparr>")
where
  "Assign_ \<lparr> assignASID= v0, assignASIDPool= v1, assignASIDCTSlot= v2 \<rparr> == Assign v0 v1 v2"

lemma assignASIDPool_assignASIDPool_update [simp]:
  "assignASIDPool (assignASIDPool_update f v) = f (assignASIDPool v)"
  by (cases v) simp

lemma assignASIDPool_assignASIDCTSlot_update [simp]:
  "assignASIDPool (assignASIDCTSlot_update f v) = assignASIDPool v"
  by (cases v) simp

lemma assignASIDPool_assignASID_update [simp]:
  "assignASIDPool (assignASID_update f v) = assignASIDPool v"
  by (cases v) simp

lemma assignASIDCTSlot_assignASIDPool_update [simp]:
  "assignASIDCTSlot (assignASIDPool_update f v) = assignASIDCTSlot v"
  by (cases v) simp

lemma assignASIDCTSlot_assignASIDCTSlot_update [simp]:
  "assignASIDCTSlot (assignASIDCTSlot_update f v) = f (assignASIDCTSlot v)"
  by (cases v) simp

lemma assignASIDCTSlot_assignASID_update [simp]:
  "assignASIDCTSlot (assignASID_update f v) = assignASIDCTSlot v"
  by (cases v) simp

lemma assignASID_assignASIDPool_update [simp]:
  "assignASID (assignASIDPool_update f v) = assignASID v"
  by (cases v) simp

lemma assignASID_assignASIDCTSlot_update [simp]:
  "assignASID (assignASIDCTSlot_update f v) = assignASID v"
  by (cases v) simp

lemma assignASID_assignASID_update [simp]:
  "assignASID (assignASID_update f v) = f (assignASID v)"
  by (cases v) simp

datatype ioport_invocation_data =
    IOPortIn8
  | IOPortIn16
  | IOPortIn32
  | IOPortOut8 word8
  | IOPortOut16 word16
  | IOPortOut32 word32

datatype ioport_invocation =
    IOPortInvocation ioport ioport_invocation_data

datatype invocation =
    InvokePDPT pdptinvocation
  | InvokePageDirectory page_directory_invocation
  | InvokePageTable page_table_invocation
  | InvokeIOPageTable iopage_table_invocation
  | InvokePage page_invocation
  | InvokeASIDControl asidcontrol_invocation
  | InvokeASIDPool asidpool_invocation
  | InvokeIOPort ioport_invocation

datatype irqcontrol_invocation =
    IssueIRQHandlerIOAPIC irq machine_word machine_word machine_word machine_word machine_word machine_word machine_word
  | IssueIRQHandlerMSI irq machine_word machine_word machine_word machine_word machine_word machine_word

primrec
  issueHandlerIOAPICPin :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICPin (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v4"

primrec
  issueHandlerIOAPICSlot :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICSlot (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v1"

primrec
  issueHandlerMSIPCIFunc :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSIPCIFunc (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v5"

primrec
  issueHandlerIOAPICLevel :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICLevel (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v5"

primrec
  issueHandlerMSISlot :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSISlot (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v1"

primrec
  issueHandlerMSIIRQ :: "irqcontrol_invocation \<Rightarrow> irq"
where
  "issueHandlerMSIIRQ (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v0"

primrec
  issueHandlerMSIHandle :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSIHandle (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v6"

primrec
  issueHandlerIOAPICControllerSlot :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICControllerSlot (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v2"

primrec
  issueHandlerIOAPICPolarity :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICPolarity (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v6"

primrec
  issueHandlerIOAPICIRQ :: "irqcontrol_invocation \<Rightarrow> irq"
where
  "issueHandlerIOAPICIRQ (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v0"

primrec
  issueHandlerMSIControllerSlot :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSIControllerSlot (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v2"

primrec
  issueHandlerMSIPCIDev :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSIPCIDev (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v4"

primrec
  issueHandlerMSIPCIBus :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerMSIPCIBus (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = v3"

primrec
  issueHandlerIOAPICVector :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICVector (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v7"

primrec
  issueHandlerIOAPICIOAPIC :: "irqcontrol_invocation \<Rightarrow> machine_word"
where
  "issueHandlerIOAPICIOAPIC (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = v3"

primrec
  issueHandlerIOAPICPin_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICPin_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 v2 v3 (f v4) v5 v6 v7"

primrec
  issueHandlerIOAPICSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICSlot_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 (f v1) v2 v3 v4 v5 v6 v7"

primrec
  issueHandlerMSIPCIFunc_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIPCIFunc_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 v1 v2 v3 v4 (f v5) v6"

primrec
  issueHandlerIOAPICLevel_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICLevel_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 (f v5) v6 v7"

primrec
  issueHandlerMSISlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSISlot_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 (f v1) v2 v3 v4 v5 v6"

primrec
  issueHandlerMSIIRQ_update :: "(irq \<Rightarrow> irq) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIIRQ_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI (f v0) v1 v2 v3 v4 v5 v6"

primrec
  issueHandlerMSIHandle_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIHandle_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 (f v6)"

primrec
  issueHandlerIOAPICControllerSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICControllerSlot_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 (f v2) v3 v4 v5 v6 v7"

primrec
  issueHandlerIOAPICPolarity_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICPolarity_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 (f v6) v7"

primrec
  issueHandlerIOAPICIRQ_update :: "(irq \<Rightarrow> irq) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICIRQ_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC (f v0) v1 v2 v3 v4 v5 v6 v7"

primrec
  issueHandlerMSIControllerSlot_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIControllerSlot_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 v1 (f v2) v3 v4 v5 v6"

primrec
  issueHandlerMSIPCIDev_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIPCIDev_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 v1 v2 v3 (f v4) v5 v6"

primrec
  issueHandlerMSIPCIBus_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerMSIPCIBus_update f (IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6) = IssueIRQHandlerMSI v0 v1 v2 (f v3) v4 v5 v6"

primrec
  issueHandlerIOAPICVector_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICVector_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 (f v7)"

primrec
  issueHandlerIOAPICIOAPIC_update :: "(machine_word \<Rightarrow> machine_word) \<Rightarrow> irqcontrol_invocation \<Rightarrow> irqcontrol_invocation"
where
  "issueHandlerIOAPICIOAPIC_update f (IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7) = IssueIRQHandlerIOAPIC v0 v1 v2 (f v3) v4 v5 v6 v7"

abbreviation (input)
  IssueIRQHandlerIOAPIC_trans :: "(irq) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> irqcontrol_invocation" ("IssueIRQHandlerIOAPIC'_ \<lparr> issueHandlerIOAPICIRQ= _, issueHandlerIOAPICSlot= _, issueHandlerIOAPICControllerSlot= _, issueHandlerIOAPICIOAPIC= _, issueHandlerIOAPICPin= _, issueHandlerIOAPICLevel= _, issueHandlerIOAPICPolarity= _, issueHandlerIOAPICVector= _ \<rparr>")
where
  "IssueIRQHandlerIOAPIC_ \<lparr> issueHandlerIOAPICIRQ= v0, issueHandlerIOAPICSlot= v1, issueHandlerIOAPICControllerSlot= v2, issueHandlerIOAPICIOAPIC= v3, issueHandlerIOAPICPin= v4, issueHandlerIOAPICLevel= v5, issueHandlerIOAPICPolarity= v6, issueHandlerIOAPICVector= v7 \<rparr> == IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7"

abbreviation (input)
  IssueIRQHandlerMSI_trans :: "(irq) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> (machine_word) \<Rightarrow> irqcontrol_invocation" ("IssueIRQHandlerMSI'_ \<lparr> issueHandlerMSIIRQ= _, issueHandlerMSISlot= _, issueHandlerMSIControllerSlot= _, issueHandlerMSIPCIBus= _, issueHandlerMSIPCIDev= _, issueHandlerMSIPCIFunc= _, issueHandlerMSIHandle= _ \<rparr>")
where
  "IssueIRQHandlerMSI_ \<lparr> issueHandlerMSIIRQ= v0, issueHandlerMSISlot= v1, issueHandlerMSIControllerSlot= v2, issueHandlerMSIPCIBus= v3, issueHandlerMSIPCIDev= v4, issueHandlerMSIPCIFunc= v5, issueHandlerMSIHandle= v6 \<rparr> == IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6"

definition
  isIssueIRQHandlerIOAPIC :: "irqcontrol_invocation \<Rightarrow> bool"
where
 "isIssueIRQHandlerIOAPIC v \<equiv> case v of
    IssueIRQHandlerIOAPIC v0 v1 v2 v3 v4 v5 v6 v7 \<Rightarrow> True
  | _ \<Rightarrow> False"

definition
  isIssueIRQHandlerMSI :: "irqcontrol_invocation \<Rightarrow> bool"
where
 "isIssueIRQHandlerMSI v \<equiv> case v of
    IssueIRQHandlerMSI v0 v1 v2 v3 v4 v5 v6 \<Rightarrow> True
  | _ \<Rightarrow> False"

datatype copy_register_sets =
    X64NoExtraRegisters

consts'
deriveCap :: "machine_word \<Rightarrow> arch_capability \<Rightarrow> ( syscall_error , arch_capability ) kernel_f"

consts'
ioSpaceGetDomainID :: "machine_word \<Rightarrow> word16"

consts'
ioSpaceGetPCIDevice :: "machine_word \<Rightarrow> ioasid option"

consts'
ioPortGetFirstPort :: "machine_word \<Rightarrow> word16"

consts'
ioPortGetLastPort :: "machine_word \<Rightarrow> word16"

consts'
updateCapData :: "bool \<Rightarrow> machine_word \<Rightarrow> arch_capability \<Rightarrow> capability"

consts'
maskCapRights :: "cap_rights \<Rightarrow> arch_capability \<Rightarrow> capability"

consts'
finaliseCap :: "arch_capability \<Rightarrow> bool \<Rightarrow> capability kernel"

consts'
resetMemMapping :: "arch_capability \<Rightarrow> arch_capability"

consts'
recycleCap :: "bool \<Rightarrow> arch_capability \<Rightarrow> arch_capability kernel"

consts'
hasRecycleRights :: "arch_capability \<Rightarrow> bool"

consts'
sameRegionAs :: "arch_capability \<Rightarrow> arch_capability \<Rightarrow> bool"

consts'
isPhysicalCap :: "arch_capability \<Rightarrow> bool"

consts'
sameObjectAs :: "arch_capability \<Rightarrow> arch_capability \<Rightarrow> bool"

consts'
createObject :: "object_type \<Rightarrow> machine_word \<Rightarrow> nat \<Rightarrow> bool \<Rightarrow> arch_capability kernel"

consts'
isIOCap :: "arch_capability \<Rightarrow> bool"

consts'
decodeInvocation :: "machine_word \<Rightarrow> machine_word list \<Rightarrow> cptr \<Rightarrow> machine_word \<Rightarrow> arch_capability \<Rightarrow> (capability * machine_word) list \<Rightarrow> ( syscall_error , ArchRetypeDecls_H.invocation ) kernel_f"

consts'
performInvocation :: "ArchRetypeDecls_H.invocation \<Rightarrow> machine_word list kernel_p"

consts'
capUntypedPtr :: "arch_capability \<Rightarrow> machine_word"

consts'
capUntypedSize :: "arch_capability \<Rightarrow> machine_word"


end (context X64)

end
