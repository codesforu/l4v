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
Arch specific object invocations
*)

chapter "x64 Object Invocations"

theory ArchInvocation_A
imports "../Structures_A"
begin

context Arch begin global_naming X64_A

text {* These datatypes encode the arguments to the various possible
x64-specific system calls. Selectors are defined for various fields
for convenience elsewhere. *}

datatype pdpt_invocation =
    PDPTMap cap cslot_ptr pml4e obj_ref
  | PDPTUnmap cap cslot_ptr

datatype page_directory_invocation =
    PageDirectoryMap cap cslot_ptr pdpte obj_ref
  | PageDirectoryUnmap cap cslot_ptr

datatype page_table_invocation = 
    PageTableMap cap cslot_ptr pde obj_ref
  | PageTableUnmap cap cslot_ptr

datatype asid_control_invocation = 
    MakePool obj_ref cslot_ptr cslot_ptr asid

datatype asid_pool_invocation = 
    Assign asid obj_ref cslot_ptr

datatype page_invocation
     = PageMap 
         (page_map_asid: asid)
         (page_map_cap: cap)
         (page_map_ct_slot: cslot_ptr)
         (page_map_entries: "vm_page_entry \<times> obj_ref")
     | PageRemap
         (page_remap_entries: "vm_page_entry \<times> obj_ref")
     | PageUnmap 
         (page_unmap_cap: arch_cap)
         (page_unmap_cap_slot: cslot_ptr)
     | PageIOMap 
         (page_iomap_cap: cap)
         (page_iomap_ct_clot: cslot_ptr)
         (page_iomap_asid: iopte)
         (page_iomap_entries: "obj_ref") (*FIXME: double check plz*)
     | PageGetAddr
         (page_get_paddr: obj_ref)

datatype io_port_invocation_data
  = IOPortIn8 | IOPortIn16 | IOPortIn32
  | IOPortOut8 "8 word" | IOPortOut16 "16 word" | IOPortOut32 "32 word"

datatype io_port_invocation = IOPortInvocation io_port io_port_invocation_data

datatype io_pt_invocation 
     = IOPageTableMapContext cap cslot_ptr iocte obj_ref
     | IOPageTableMap cap cslot_ptr iopte obj_ref
     | IOPageTableUnmap cap cslot_ptr

datatype arch_invocation
     = InvokePageTable page_table_invocation
     | InvokePageDirectory page_directory_invocation
     | InvokePDPT pdpt_invocation
     | InvokePage page_invocation
     | InvokeASIDControl asid_control_invocation
     | InvokeASIDPool asid_pool_invocation
     | InvokeIOPort io_port_invocation
     | InvokeIOPT io_pt_invocation

datatype arch_copy_register_sets =
    ArchDefaultExtraRegisters

datatype arch_irq_control_invocation
  = IssueIRQHandlerIOAPIC irq cslot_ptr cslot_ptr
      machine_word machine_word machine_word machine_word machine_word
  | IssueIRQHandlerMSI irq cslot_ptr cslot_ptr
      machine_word machine_word machine_word machine_word

end
end
