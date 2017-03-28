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
  Lemmas on arch get/set object etc
*)

theory ArchAcc_R
imports SubMonad_R
begin

context Arch begin global_naming X64_A (*FIXME: arch_split*)

lemma asid_pool_at_ko:
  "asid_pool_at p s \<Longrightarrow> \<exists>pool. ko_at (ArchObj (X64_A.ASIDPool pool)) p s"
  apply (clarsimp simp: obj_at_def a_type_def)
  apply (case_tac ko, simp_all split: if_split_asm)
  apply (rename_tac arch_kernel_obj)
  apply (case_tac arch_kernel_obj, auto split: if_split_asm)
  done


end

context begin interpretation Arch . (*FIXME: arch_split*)

declare if_cong[cong]

lemma corres_gets_asid:
  "corres (\<lambda>a c. a = c o ucast) \<top> \<top> (gets (x64_asid_table \<circ> arch_state)) (gets (x64KSASIDTable \<circ> ksArchState))"
  by (simp add: state_relation_def arch_state_relation_def)

lemma asid_low_bits [simp]:
  "asidLowBits = asid_low_bits"
  by (simp add: asid_low_bits_def asidLowBits_def)

lemma get_asid_pool_corres:
  "corres (\<lambda>p p'. p = inv ASIDPool p' o ucast)
          (asid_pool_at p) (asid_pool_at' p)
          (get_asid_pool p) (getObject p)"
  apply (simp add: getObject_def get_asid_pool_def get_object_def split_def)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
   apply (clarsimp simp: typ_at'_def ko_wp_at'_def)
   apply (case_tac ko; simp)
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all)[1]
   apply (clarsimp simp: lookupAround2_known1
                         projectKOs)
   apply (clarsimp simp: obj_at'_def projectKOs objBits_simps
                         archObjSize_def)
   apply (erule (1) ps_clear_lookupAround2)
     apply simp
    apply (erule is_aligned_no_overflow)
   apply simp
   apply (clarsimp simp add: objBits_simps archObjSize_def
                      split: option.split)
  apply (clarsimp simp: in_monad loadObject_default_def projectKOs)
  apply (simp add: bind_assoc exec_gets)
  apply (drule asid_pool_at_ko)
  apply (clarsimp simp: obj_at_def)
  apply (simp add: return_def)
  apply (simp add: in_magnitude_check objBits_simps
                   archObjSize_def pageBits_def)
  apply clarsimp
  apply (clarsimp simp: state_relation_def pspace_relation_def)
  apply (drule bspec, blast)
  apply (clarsimp simp: other_obj_relation_def asid_pool_relation_def)
  done

lemma aligned_distinct_obj_atI':
  "\<lbrakk> ksPSpace s x = Some ko; pspace_aligned' s;
      pspace_distinct' s; ko = injectKO v \<rbrakk>
      \<Longrightarrow> ko_at' v x s"
  apply (simp add: obj_at'_def projectKOs project_inject
                   pspace_distinct'_def pspace_aligned'_def)
  apply (drule bspec, erule domI)+
  apply simp
  done

lemmas aligned_distinct_asid_pool_atI'
    = aligned_distinct_obj_atI'[where 'a=asidpool,
                                simplified, OF _ _ _ refl]

lemma aligned_distinct_relation_asid_pool_atI'[elim]:
  "\<lbrakk> asid_pool_at p s; pspace_relation (kheap s) (ksPSpace s');
     pspace_aligned' s'; pspace_distinct' s' \<rbrakk>
        \<Longrightarrow> asid_pool_at' p s'"
  apply (drule asid_pool_at_ko)
  apply (clarsimp simp add: obj_at_def)
  apply (drule(1) pspace_relation_absD)
  apply (clarsimp simp: other_obj_relation_def)
  apply (simp split: Structures_H.kernel_object.split_asm
                     arch_kernel_object.split_asm)
  apply (drule(2) aligned_distinct_asid_pool_atI')
  apply (clarsimp simp: obj_at'_def typ_at'_def ko_wp_at'_def
                        projectKOs)
  done

lemma get_asid_pool_corres':
  "corres (\<lambda>p p'. p = inv ASIDPool p' o ucast)
          (asid_pool_at p) (pspace_aligned' and pspace_distinct')
          (get_asid_pool p) (getObject p)"
  apply (rule stronger_corres_guard_imp,
         rule get_asid_pool_corres)
   apply auto
  done

lemma storePML4E_cte_wp_at'[wp]:
  "\<lbrace>\<lambda>s. P (cte_wp_at' P' p s)\<rbrace>
     storePML4E ptr val
   \<lbrace>\<lambda>rv s. P (cte_wp_at' P' p s)\<rbrace>"
  apply (simp add: storePML4E_def)
  apply (wp setObject_cte_wp_at2'[where Q="\<top>"])
    apply (clarsimp simp: updateObject_default_def in_monad
                          projectKO_opts_defs projectKOs)
   apply (rule equals0I)
   apply (clarsimp simp: updateObject_default_def in_monad
                         projectKOs projectKO_opts_defs)
  apply simp
  done

lemma storePML4E_state_refs_of[wp]:
  "\<lbrace>\<lambda>s. P (state_refs_of' s)\<rbrace>
     storePML4E ptr val
   \<lbrace>\<lambda>rv s. P (state_refs_of' s)\<rbrace>"
  unfolding storePML4E_def
  by (wp setObject_state_refs_of_eq; clarsimp simp: updateObject_default_def in_monad projectKOs)

lemma storePDPTE_cte_wp_at'[wp]:
  "\<lbrace>\<lambda>s. P (cte_wp_at' P' p s)\<rbrace>
     storePDPTE ptr val
   \<lbrace>\<lambda>rv s. P (cte_wp_at' P' p s)\<rbrace>"
  apply (simp add: storePDPTE_def)
  apply (wp setObject_cte_wp_at2'[where Q="\<top>"])
    apply (clarsimp simp: updateObject_default_def in_monad
                          projectKO_opts_defs projectKOs)
   apply (rule equals0I)
   apply (clarsimp simp: updateObject_default_def in_monad
                         projectKOs projectKO_opts_defs)
  apply simp
  done

lemma storePDPTE_state_refs_of[wp]:
  "\<lbrace>\<lambda>s. P (state_refs_of' s)\<rbrace>
     storePDPTE ptr val
   \<lbrace>\<lambda>rv s. P (state_refs_of' s)\<rbrace>"
  unfolding storePDPTE_def
  by (wp setObject_state_refs_of_eq; clarsimp simp: updateObject_default_def in_monad projectKOs)

lemma storePDE_cte_wp_at'[wp]:
  "\<lbrace>\<lambda>s. P (cte_wp_at' P' p s)\<rbrace>
     storePDE ptr val
   \<lbrace>\<lambda>rv s. P (cte_wp_at' P' p s)\<rbrace>"
  apply (simp add: storePDE_def)
  apply (wp setObject_cte_wp_at2'[where Q="\<top>"])
    apply (clarsimp simp: updateObject_default_def in_monad
                          projectKO_opts_defs projectKOs)
   apply (rule equals0I)
   apply (clarsimp simp: updateObject_default_def in_monad
                         projectKOs projectKO_opts_defs)
  apply simp
  done

lemma storePDE_state_refs_of[wp]:
  "\<lbrace>\<lambda>s. P (state_refs_of' s)\<rbrace>
     storePDE ptr val
   \<lbrace>\<lambda>rv s. P (state_refs_of' s)\<rbrace>"
  unfolding storePDE_def
  by (wp setObject_state_refs_of_eq; clarsimp simp: updateObject_default_def in_monad projectKOs)

lemma storePTE_cte_wp_at'[wp]:
  "\<lbrace>\<lambda>s. P (cte_wp_at' P' p s)\<rbrace>
     storePTE ptr val
   \<lbrace>\<lambda>rv s. P (cte_wp_at' P' p s)\<rbrace>"
  apply (simp add: storePTE_def)
  apply (wp setObject_cte_wp_at2'[where Q="\<top>"])
    apply (clarsimp simp: updateObject_default_def in_monad
                          projectKO_opts_defs projectKOs)
   apply (rule equals0I)
   apply (clarsimp simp: updateObject_default_def in_monad
                         projectKOs projectKO_opts_defs)
  apply simp
  done

lemma storePTE_state_refs_of[wp]:
  "\<lbrace>\<lambda>s. P (state_refs_of' s)\<rbrace>
     storePTE ptr val
   \<lbrace>\<lambda>rv s. P (state_refs_of' s)\<rbrace>"
  unfolding storePTE_def
  apply (wp setObject_state_refs_of_eq;
         clarsimp simp: updateObject_default_def in_monad
                        projectKOs)
  done

crunch cte_wp_at'[wp]: setIRQState "\<lambda>s. P (cte_wp_at' P' p s)"
crunch inv[wp]: getIRQSlot "P"

lemma set_asid_pool_corres:
  "a = inv ASIDPool a' o ucast \<Longrightarrow>
  corres dc (asid_pool_at p and valid_etcbs) (asid_pool_at' p)
            (set_asid_pool p a) (setObject p a')"
  apply (simp add: set_asid_pool_def update_object_def)
  apply (rule corres_symb_exec_l)
     apply (rule corres_symb_exec_l)
        apply (rule corres_guard_imp)
          apply (rule set_other_obj_corres [where P="\<lambda>ko::asidpool. True"])
                apply simp
               apply (clarsimp simp: obj_at'_def projectKOs)
               apply (erule map_to_ctes_upd_other, simp, simp)
              apply (simp add: a_type_def is_other_obj_relation_type_def)
             apply (simp add: objBits_simps archObjSize_def)
            apply simp
           apply (simp add: objBits_simps archObjSize_def pageBits_def)
          apply (simp add: other_obj_relation_def asid_pool_relation_def)
         apply assumption
        apply (simp add: typ_at'_def obj_at'_def ko_wp_at'_def projectKOs)
        apply clarsimp
        apply (case_tac ko; simp)
        apply (rename_tac arch_kernel_object)
        apply (case_tac arch_kernel_object; simp)
       prefer 5
       apply (rule get_object_sp)
      apply (clarsimp simp: obj_at_def exs_valid_def assert_def a_type_def return_def fail_def)
      apply (auto split: Structures_A.kernel_object.split_asm arch_kernel_obj.split_asm if_split_asm)[1]
     apply wp
     apply (clarsimp simp: obj_at_def a_type_def)
     apply (auto split: Structures_A.kernel_object.split_asm arch_kernel_obj.split_asm if_split_asm)[1]
    apply (rule no_fail_pre, wp)
    apply (clarsimp simp: simp: obj_at_def a_type_def)
    apply (auto split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)[1]
   apply (clarsimp simp: obj_at_def exs_valid_def get_object_def exec_gets)
   apply (simp add: return_def)
  apply (rule no_fail_pre, wp)
  apply (clarsimp simp add: obj_at_def)
  done

lemma set_asid_pool_corres':
  "a = inv ASIDPool a' o ucast \<Longrightarrow>
  corres dc (asid_pool_at p and valid_etcbs) (pspace_aligned' and pspace_distinct')
            (set_asid_pool p a) (setObject p a')"
  apply (rule stronger_corres_guard_imp,
         erule set_asid_pool_corres)
   apply auto
  done

lemma mask_pd_bits_inner_beauty:
  "is_aligned p word_size_bits \<Longrightarrow>
  (p && ~~ mask pd_bits) + (ucast ((ucast (p && mask pd_bits >> word_size_bits)) :: 9 word) << word_size_bits) = (p :: machine_word)"
  by (rule mask_split_aligned; simp add: bit_simps)

lemma get_pde_corres:
  "corres (pde_relation') (pde_at p) (pde_at' p)
     (get_pde p) (getObject p)"
  apply (simp add: getObject_def get_pde_def get_pd_def get_object_def split_def bind_assoc)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
   apply (clarsimp simp: ko_wp_at'_def typ_at'_def lookupAround2_known1)
   apply (case_tac ko; simp)
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object; simp add: projectKOs)
   apply (clarsimp simp: objBits_def cong: option.case_cong)
   apply (erule (1) ps_clear_lookupAround2)
     apply simp
    apply (erule is_aligned_no_overflow)
    apply (simp add: objBits_simps archObjSize_def word_bits_def)
   apply simp
  apply (clarsimp simp: in_monad loadObject_default_def projectKOs)
  apply (simp add: bind_assoc exec_gets)
  apply (clarsimp simp: pde_at_def obj_at_def)
  apply (clarsimp simp add: a_type_def return_def
                  split: if_split_asm Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (clarsimp simp: typ_at'_def ko_wp_at'_def)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def)
  apply (clarsimp simp: bind_def)
  apply (clarsimp simp: state_relation_def pspace_relation_def)
  apply (drule bspec, blast)
  apply (clarsimp simp: other_obj_relation_def pde_relation_def)
  apply (erule_tac x="(ucast (p && mask pd_bits >> word_size_bits))" in allE)
  by (clarsimp simp:  mask_pd_bits_inner_beauty[simplified bit_simps] bit_simps)

lemmas aligned_distinct_pde_atI'
    = aligned_distinct_obj_atI'[where 'a=pde,
                                simplified, OF _ _ _ refl]

lemma aligned_distinct_relation_pde_atI'[elim]:
  "\<lbrakk> pde_at p s; pspace_relation (kheap s) (ksPSpace s');
     pspace_aligned' s'; pspace_distinct' s' \<rbrakk>
        \<Longrightarrow> pde_at' p s'"
  apply (clarsimp simp add: pde_at_def obj_at_def a_type_def)
  apply (simp split: Structures_A.kernel_object.split_asm
                     if_split_asm arch_kernel_obj.split_asm)
  apply (drule(1) pspace_relation_absD)
  apply (clarsimp simp: other_obj_relation_def)
  apply (drule_tac x="ucast ((p && mask pd_bits) >> word_size_bits)"
                in spec)
  apply (subst(asm) ucast_ucast_len)
   apply (rule shiftr_less_t2n)
   apply (rule less_le_trans, rule and_mask_less_size)
    apply (simp add: bit_simps word_size)
   apply (simp add: bit_simps)
  apply (simp add: shiftr_shiftl1)
  apply (subst(asm) is_aligned_neg_mask_eq[where n=word_size_bits])
   apply (simp add: bit_simps, erule is_aligned_andI1)
  apply (subst(asm) add.commute,
         subst(asm) word_plus_and_or_coroll2)
  apply (clarsimp simp: pde_relation_def)
  apply (drule(2) aligned_distinct_pde_atI')
  apply (clarsimp simp: obj_at'_def typ_at'_def ko_wp_at'_def
                        projectKOs)
  done

lemma pde_relation_alignedD:
  "\<lbrakk> kheap s (p && ~~ mask pd_bits) = Some (ArchObj (PageDirectory pd));
     pspace_relation (kheap s) (ksPSpace s');
     ksPSpace s' ((p && ~~ mask pd_bits) + (ucast x << word_size_bits)) = Some (KOArch (KOPDE pde))\<rbrakk>
     \<Longrightarrow> pde_relation' (pd x) pde"
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec,blast)
  apply (clarsimp simp:pde_relation_def)
  apply (drule_tac x = x in spec)
  apply (clarsimp split:X64_H.pde.splits)
  done

lemma get_pde_corres':
  "corres (pde_relation') (pde_at p)
     (pspace_aligned' and pspace_distinct')
     (get_pde p) (getObject p)"
  apply (rule stronger_corres_guard_imp,
         rule get_pde_corres)
   apply auto[1]
  apply clarsimp
  apply (rule aligned_distinct_relation_pde_atI')
   apply (simp add:state_relation_def)+
  done

lemma mask_pt_bits_inner_beauty:
  "is_aligned p word_size_bits \<Longrightarrow>
  (p && ~~ mask pt_bits) + (ucast ((ucast (p && mask pt_bits >> word_size_bits)) :: 9 word) << word_size_bits) = (p::machine_word)"
  by (rule mask_split_aligned; simp add: bit_simps)

lemma get_pte_corres:
  "corres (pte_relation') (pte_at p) (pte_at' p)
     (get_pte p) (getObject p)"
  apply (simp add: getObject_def get_pte_def get_pt_def get_object_def split_def bind_assoc)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
   apply (clarsimp simp: ko_wp_at'_def typ_at'_def lookupAround2_known1)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (clarsimp simp: objBits_def cong: option.case_cong)
   apply (erule (1) ps_clear_lookupAround2)
     apply simp
    apply (erule is_aligned_no_overflow)
    apply (simp add: objBits_simps archObjSize_def word_bits_def)
   apply simp
  apply (clarsimp simp: in_monad loadObject_default_def projectKOs)
  apply (simp add: bind_assoc exec_gets)
  apply (clarsimp simp: obj_at_def pte_at_def)
  apply (clarsimp simp add: a_type_def return_def
                  split: if_split_asm Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (clarsimp simp: typ_at'_def ko_wp_at'_def)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def)
  apply (clarsimp simp: bind_def)
  apply (clarsimp simp: state_relation_def pspace_relation_def)
  apply (drule bspec, blast)
  apply (clarsimp simp: other_obj_relation_def pte_relation_def)
  apply (erule_tac x="(ucast (p && mask pt_bits >> word_size_bits))" in allE)
  apply (clarsimp simp: mask_pt_bits_inner_beauty[simplified bit_simps] bit_simps
                        obj_at_def)
  done

lemma pte_relation_alignedD:
  "\<lbrakk> kheap s (p && ~~ mask pt_bits) = Some (ArchObj (PageTable pt));
     pspace_relation (kheap s) (ksPSpace s');
     ksPSpace s' ((p && ~~ mask pt_bits) + (ucast x << word_size_bits)) = Some (KOArch (KOPTE pte))\<rbrakk>
     \<Longrightarrow> pte_relation' (pt x) pte"
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec,blast)
  apply (clarsimp simp:pte_relation_def)
  apply (drule_tac x = x in spec)
  apply clarsimp
  done

lemmas aligned_distinct_pte_atI'
    = aligned_distinct_obj_atI'[where 'a=pte,
                                simplified, OF _ _ _ refl]

lemma aligned_distinct_relation_pte_atI'[elim]:
  "\<lbrakk> pte_at p s; pspace_relation (kheap s) (ksPSpace s');
     pspace_aligned' s'; pspace_distinct' s' \<rbrakk>
        \<Longrightarrow> pte_at' p s'"
  apply (clarsimp simp add: pte_at_def obj_at_def a_type_def)
  apply (simp split: Structures_A.kernel_object.split_asm
                     if_split_asm arch_kernel_obj.split_asm)
  apply (drule(1) pspace_relation_absD)
  apply (clarsimp simp: other_obj_relation_def)
  apply (drule_tac x="ucast ((p && mask pt_bits) >> word_size_bits)"
                in spec)
  apply (subst(asm) ucast_ucast_len)
   apply (rule shiftr_less_t2n)
   apply (rule less_le_trans, rule and_mask_less_size)
    apply (simp add: word_size bit_simps)
   apply (simp add: bit_simps)
  apply (simp add: shiftr_shiftl1)
  apply (subst(asm) is_aligned_neg_mask_eq[where n=word_size_bits])
   apply (simp add: bit_simps; erule is_aligned_andI1)
  apply (subst(asm) add.commute,
         subst(asm) word_plus_and_or_coroll2)
  apply (clarsimp simp: pte_relation_def)
  apply (drule(2) aligned_distinct_pte_atI')
  apply (clarsimp simp: obj_at'_def typ_at'_def ko_wp_at'_def
                        projectKOs)
  done

lemma get_pte_corres':
  "corres (pte_relation') (pte_at p)
     (pspace_aligned' and pspace_distinct')
     (get_pte p) (getObject p)"
  apply (rule stronger_corres_guard_imp,
         rule get_pte_corres)
   apply auto[1]
  apply clarsimp
  apply (rule aligned_distinct_relation_pte_atI')
   apply (simp add:state_relation_def)+
  done

lemma mask_pdpt_bits_inner_beauty:
  "is_aligned p word_size_bits \<Longrightarrow>
  (p && ~~ mask pdpt_bits) + (ucast ((ucast (p && mask pdpt_bits >> word_size_bits)) :: 9 word) << word_size_bits) = (p::machine_word)"
  by (rule mask_split_aligned; simp add: bit_simps)

lemma get_pdpte_corres:
  "corres (pdpte_relation') (pdpte_at p) (pdpte_at' p)
     (get_pdpte p) (getObject p)"
  apply (simp add: getObject_def get_pdpte_def get_pdpt_def get_object_def split_def bind_assoc)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
   apply (clarsimp simp: ko_wp_at'_def typ_at'_def lookupAround2_known1)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (clarsimp simp: objBits_def cong: option.case_cong)
   apply (erule (1) ps_clear_lookupAround2)
     apply simp
    apply (erule is_aligned_no_overflow)
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply simp
  apply (clarsimp simp: in_monad loadObject_default_def projectKOs)
  apply (simp add: bind_assoc exec_gets)
  apply (clarsimp simp: obj_at_def pdpte_at_def)
  apply (clarsimp simp add: a_type_def return_def
                  split: if_split_asm Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (clarsimp simp: typ_at'_def ko_wp_at'_def)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def)
  apply (clarsimp simp: bind_def)
  apply (clarsimp simp: state_relation_def pspace_relation_def)
  apply (drule bspec, blast)
  apply (clarsimp simp: other_obj_relation_def pdpte_relation_def)
  apply (erule_tac x="(ucast (p && mask pdpt_bits >> word_size_bits))" in allE)
  apply (clarsimp simp: mask_pt_bits_inner_beauty[simplified bit_simps] bit_simps
                        obj_at_def)
  done

lemma pdpte_relation_alignedD:
  "\<lbrakk> kheap s (p && ~~ mask pdpt_bits) = Some (ArchObj (PDPointerTable pt));
     pspace_relation (kheap s) (ksPSpace s');
     ksPSpace s' ((p && ~~ mask pdpt_bits) + (ucast x << word_size_bits)) = Some (KOArch (KOPDPTE pdpte))\<rbrakk>
     \<Longrightarrow> pdpte_relation' (pt x) pdpte"
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec,blast)
  apply (clarsimp simp:pdpte_relation_def)
  apply (drule_tac x = x in spec)
  apply clarsimp
  done

lemmas aligned_distinct_pdpte_atI'
    = aligned_distinct_obj_atI'[where 'a=pdpte,
                                simplified, OF _ _ _ refl]

lemma aligned_distinct_relation_pdpte_atI'[elim]:
  "\<lbrakk> pdpte_at p s; pspace_relation (kheap s) (ksPSpace s');
     pspace_aligned' s'; pspace_distinct' s' \<rbrakk>
        \<Longrightarrow> pdpte_at' p s'"
  apply (clarsimp simp add: pdpte_at_def obj_at_def a_type_def)
  apply (simp split: Structures_A.kernel_object.split_asm
                     if_split_asm arch_kernel_obj.split_asm)
  apply (drule(1) pspace_relation_absD)
  apply (clarsimp simp: other_obj_relation_def)
  apply (drule_tac x="ucast ((p && mask pdpt_bits) >> word_size_bits)"
                in spec)
  apply (subst(asm) ucast_ucast_len)
   apply (rule shiftr_less_t2n)
   apply (rule less_le_trans, rule and_mask_less_size)
    apply (simp add: word_size bit_simps)
   apply (simp add: bit_simps)
  apply (simp add: shiftr_shiftl1)
  apply (subst(asm) is_aligned_neg_mask_eq[where n=word_size_bits])
   apply (simp add: bit_simps; erule is_aligned_andI1)
  apply (subst(asm) add.commute,
         subst(asm) word_plus_and_or_coroll2)
  apply (clarsimp simp: pdpte_relation_def)
  apply (drule(2) aligned_distinct_pdpte_atI')
  apply (clarsimp simp: obj_at'_def typ_at'_def ko_wp_at'_def
                        projectKOs)
  done

lemma get_pdpte_corres':
  "corres (pdpte_relation') (pdpte_at p)
     (pspace_aligned' and pspace_distinct')
     (get_pdpte p) (getObject p)"
  apply (rule stronger_corres_guard_imp,
         rule get_pdpte_corres)
   apply auto[1]
  apply clarsimp
  apply (rule aligned_distinct_relation_pdpte_atI')
   apply (simp add:state_relation_def)+
  done

lemma mask_pml4_bits_inner_beauty:
  "is_aligned p word_size_bits \<Longrightarrow>
  (p && ~~ mask pml4_bits) + (ucast ((ucast (p && mask pml4_bits >> word_size_bits)) :: 9 word) << word_size_bits) = (p::machine_word)"
  by (rule mask_split_aligned; simp add: bit_simps)

lemma get_pml4e_corres:
  "corres (pml4e_relation') (pml4e_at p) (pml4e_at' p)
     (get_pml4e p) (getObject p)"
  apply (simp add: getObject_def get_pml4e_def get_pml4_def get_object_def split_def bind_assoc)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
   apply (clarsimp simp: ko_wp_at'_def typ_at'_def lookupAround2_known1)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (clarsimp simp: objBits_def cong: option.case_cong)
   apply (erule (1) ps_clear_lookupAround2)
     apply simp
    apply (erule is_aligned_no_overflow)
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply simp
  apply (clarsimp simp: in_monad loadObject_default_def projectKOs)
  apply (simp add: bind_assoc exec_gets)
  apply (clarsimp simp: obj_at_def pml4e_at_def)
  apply (clarsimp simp add: a_type_def return_def
                  split: if_split_asm Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (clarsimp simp: typ_at'_def ko_wp_at'_def)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def)
  apply (clarsimp simp: bind_def)
  apply (clarsimp simp: state_relation_def pspace_relation_def)
  apply (drule bspec, blast)
  apply (clarsimp simp: other_obj_relation_def pml4e_relation_def)
  apply (erule_tac x="(ucast (p && mask pml4_bits >> word_size_bits))" in allE)
  apply (clarsimp simp: mask_pt_bits_inner_beauty[simplified bit_simps] bit_simps
                        obj_at_def)
  done

lemma pml4e_relation_alignedD:
  "\<lbrakk> kheap s (p && ~~ mask pml4_bits) = Some (ArchObj (PageMapL4 pt));
     pspace_relation (kheap s) (ksPSpace s');
     ksPSpace s' ((p && ~~ mask pml4_bits) + (ucast x << word_size_bits)) = Some (KOArch (KOPML4E pml4e))\<rbrakk>
     \<Longrightarrow> pml4e_relation' (pt x) pml4e"
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec,blast)
  apply (clarsimp simp:pml4e_relation_def)
  apply (drule_tac x = x in spec)
  apply clarsimp
  done

lemmas aligned_distinct_pml4e_atI'
    = aligned_distinct_obj_atI'[where 'a=pml4e,
                                simplified, OF _ _ _ refl]

lemma aligned_distinct_relation_pml4e_atI'[elim]:
  "\<lbrakk> pml4e_at p s; pspace_relation (kheap s) (ksPSpace s');
     pspace_aligned' s'; pspace_distinct' s' \<rbrakk>
        \<Longrightarrow> pml4e_at' p s'"
  apply (clarsimp simp add: pml4e_at_def obj_at_def a_type_def)
  apply (simp split: Structures_A.kernel_object.split_asm
                     if_split_asm arch_kernel_obj.split_asm)
  apply (drule(1) pspace_relation_absD)
  apply (clarsimp simp: other_obj_relation_def)
  apply (drule_tac x="ucast ((p && mask pml4_bits) >> word_size_bits)"
                in spec)
  apply (subst(asm) ucast_ucast_len)
   apply (rule shiftr_less_t2n)
   apply (rule less_le_trans, rule and_mask_less_size)
    apply (simp add: word_size bit_simps)
   apply (simp add: bit_simps)
  apply (simp add: shiftr_shiftl1)
  apply (subst(asm) is_aligned_neg_mask_eq[where n=word_size_bits])
   apply (simp add: bit_simps; erule is_aligned_andI1)
  apply (subst(asm) add.commute,
         subst(asm) word_plus_and_or_coroll2)
  apply (clarsimp simp: pml4e_relation_def)
  apply (drule(2) aligned_distinct_pml4e_atI')
  apply (clarsimp simp: obj_at'_def typ_at'_def ko_wp_at'_def
                        projectKOs)
  done

lemma get_pml4e_corres':
  "corres (pml4e_relation') (pml4e_at p)
     (pspace_aligned' and pspace_distinct')
     (get_pml4e p) (getObject p)"
  apply (rule stronger_corres_guard_imp,
         rule get_pml4e_corres)
   apply auto[1]
  apply clarsimp
  apply (rule aligned_distinct_relation_pml4e_atI')
   apply (simp add:state_relation_def)+
  done

(* FIXME: move *)
lemma table_size_slot_eq:
  "((p::machine_word) && ~~ mask table_size) + (ucast x << word_size_bits) = p \<Longrightarrow>
    (x::9 word) = ucast (p && mask table_size >> word_size_bits)"
  apply (clarsimp simp: bit_simps mask_def)
  apply word_bitwise
  apply clarsimp
  done

lemmas pd_bits_slot_eq = table_size_slot_eq[folded pd_bits_def]
lemmas pt_bits_slot_eq = table_size_slot_eq[folded pt_bits_def]
lemmas pdpt_bits_slot_eq = table_size_slot_eq[folded pdpt_bits_def]
lemmas pml4_bits_slot_eq = table_size_slot_eq[folded pml4_bits_def]

lemma more_pd_inner_beauty:
  fixes x :: "9 word"
  fixes p :: machine_word
  assumes x: "x \<noteq> ucast (p && mask pd_bits >> word_size_bits)"
  shows "(p && ~~ mask pd_bits) + (ucast x << word_size_bits) = p \<Longrightarrow> False"
  by (rule mask_split_aligned_neg[OF _ _ x]; simp add: bit_simps)

-- "set_other_obj_corres unfortunately doesn't work here"
lemma set_pd_corres:
  "pde_relation' pde pde' \<Longrightarrow>
         corres dc  (ko_at (ArchObj (PageDirectory pd)) (p && ~~ mask pd_bits)
                     and pspace_aligned and valid_etcbs)
                    (pde_at' p)
          (set_pd (p && ~~ mask pd_bits) (pd(ucast (p && mask pd_bits >> word_size_bits) := pde)))
          (setObject p pde')"
  apply (simp add: set_pd_def get_object_def bind_assoc update_object_def)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
    apply simp
   apply (clarsimp simp: obj_at'_def ko_wp_at'_def typ_at'_def lookupAround2_known1 projectKOs)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply (clarsimp simp: setObject_def in_monad split_def updateObject_default_def projectKOs)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def a_type_simps)
  apply (clarsimp simp: obj_at_def exec_gets a_type_simps)
  apply (clarsimp simp: set_object_def bind_assoc exec_get)
  apply (clarsimp simp: put_def)
  apply (fold word_size_bits_def)
  apply (clarsimp simp: state_relation_def mask_pd_bits_inner_beauty)
  apply (rule conjI)
   apply (clarsimp simp: pspace_relation_def split del: if_split)
   apply (rule conjI)
    apply (subst pspace_dom_update, assumption)
     apply (simp add: a_type_def)
    apply (auto simp: dom_def)[1]
   apply (rule conjI)
    apply (drule bspec, blast)
    apply clarsimp
    apply (drule_tac x = x in spec)
    apply (clarsimp simp: pde_relation_def mask_pd_bits_inner_beauty
                   dest!: more_pd_inner_beauty)
   apply (rule ballI)
   apply (drule (1) bspec)
   apply clarsimp
   apply (rule conjI)
    apply (clarsimp simp: pde_relation_def mask_pd_bits_inner_beauty
                   dest!: more_pd_inner_beauty)
   apply clarsimp
   apply (drule bspec, assumption)
   apply clarsimp
   apply (erule (1) obj_relation_cutsE)
       apply simp
      apply simp
     apply clarsimp
     apply (frule (1) pspace_alignedD)
     apply (drule_tac p=x in pspace_alignedD, assumption)
     apply simp
     apply (drule mask_alignment_ugliness)
        apply (simp add: pd_bits_def pageBits_def)
       apply (simp add: pd_bits_def pageBits_def)
      apply clarsimp
      apply (clarsimp simp: nth_ucast nth_shiftl)
      apply (drule test_bit_size)
      apply (clarsimp simp: word_size bit_simps)
      apply arith
     apply ((simp split: if_split_asm)+)[4]
   apply (simp add: other_obj_relation_def
               split: Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (rule conjI)
   apply (clarsimp simp: ekheap_relation_def pspace_relation_def)
   apply (drule(1) ekheap_kheap_dom)
   apply clarsimp
   apply (drule_tac x=p in bspec, erule domI)
   apply (simp add: other_obj_relation_def
           split: Structures_A.kernel_object.splits)
  apply (rule conjI)
   apply (clarsimp simp add: ghost_relation_def)
   apply (erule_tac x="p && ~~ mask pd_bits" in allE)+
   apply fastforce
  apply (simp add: map_to_ctes_upd_other)
  apply (simp add: fun_upd_def)
  apply (simp add: caps_of_state_after_update obj_at_def swp_cte_at_caps_of)
  done

lemma more_pt_inner_beauty:
  fixes x :: "9 word"
  fixes p :: machine_word
  assumes x: "x \<noteq> ucast (p && mask pt_bits >> word_size_bits)"
  shows "(p && ~~ mask pt_bits) + (ucast x << word_size_bits) = p \<Longrightarrow> False"
  by (rule mask_split_aligned_neg[OF _ _ x]; simp add: bit_simps)

-- "set_other_obj_corres unfortunately doesn't work here"
lemma set_pt_corres:
  "pte_relation' pte pte' \<Longrightarrow>
         corres dc  (ko_at (ArchObj (PageTable pt)) (p && ~~ mask pt_bits)
                     and pspace_aligned and valid_etcbs)
                    (pte_at' p)
          (set_pt (p && ~~ mask pt_bits) (pt(ucast (p && mask pt_bits >> word_size_bits) := pte)))
          (setObject p pte')"
  apply (simp add: set_pt_def get_object_def bind_assoc update_object_def)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
    apply simp
   apply (clarsimp simp: obj_at'_def ko_wp_at'_def typ_at'_def lookupAround2_known1 projectKOs)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply (clarsimp simp: setObject_def in_monad split_def updateObject_default_def projectKOs)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def a_type_simps)
  apply (clarsimp simp: obj_at_def exec_gets a_type_simps)
  apply (clarsimp simp: set_object_def bind_assoc exec_get)
  apply (clarsimp simp: put_def)
  apply (fold word_size_bits_def)
  apply (clarsimp simp: state_relation_def mask_pt_bits_inner_beauty)
  apply (rule conjI)
   apply (clarsimp simp: pspace_relation_def split del: if_split)
   apply (rule conjI)
    apply (subst pspace_dom_update, assumption)
     apply (simp add: a_type_def)
    apply (auto simp: dom_def)[1]
   apply (rule conjI)
    apply (drule bspec, blast)
    apply clarsimp
    apply (drule_tac x = x in spec)
    apply (clarsimp simp: pte_relation_def mask_pt_bits_inner_beauty
                   dest!: more_pt_inner_beauty)
   apply (rule ballI)
   apply (drule (1) bspec)
   apply clarsimp
   apply (rule conjI)
    apply (clarsimp simp: pte_relation_def mask_pt_bits_inner_beauty
                   dest!: more_pt_inner_beauty)
   apply clarsimp
   apply (drule bspec, assumption)
   apply clarsimp
   apply (erule (1) obj_relation_cutsE)
       apply simp
      apply simp
     apply clarsimp
     apply (frule (1) pspace_alignedD)
     apply (drule_tac p=x in pspace_alignedD, assumption)
     apply simp
     apply (drule mask_alignment_ugliness)
        apply (simp add: pt_bits_def pageBits_def)
       apply (simp add: pt_bits_def pageBits_def)
      apply clarsimp
      apply (clarsimp simp: nth_ucast nth_shiftl)
      apply (drule test_bit_size)
      apply (clarsimp simp: word_size bit_simps)
      apply arith
     apply ((simp split: if_split_asm)+)[5]
   apply (simp add: other_obj_relation_def
               split: Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (rule conjI)
   apply (clarsimp simp: ekheap_relation_def pspace_relation_def)
   apply (drule(1) ekheap_kheap_dom)
   apply clarsimp
   apply (drule_tac x=p in bspec, erule domI)
   apply (simp add: other_obj_relation_def
           split: Structures_A.kernel_object.splits)
  apply (rule conjI)
   apply (clarsimp simp add: ghost_relation_def)
   apply (erule_tac x="p && ~~ mask pt_bits" in allE)+
   apply fastforce
  apply (simp add: map_to_ctes_upd_other)
  apply (simp add: fun_upd_def)
  apply (simp add: caps_of_state_after_update obj_at_def swp_cte_at_caps_of)
  done

lemma more_pdpt_inner_beauty:
  fixes x :: "9 word"
  fixes p :: machine_word
  assumes x: "x \<noteq> ucast (p && mask pdpt_bits >> word_size_bits)"
  shows "(p && ~~ mask pdpt_bits) + (ucast x << word_size_bits) = p \<Longrightarrow> False"
  by (rule mask_split_aligned_neg[OF _ _ x]; simp add: bit_simps)

-- "set_other_obj_corres unfortunately doesn't work here"
lemma set_pdpt_corres:
  "pdpte_relation' pdpte pdpte' \<Longrightarrow>
         corres dc  (ko_at (ArchObj (PDPointerTable pt)) (p && ~~ mask pdpt_bits)
                     and pspace_aligned and valid_etcbs)
                    (pdpte_at' p)
          (set_pdpt (p && ~~ mask pdpt_bits) (pt(ucast (p && mask pdpt_bits >> word_size_bits) := pdpte)))
          (setObject p pdpte')"
  apply (simp add: set_pdpt_def get_object_def bind_assoc update_object_def)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
    apply simp
   apply (clarsimp simp: obj_at'_def ko_wp_at'_def typ_at'_def lookupAround2_known1 projectKOs)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply (clarsimp simp: setObject_def in_monad split_def updateObject_default_def projectKOs)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def a_type_simps)
  apply (clarsimp simp: obj_at_def exec_gets a_type_simps)
  apply (clarsimp simp: set_object_def bind_assoc exec_get)
  apply (clarsimp simp: put_def)
  apply (fold word_size_bits_def)
  apply (clarsimp simp: state_relation_def mask_pdpt_bits_inner_beauty)
  apply (rule conjI)
   apply (clarsimp simp: pspace_relation_def split del: if_split)
   apply (rule conjI)
    apply (subst pspace_dom_update, assumption)
     apply (simp add: a_type_def)
    apply (auto simp: dom_def)[1]
   apply (rule conjI)
    apply (drule bspec, blast)
    apply clarsimp
    apply (drule_tac x = x in spec)
    apply (clarsimp simp: pdpte_relation_def mask_pdpt_bits_inner_beauty
                   dest!: more_pdpt_inner_beauty)
   apply (rule ballI)
   apply (drule (1) bspec)
   apply clarsimp
   apply (rule conjI)
    apply (clarsimp simp: pdpte_relation_def mask_pdpt_bits_inner_beauty
                   dest!: more_pdpt_inner_beauty)
   apply clarsimp
   apply (drule bspec, assumption)
   apply clarsimp
   apply (erule (1) obj_relation_cutsE)
       apply simp
      apply simp
     apply clarsimp
     apply (frule (1) pspace_alignedD)
     apply (drule_tac p=x in pspace_alignedD, assumption)
     apply simp
     apply (drule mask_alignment_ugliness)
        apply (simp add: pdpt_bits_def pageBits_def)
       apply (simp add: pdpt_bits_def pageBits_def)
      apply clarsimp
      apply (clarsimp simp: nth_ucast nth_shiftl)
      apply (drule test_bit_size)
      apply (clarsimp simp: word_size bit_simps)
      apply arith
     apply ((simp split: if_split_asm)+)[5]
   apply (simp add: other_obj_relation_def
               split: Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (rule conjI)
   apply (clarsimp simp: ekheap_relation_def pspace_relation_def)
   apply (drule(1) ekheap_kheap_dom)
   apply clarsimp
   apply (drule_tac x=p in bspec, erule domI)
   apply (simp add: other_obj_relation_def
           split: Structures_A.kernel_object.splits)
  apply (rule conjI)
   apply (clarsimp simp add: ghost_relation_def)
   apply (erule_tac x="p && ~~ mask pdpt_bits" in allE)+
   apply fastforce
  apply (simp add: map_to_ctes_upd_other)
  apply (simp add: fun_upd_def)
  apply (simp add: caps_of_state_after_update obj_at_def swp_cte_at_caps_of)
  done

lemma more_pml4_inner_beauty:
  fixes x :: "9 word"
  fixes p :: machine_word
  assumes x: "x \<noteq> ucast (p && mask pml4_bits >> word_size_bits)"
  shows "(p && ~~ mask pml4_bits) + (ucast x << word_size_bits) = p \<Longrightarrow> False"
  by (rule mask_split_aligned_neg[OF _ _ x]; simp add: bit_simps)

-- "set_other_obj_corres unfortunately doesn't work here"
lemma set_pml4_corres:
  "pml4e_relation' pml4e pml4e' \<Longrightarrow>
         corres dc  (ko_at (ArchObj (PageMapL4 pt)) (p && ~~ mask pml4_bits)
                     and pspace_aligned and valid_etcbs)
                    (pml4e_at' p)
          (set_pml4 (p && ~~ mask pml4_bits) (pt(ucast (p && mask pml4_bits >> word_size_bits) := pml4e)))
          (setObject p pml4e')"
  apply (simp add: set_pml4_def get_object_def bind_assoc update_object_def)
  apply (rule corres_no_failI)
   apply (rule no_fail_pre, wp)
    apply simp
   apply (clarsimp simp: obj_at'_def ko_wp_at'_def typ_at'_def lookupAround2_known1 projectKOs)
   apply (case_tac ko, simp_all)[1]
   apply (rename_tac arch_kernel_object)
   apply (case_tac arch_kernel_object, simp_all add: projectKOs)[1]
   apply (simp add: objBits_simps archObjSize_def word_bits_def)
  apply (clarsimp simp: setObject_def in_monad split_def updateObject_default_def projectKOs)
  apply (simp add: in_magnitude_check objBits_simps archObjSize_def pageBits_def a_type_simps)
  apply (clarsimp simp: obj_at_def exec_gets a_type_simps)
  apply (clarsimp simp: set_object_def bind_assoc exec_get)
  apply (clarsimp simp: put_def)
  apply (fold word_size_bits_def)
  apply (clarsimp simp: state_relation_def mask_pml4_bits_inner_beauty)
  apply (rule conjI)
   apply (clarsimp simp: pspace_relation_def split del: if_split)
   apply (rule conjI)
    apply (subst pspace_dom_update, assumption)
     apply (simp add: a_type_def)
    apply (auto simp: dom_def)[1]
   apply (rule conjI)
    apply (drule bspec, blast)
    apply clarsimp
    apply (drule_tac x = x in spec)
    apply (clarsimp simp: pml4e_relation_def mask_pml4_bits_inner_beauty
      dest!: more_pml4_inner_beauty)
   apply (rule ballI)
   apply (drule (1) bspec)
   apply clarsimp
   apply (rule conjI)
    apply (clarsimp simp: pml4e_relation_def mask_pml4_bits_inner_beauty
      dest!: more_pml4_inner_beauty)
   apply clarsimp
   apply (drule bspec, assumption)
   apply clarsimp
   apply (erule (1) obj_relation_cutsE)
         apply simp
        apply simp
       apply clarsimp
      apply simp
     apply (frule (1) pspace_alignedD)
     apply (drule_tac p=x in pspace_alignedD, assumption)
     apply simp
     apply (drule mask_alignment_ugliness)
        apply (simp add: bit_simps)
       apply (simp add: pml4_bits_def pageBits_def)
      apply clarsimp
      apply (clarsimp simp: nth_ucast nth_shiftl)
      apply (drule test_bit_size)
      apply (clarsimp simp: word_size bit_simps)
      apply arith
     apply ((simp split: if_split_asm)+)[2]
   apply (simp add: other_obj_relation_def
      split: Structures_A.kernel_object.splits arch_kernel_obj.splits)
  apply (rule conjI)
   apply (clarsimp simp: ekheap_relation_def pspace_relation_def)
   apply (drule(1) ekheap_kheap_dom)
   apply clarsimp
   apply (drule_tac x=p in bspec, erule domI)
   apply (simp add: other_obj_relation_def
      split: Structures_A.kernel_object.splits)
  apply (rule conjI)
   apply (clarsimp simp add: ghost_relation_def)
   apply (erule_tac x="p && ~~ mask pml4_bits" in allE)+
   apply fastforce
  apply (simp add: map_to_ctes_upd_other)
  apply (simp add: fun_upd_def)
  apply (simp add: caps_of_state_after_update obj_at_def swp_cte_at_caps_of)
  done

declare set_arch_obj_simps[simp del]

lemma store_pml4e_corres:
  "pml4e_relation' pml4e pml4e' \<Longrightarrow>
  corres dc (pml4e_at p and pspace_aligned and valid_etcbs) (pml4e_at' p) (store_pml4e p pml4e) (storePML4E p pml4e')"
  apply (simp add: store_pml4e_def storePML4E_def)
  apply (rule corres_symb_exec_l)
     apply (erule set_pml4_corres)
    apply (clarsimp simp: exs_valid_def get_pml4_def get_object_def exec_gets bind_assoc
                          obj_at_def pml4e_at_def)
    apply (clarsimp simp: a_type_def return_def
                    split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
   apply wp
   apply clarsimp
  apply (clarsimp simp: get_pml4_def obj_at_def no_fail_def pml4e_at_def
                        get_object_def bind_assoc exec_gets)
  apply (clarsimp simp: a_type_def return_def
                  split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
  done

lemma store_pml4e_corres':
  "pml4e_relation' pml4e pml4e' \<Longrightarrow>
  corres dc
     (pml4e_at p and pspace_aligned and valid_etcbs) (pspace_aligned' and pspace_distinct')
     (store_pml4e p pml4e) (storePML4E p pml4e')"
  apply (rule stronger_corres_guard_imp,
         erule store_pml4e_corres)
   apply auto
  done

lemma store_pdpte_corres:
  "pdpte_relation' pdpte pdpte' \<Longrightarrow>
  corres dc (pdpte_at p and pspace_aligned and valid_etcbs) (pdpte_at' p) (store_pdpte p pdpte) (storePDPTE p pdpte')"
  apply (simp add: store_pdpte_def storePDPTE_def)
  apply (rule corres_symb_exec_l)
     apply (erule set_pdpt_corres)
    apply (clarsimp simp: exs_valid_def get_pdpt_def get_object_def exec_gets bind_assoc
                          obj_at_def pdpte_at_def)
    apply (clarsimp simp: a_type_def return_def
                    split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
   apply wp
   apply clarsimp
  apply (clarsimp simp: get_pdpt_def obj_at_def no_fail_def pdpte_at_def
                        get_object_def bind_assoc exec_gets)
  apply (clarsimp simp: a_type_def return_def
                  split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
  done

lemma store_pdpte_corres':
  "pdpte_relation' pdpte pdpte' \<Longrightarrow>
  corres dc
     (pdpte_at p and pspace_aligned and valid_etcbs) (pspace_aligned' and pspace_distinct')
     (store_pdpte p pdpte) (storePDPTE p pdpte')"
  apply (rule stronger_corres_guard_imp,
         erule store_pdpte_corres)
   apply auto
  done

lemma store_pde_corres:
  "pde_relation' pde pde' \<Longrightarrow>
  corres dc (pde_at p and pspace_aligned and valid_etcbs) (pde_at' p) (store_pde p pde) (storePDE p pde')"
  apply (simp add: store_pde_def storePDE_def)
  apply (rule corres_symb_exec_l)
     apply (erule set_pd_corres)
    apply (clarsimp simp: exs_valid_def get_pd_def get_object_def exec_gets bind_assoc
                          obj_at_def pde_at_def)
    apply (clarsimp simp: a_type_def return_def
                    split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
   apply wp
   apply clarsimp
  apply (clarsimp simp: get_pd_def obj_at_def no_fail_def pde_at_def
                        get_object_def bind_assoc exec_gets)
  apply (clarsimp simp: a_type_def return_def
                  split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
  done

lemma store_pde_corres':
  "pde_relation' pde pde' \<Longrightarrow>
  corres dc
     (pde_at p and pspace_aligned and valid_etcbs) (pspace_aligned' and pspace_distinct')
     (store_pde p pde) (storePDE p pde')"
  apply (rule stronger_corres_guard_imp,
         erule store_pde_corres)
   apply auto
  done

lemma store_pte_corres:
  "pte_relation' pte pte' \<Longrightarrow>
  corres dc (pte_at p and pspace_aligned and valid_etcbs) (pte_at' p) (store_pte p pte) (storePTE p pte')"
  apply (simp add: store_pte_def storePTE_def)
  apply (rule corres_symb_exec_l)
     apply (erule set_pt_corres)
    apply (clarsimp simp: exs_valid_def get_pt_def get_object_def
                          exec_gets bind_assoc obj_at_def pte_at_def)
    apply (clarsimp simp: a_type_def return_def
                    split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
   apply wp
   apply clarsimp
  apply (clarsimp simp: get_pt_def obj_at_def pte_at_def no_fail_def
                        get_object_def bind_assoc exec_gets)
  apply (clarsimp simp: a_type_def return_def
                  split: Structures_A.kernel_object.splits arch_kernel_obj.splits if_split_asm)
  done

lemma store_pte_corres':
  "pte_relation' pte pte' \<Longrightarrow>
  corres dc (pte_at p and pspace_aligned and valid_etcbs)
            (pspace_aligned' and pspace_distinct')
            (store_pte p pte) (storePTE p pte')"
  apply (rule stronger_corres_guard_imp,
         erule store_pte_corres)
   apply auto
  done

lemmas tableBitSimps[simplified ptTranslationBits_def, simplified] =
      ptBits_def pdBits_def pdptBits_def pml4Bits_def

lemmas shiftBitSimps[simplified ptTranslationBits_def pageBits_def, simplified] =
      ptShiftBits_def pdShiftBits_def pdptShiftBits_def pml4ShiftBits_def

lemmas bitSimps = tableBitSimps shiftBitSimps

lemma bit_simps_corres[simp]:
  "ptShiftBits = pt_shift_bits"
  "pdShiftBits = pd_shift_bits"
  "pdptShiftBits = pdpt_shift_bits"
  "pml4ShiftBits = pml4_shift_bits"
  "ptBits = pt_bits"
  "pdBits = pd_bits"
  "pdptBits = pdpt_bits"
  "pml4Bits = pml4_bits"
  by (simp add: bit_simps bitSimps)+

lemma get_pml4_index_corres[simp]:
  "get_pml4_index x = getPML4Index x"
  by (simp add: get_pml4_index_def getPML4Index_def bit_simps)

lemma get_pdpt_index_corres[simp]:
  "get_pdpt_index x = getPDPTIndex x"
  by (simp add: get_pdpt_index_def getPDPTIndex_def bit_simps)

lemma get_pd_index_corres[simp]:
  "get_pd_index x = getPDIndex x"
  by (simp add: get_pd_index_def getPDIndex_def bit_simps)

lemma get_pt_index_corres[simp]:
  "get_pt_index x = getPTIndex x"
  by (simp add: get_pt_index_def getPTIndex_def bit_simps )

lemma lookup_pml4_slot_corres [simp]:
  "lookupPML4Slot pml4 vptr = lookup_pml4_slot pml4 vptr"
  by (simp add: lookupPML4Slot_def lookup_pml4_slot_def bit_simps)

lemma corres_name_pre:
  "\<lbrakk> \<And>s s'. \<lbrakk> P s; P' s'; (s, s') \<in> state_relation \<rbrakk>
                 \<Longrightarrow> corres rvr (op = s) (op = s') f g \<rbrakk>
        \<Longrightarrow> corres rvr P P' f g"
  apply (simp add: corres_underlying_def split_def
                   Ball_def)
  apply blast
  done

defs checkPML4At_def:
  "checkPML4At pd \<equiv> stateAssert (page_map_l4_at' pd) []"

defs checkPDPTAt_def:
  "checkPDPTAt pd \<equiv> stateAssert (pd_pointer_table_at' pd) []"

defs checkPDAt_def:
  "checkPDAt pd \<equiv> stateAssert (page_directory_at' pd) []"

defs checkPTAt_def:
  "checkPTAt pt \<equiv> stateAssert (page_table_at' pt) []"

lemma pte_relation_must_pte:
  "pte_relation m (ArchObj (PageTable pt)) ko \<Longrightarrow> \<exists>pte. ko = (KOArch (KOPTE pte))"
  apply (case_tac ko)
   apply (simp_all add:pte_relation_def)
  apply clarsimp
  done

lemma pde_relation_must_pde:
  "pde_relation m (ArchObj (PageDirectory pd)) ko \<Longrightarrow> \<exists>pde. ko = (KOArch (KOPDE pde))"
  apply (case_tac ko)
   apply (simp_all add:pde_relation_def)
  apply clarsimp
  done

lemma pdpte_relation_must_pdpte:
  "pdpte_relation m (ArchObj (PDPointerTable pdpt)) ko \<Longrightarrow> \<exists>pdpte. ko = (KOArch (KOPDPTE pdpte))"
  apply (case_tac ko)
   apply (simp_all add:pdpte_relation_def)
  apply clarsimp
  done

lemma pml4e_relation_must_pml4e:
  "pml4e_relation m (ArchObj (PageMapL4 pml4)) ko \<Longrightarrow> \<exists>pml4e. ko = (KOArch (KOPML4E pml4e))"
  apply (case_tac ko)
   apply (simp_all add:pml4e_relation_def)
  apply clarsimp
  done

declare X64_H.pptrBase_def[simp]

lemma page_table_at_state_relation:
  "\<lbrakk>page_table_at (ptrFromPAddr ptr) s; pspace_aligned s;
     (s, sa) \<in> state_relation;pspace_distinct' sa\<rbrakk>
  \<Longrightarrow> page_table_at' (ptrFromPAddr ptr) sa"
  apply (clarsimp simp:page_table_at'_def state_relation_def
    obj_at_def)
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec)
   apply fastforce
  apply clarsimp
  apply (frule(1) pspace_alignedD)
   apply (simp add:ptrFromPAddr_def bit_simps )
  apply clarsimp
  apply (drule_tac x = "ucast y" in spec)
  apply (drule sym[where s = "pspace_dom (kheap s)"])
  apply (clarsimp simp:typ_at'_def ko_wp_at'_def)
  apply (subgoal_tac "(ptr + pptrBase + (y << word_size_bits)) \<in> dom (ksPSpace sa)")
   prefer 2
   apply (clarsimp simp: pspace_dom_def)
   apply (rule_tac x = "ptr + pptrBase" in bexI[where A = "dom (kheap s)"])
    apply (simp add:image_def )
    apply (rule_tac x = "ucast y" in exI)
    apply (simp add:ucast_ucast_len)
   apply fastforce
  apply (thin_tac "dom a = b" for a b)
  apply (frule(1) pspace_alignedD)
  apply (clarsimp simp: ucast_ucast_len word_size_bits_def
                 split: if_splits)
  apply (drule pte_relation_must_pte)
  apply (drule(1) pspace_distinctD')
  apply (clarsimp simp:objBits_simps archObjSize_def)
  apply (rule is_aligned_weaken)
   apply (erule aligned_add_aligned)
    apply (rule is_aligned_shiftl_self)
   apply simp
  apply simp
  done

lemma page_directory_at_state_relation:
  "\<lbrakk>page_directory_at ptr s; pspace_aligned s;
     (s, sa) \<in> state_relation;pspace_distinct' sa\<rbrakk>
  \<Longrightarrow> page_directory_at' ptr sa"
  apply (clarsimp simp:page_directory_at'_def state_relation_def obj_at_def)
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec)
   apply fastforce
  apply clarsimp
  apply (frule(1) pspace_alignedD)
   apply (simp add: pdBits_def pageBits_def bit_simps )
  apply clarsimp
  apply (drule_tac x = "ucast y" in spec)
  apply (drule sym[where s = "pspace_dom (kheap s)"])
  apply (clarsimp simp:typ_at'_def ko_wp_at'_def)
  apply (subgoal_tac "(ptr + (y << word_size_bits)) \<in> dom (ksPSpace sa)")
   prefer 2
   apply (clarsimp simp: pspace_dom_def)
   apply (rule_tac x = "ptr" in bexI[where A = "dom (kheap s)"])
    apply (simp add: image_def)
    apply (rule_tac x = "ucast y" in exI)
    apply (simp add:ucast_ucast_len)
   apply fastforce
  apply (thin_tac "dom a = b" for a b)
  apply (frule(1) pspace_alignedD)
  apply (clarsimp simp:ucast_ucast_len word_size_bits_def split:if_splits)
  apply (drule pde_relation_must_pde)
  apply (drule(1) pspace_distinctD')
  apply (clarsimp simp:objBits_simps archObjSize_def)
  apply (rule is_aligned_weaken)
   apply (erule aligned_add_aligned)
    apply (rule is_aligned_shiftl_self)
   apply simp
  apply simp
  done

lemma pd_pointer_table_at_state_relation:
  "\<lbrakk>pd_pointer_table_at ptr s; pspace_aligned s;
     (s, sa) \<in> state_relation;pspace_distinct' sa\<rbrakk>
  \<Longrightarrow> pd_pointer_table_at' ptr sa"
  apply (clarsimp simp:pd_pointer_table_at'_def state_relation_def obj_at_def)
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec)
   apply fastforce
  apply clarsimp
  apply (frule(1) pspace_alignedD)
   apply (simp add: bit_simps )
  apply clarsimp
  apply (drule_tac x = "ucast y" in spec)
  apply (drule sym[where s = "pspace_dom (kheap s)"])
  apply (clarsimp simp:typ_at'_def ko_wp_at'_def)
  apply (subgoal_tac "(ptr + (y << word_size_bits)) \<in> dom (ksPSpace sa)")
   prefer 2
   apply (clarsimp simp: pspace_dom_def)
   apply (rule_tac x = "ptr" in bexI[where A = "dom (kheap s)"])
    apply (simp add: image_def)
    apply (rule_tac x = "ucast y" in exI)
    apply (simp add:ucast_ucast_len)
   apply fastforce
  apply (thin_tac "dom a = b" for a b)
  apply (frule(1) pspace_alignedD)
  apply (clarsimp simp:ucast_ucast_len word_size_bits_def split:if_splits)
  apply (drule pdpte_relation_must_pdpte)
  apply (drule(1) pspace_distinctD')
  apply (clarsimp simp:objBits_simps archObjSize_def)
  apply (rule is_aligned_weaken)
   apply (erule aligned_add_aligned)
    apply (rule is_aligned_shiftl_self)
   apply simp
  apply simp
  done

lemma page_map_l4_at_state_relation:
  "\<lbrakk>page_map_l4_at ptr s; pspace_aligned s;
     (s, sa) \<in> state_relation;pspace_distinct' sa\<rbrakk>
  \<Longrightarrow> page_map_l4_at' ptr sa"
  apply (clarsimp simp:page_map_l4_at'_def state_relation_def obj_at_def)
  apply (clarsimp simp:pspace_relation_def)
  apply (drule bspec)
   apply fastforce
  apply clarsimp
  apply (frule(1) pspace_alignedD)
   apply (simp add: bit_simps )
  apply clarsimp
  apply (drule_tac x = "ucast y" in spec)
  apply (drule sym[where s = "pspace_dom (kheap s)"])
  apply (clarsimp simp:typ_at'_def ko_wp_at'_def)
  apply (subgoal_tac "(ptr + (y << word_size_bits)) \<in> dom (ksPSpace sa)")
   prefer 2
   apply (clarsimp simp: pspace_dom_def)
   apply (rule_tac x = "ptr" in bexI[where A = "dom (kheap s)"])
    apply (simp add: image_def)
    apply (rule_tac x = "ucast y" in exI)
    apply (simp add:ucast_ucast_len)
   apply fastforce
  apply (thin_tac "dom a = b" for a b)
  apply (frule(1) pspace_alignedD)
  apply (clarsimp simp:ucast_ucast_len word_size_bits_def split:if_splits)
  apply (drule pml4e_relation_must_pml4e)
  apply (drule(1) pspace_distinctD')
  apply (clarsimp simp:objBits_simps archObjSize_def)
  apply (rule is_aligned_weaken)
   apply (erule aligned_add_aligned)
    apply (rule is_aligned_shiftl_self)
   apply simp
  apply simp
  done

lemma getPML4E_wp:
  "\<lbrace>\<lambda>s. \<forall>ko. ko_at' (ko::pml4e) p s \<longrightarrow> Q ko s\<rbrace> getObject p \<lbrace>Q\<rbrace>"
  by (clarsimp simp: getObject_def split_def loadObject_default_def
                     archObjSize_def in_magnitude_check
                     projectKOs in_monad valid_def obj_at'_def objBits_simps)

lemma getPDPTE_wp:
  "\<lbrace>\<lambda>s. \<forall>ko. ko_at' (ko::pdpte) p s \<longrightarrow> Q ko s\<rbrace> getObject p \<lbrace>Q\<rbrace>"
  by (clarsimp simp: getObject_def split_def loadObject_default_def
                     archObjSize_def in_magnitude_check
                     projectKOs in_monad valid_def obj_at'_def objBits_simps)

lemma getPDE_wp:
  "\<lbrace>\<lambda>s. \<forall>ko. ko_at' (ko::pde) p s \<longrightarrow> Q ko s\<rbrace> getObject p \<lbrace>Q\<rbrace>"
  by (clarsimp simp: getObject_def split_def loadObject_default_def
                     archObjSize_def in_magnitude_check
                     projectKOs in_monad valid_def obj_at'_def objBits_simps)

lemma getPTE_wp:
  "\<lbrace>\<lambda>s. \<forall>ko. ko_at' (ko::pte) p s \<longrightarrow> Q ko s\<rbrace> getObject p \<lbrace>Q\<rbrace>"
  by (clarsimp simp: getObject_def split_def loadObject_default_def
                     archObjSize_def in_magnitude_check
                     projectKOs in_monad valid_def obj_at'_def objBits_simps)


lemma lookup_pdpt_slot_corres:
  "corres (lfr \<oplus> op =)
          (pspace_aligned and valid_arch_objs and page_map_l4_at pml4
          and (\<exists>\<rhd>pml4) and
          K (is_aligned pml4 pml4_bits \<and> vptr < pptr_base \<and> canonical_address vptr))
          (pspace_aligned' and pspace_distinct')
          (lookup_pdpt_slot pml4 vptr) (lookupPDPTSlot pml4 vptr)"
  apply (simp add: lookup_pdpt_slot_def lookupPDPTSlot_def)
  apply (rule corres_guard_imp)
  apply (rule corres_initial_splitE
                 [where Q'="\<lambda>_. pspace_distinct'" and Q="\<lambda>r. pml4e_at (lookup_pml4_slot pml4 vptr)"])
       apply (simp, rule get_pml4e_corres')
      apply (case_tac rv; simp add: lookup_failure_map_def bit_simps
                             split: X64_H.pml4e.splits)
      apply (wpsimp wp: getPML4E_wp get_pml4e_wp
                  simp: obj_at_def lookup_pml4_slot_eq lookup_pml4_slot_kernel_mappings returnOk_liftE
                        page_map_l4_pml4e_at_lookupI)+
  done

crunch aligned'[wp]: lookupPDPTSlot, lookupPDSlot pspace_aligned'
  (wp: getPML4E_wp getPDPTE_wp hoare_drop_imps ignore: getObject)

crunch distict'[wp]: lookupPDPTSlot, lookupPDSlot pspace_distinct'
  (wp: getPML4E_wp getPDPTE_wp hoare_drop_imps ignore: getObject)

lemma lookup_pd_slot_corres:
  "corres (lfr \<oplus> op =)
          (pspace_aligned and valid_arch_objs and valid_arch_state and equal_kernel_mappings
           and valid_global_objs and (\<exists>\<rhd> pml4) and page_map_l4_at pml4 and
             K (canonical_address vptr \<and> is_aligned pml4 pml4_bits \<and> vptr < pptr_base))
          (pspace_aligned' and pspace_distinct')
          (lookup_pd_slot pml4 vptr) (lookupPDSlot pml4 vptr)"
  apply (simp add: lookup_pd_slot_def lookupPDSlot_def)
  apply (rule corres_guard_imp)
    apply (rule corres_split_eqrE[OF _ lookup_pdpt_slot_corres])
      apply (rule corres_initial_splitE, simp, rule get_pdpte_corres')
        apply (case_tac rv; simp add: lookup_failure_map_def bit_simps  split: pdpte.splits)
        apply (wpsimp wp: get_pdpte_wp getPDPTE_wp simp: returnOk_liftE)+
  done

lemma lookup_pt_slot_corres:
  "corres (lfr \<oplus> op =)
          (pspace_aligned and valid_arch_objs and valid_arch_state and equal_kernel_mappings
           and valid_global_objs and (\<exists>\<rhd> pml4) and page_map_l4_at pml4 and
             K (canonical_address vptr \<and> is_aligned pml4 pml4_bits \<and> vptr < pptr_base))
          (pspace_aligned' and pspace_distinct')
          (lookup_pt_slot pml4 vptr) (lookupPTSlot pml4 vptr)"
  apply (simp add: lookup_pt_slot_def lookupPTSlot_def)
  apply (rule corres_guard_imp)
    apply (rule corres_split_eqrE[OF _ lookup_pd_slot_corres])
      apply (rule corres_initial_splitE, simp, rule get_pde_corres')
        apply (case_tac rv; simp_all add: lookup_failure_map_def bit_simps  split: pde.splits)
        apply (wpsimp wp: get_pde_wp getPDE_wp simp: returnOk_liftE)+
  done

declare in_set_zip_refl[simp]

crunch typ_at' [wp]: storePML4E "\<lambda>s. P (typ_at' T p s)"
  (wp: crunch_wps mapM_x_wp' simp: crunch_simps)

crunch typ_at' [wp]: storePDPTE "\<lambda>s. P (typ_at' T p s)"
  (wp: crunch_wps mapM_x_wp' simp: crunch_simps)

crunch typ_at' [wp]: storePDE "\<lambda>s. P (typ_at' T p s)"
  (wp: crunch_wps mapM_x_wp' simp: crunch_simps)

crunch typ_at' [wp]: storePTE "\<lambda>s. P (typ_at' T p s)"
  (wp: crunch_wps mapM_x_wp' simp: crunch_simps)

lemmas storePML4E_typ_ats[wp] = typ_at_lifts [OF storePML4E_typ_at']
lemmas storePDPTE_typ_ats[wp] = typ_at_lifts [OF storePDPTE_typ_at']
lemmas storePDE_typ_ats[wp] = typ_at_lifts [OF storePDE_typ_at']
lemmas storePTE_typ_ats[wp] = typ_at_lifts [OF storePTE_typ_at']

lemma setObject_asid_typ_at' [wp]:
  "\<lbrace>\<lambda>s. P (typ_at' T p s)\<rbrace> setObject p' (v::asidpool) \<lbrace>\<lambda>_ s. P (typ_at' T p s)\<rbrace>"
  by (wp setObject_typ_at')

lemmas setObject_asid_typ_ats' [wp] = typ_at_lifts [OF setObject_asid_typ_at']

lemma getObject_pte_inv[wp]:
  "\<lbrace>P\<rbrace> getObject p \<lbrace>\<lambda>rv :: pte. P\<rbrace>"
  by (simp add: getObject_inv loadObject_default_inv)

lemma getObject_pde_inv[wp]:
  "\<lbrace>P\<rbrace> getObject p \<lbrace>\<lambda>rv :: pde. P\<rbrace>"
  by (simp add: getObject_inv loadObject_default_inv)

lemma getObject_pdpte_inv[wp]:
  "\<lbrace>P\<rbrace> getObject p \<lbrace>\<lambda>rv :: pdpte. P\<rbrace>"
  by (simp add: getObject_inv loadObject_default_inv)

lemma getObject_pml4e_inv[wp]:
  "\<lbrace>P\<rbrace> getObject p \<lbrace>\<lambda>rv :: pml4e. P\<rbrace>"
  by (simp add: getObject_inv loadObject_default_inv)

crunch typ_at'[wp]: copyGlobalMappings "\<lambda>s. P (typ_at' T p s)"
  (wp: mapM_x_wp' ignore: forM_x getObject)

lemmas copyGlobalMappings_typ_ats[wp] = typ_at_lifts [OF copyGlobalMappings_typ_at']

lemma copy_global_mappings_corres:
  "corres dc (page_map_l4_at pm and pspace_aligned and valid_arch_state and valid_etcbs)
             (page_map_l4_at' pm and valid_arch_state')
          (copy_global_mappings pm) (copyGlobalMappings pm)"
  apply (simp add: copy_global_mappings_def copyGlobalMappings_def)
  apply (simp add: pd_bits_def pdBits_def objBits_simps
                   archObjSize_def pptr_base_def X64.pptrBase_def getPML4Index_def bit_simps)
  apply (rule corres_guard_imp)
    apply (rule corres_split [where r'="op =" and P=\<top>  and P'=\<top>])
       prefer 2
       apply (clarsimp simp: state_relation_def arch_state_relation_def)
      apply (rule corres_mapM_x)
          prefer 5
          apply (rule order_refl)
          apply clarsimp
            apply (rule corres_split)
            apply (rule store_pml4e_corres)
            apply assumption
           apply (rule_tac P="page_map_l4_at globalPM and pspace_aligned" and
                           P'="page_map_l4_at' globalPM" in corres_guard_imp)
             apply (rule corres_rel_imp)
              apply (rule get_pml4e_corres, assumption)
             apply clarsimp
            apply (erule page_map_l4_pml4e_atI[simplified bit_simps, simplified], word_bitwise, assumption)
           apply (erule page_map_l4_pml4e_atI'[simplified bit_simps, simplified], word_bitwise)
          apply (rule_tac P="page_map_l4_at pm and pspace_aligned and valid_etcbs" in hoare_triv)
          apply wp
          apply clarsimp
          apply (erule page_map_l4_pml4e_atI[simplified bit_simps, simplified], word_bitwise, assumption)
         apply (rule_tac P="page_map_l4_at' pm" in hoare_triv)
         apply (wp getPML4E_wp)
         apply clarsimp
         apply (erule page_map_l4_pml4e_atI'[simplified bit_simps, simplified], word_bitwise)
        apply wp
        apply simp+
       apply (wp getPML4E_wp)
       apply clarsimp
      apply clarsimp
     apply wp+
   apply (clarsimp simp: valid_arch_state_def obj_at_def dest!:pspace_alignedD)
  apply (simp add: valid_arch_state'_def)
  done

lemma arch_cap_rights_update:
  "acap_relation c c' \<Longrightarrow>
   cap_relation (cap.ArchObjectCap (acap_rights_update (acap_rights c \<inter> msk) c))
                 (Arch.maskCapRights (rights_mask_map msk) c')"
  apply (cases c, simp_all add: X64_H.maskCapRights_def
                                acap_rights_update_def Let_def isCap_simps)
  apply (simp add: maskVMRights_def vmrights_map_def rights_mask_map_def
                   validate_vm_rights_def vm_read_write_def vm_read_only_def
                   vm_kernel_only_def )
  done

lemma arch_deriveCap_inv:
  "\<lbrace>P\<rbrace> Arch.deriveCap arch_cap u \<lbrace>\<lambda>rv. P\<rbrace>"
  apply (simp      add: X64_H.deriveCap_def
                  cong: if_cong
             split del: if_split)
  apply (rule hoare_pre, wp undefined_valid)
  apply (cases u, simp_all add: isCap_defs)
  done

lemma arch_deriveCap_valid:
  "\<lbrace>valid_cap' (ArchObjectCap arch_cap)\<rbrace>
     Arch.deriveCap u arch_cap
   \<lbrace>\<lambda>rv. valid_cap' (ArchObjectCap rv)\<rbrace>,-"
  apply (simp      add: X64_H.deriveCap_def
                  cong: if_cong
             split del: if_split)
  apply (rule hoare_pre, wp undefined_validE_R)
  apply (cases arch_cap, simp_all add: isCap_defs)
  apply (simp add: valid_cap'_def capAligned_def
                   capUntypedPtr_def X64_H.capUntypedPtr_def)
  done

lemma arch_derive_corres:
 "cap_relation (cap.ArchObjectCap c) (ArchObjectCap c') \<Longrightarrow>
  corres (ser \<oplus> (\<lambda>c c'. cap_relation (cap.ArchObjectCap c) (ArchObjectCap c')))
         \<top> \<top>
         (arch_derive_cap c)
         (Arch.deriveCap slot c')"
  unfolding arch_derive_cap_def X64_H.deriveCap_def Let_def
  apply (cases c, simp_all add: isCap_simps split: option.splits split del: if_split)
      apply (clarify?, rule corres_noopE; wpsimp)+
  done

definition
  "vmattributes_map \<equiv> \<lambda>R. VMAttributes (PTAttr WriteThrough \<in> R) (PAT \<in> R) (PTAttr CacheDisabled \<in> R)"

definition
  page_entry_map :: "vm_page_entry \<Rightarrow> vmpage_entry \<Rightarrow> bool"
where
  "page_entry_map ae he \<equiv> case ae of
        vm_page_entry.VMPTE p \<Rightarrow> \<exists>p'. he = VMPTE p' \<and> pte_relation' p p'
      | vm_page_entry.VMPDE p \<Rightarrow> \<exists>p'. he = VMPDE p' \<and> pde_relation' p p'
      | vm_page_entry.VMPDPTE p \<Rightarrow> \<exists>p'. he = VMPDPTE p' \<and> pdpte_relation' p p'"

definition
  page_entry_ptr_map :: "machine_word \<Rightarrow> vmpage_entry_ptr \<Rightarrow> bool"
where
  "page_entry_ptr_map x h \<equiv> case_vmpage_entry_ptr (op = x) (op = x) (op = x) h"

definition
  page_entry_map_corres :: "vmpage_entry \<times>vmpage_entry_ptr \<Rightarrow> bool"
where
  "page_entry_map_corres e \<equiv> case (fst e) of
        VMPTE pte \<Rightarrow> \<exists>ptr'. snd e = VMPTEPtr ptr'
      | VMPDE pde \<Rightarrow> \<exists>ptr'. snd e = VMPDEPtr ptr'
      | VMPDPTE pdpte \<Rightarrow> \<exists>ptr'. snd e = VMPDPTEPtr ptr'"

term createMappingEntries
definition
  mapping_map :: "vm_page_entry \<times> machine_word \<Rightarrow> vmpage_entry \<times> vmpage_entry_ptr \<Rightarrow> bool"
where
  "mapping_map \<equiv> page_entry_map \<otimes> page_entry_ptr_map"

lemma create_mapping_entries_corres:
  notes mapping_map_simps = page_entry_map_def attr_mask_def attr_mask'_def page_entry_ptr_map_def
  shows
  "\<lbrakk> vm_rights' = vmrights_map vm_rights;
     attrib' = vmattributes_map attrib \<rbrakk>
  \<Longrightarrow> corres (ser \<oplus> mapping_map)
          (valid_arch_objs and pspace_aligned and valid_arch_state and valid_global_objs and
           equal_kernel_mappings and \<exists>\<rhd> pml4 and page_map_l4_at pml4 and
           K (is_aligned pml4 pml4_bits \<and> vmsz_aligned vptr pgsz \<and> vptr < pptr_base
                \<and> vm_rights \<in> valid_vm_rights \<and> canonical_address vptr))
          (pspace_aligned' and pspace_distinct')
          (create_mapping_entries base vptr pgsz vm_rights attrib pml4)
          (createMappingEntries base vptr pgsz vm_rights' attrib' pml4)"
  apply simp
  apply (cases pgsz, simp_all add: createMappingEntries_def mapping_map_def)
    apply (rule corres_guard_imp)
      apply (rule corres_split_eqrE)
         apply (rule corres_returnOkTT)
         apply (clarsimp simp: vmattributes_map_def mapping_map_simps)
        apply (rule corres_lookup_error)
        apply (rule lookup_pt_slot_corres)
       apply wp+
     apply clarsimp
    apply simp+
   apply (rule corres_guard_imp)
     apply (rule corres_split_eqrE)
        apply (rule corres_returnOkTT)
        apply (clarsimp simp: vmattributes_map_def mapping_map_simps)
       apply (rule corres_lookup_error)
       apply (rule lookup_pd_slot_corres)
      apply wp+
    apply clarsimp
   apply simp+
  apply (rule corres_guard_imp)
    apply (rule corres_split_eqrE)
       apply (rule corres_returnOkTT)
       apply (clarsimp simp: vmattributes_map_def mapping_map_simps)
      apply (rule corres_lookup_error)
      apply (rule lookup_pdpt_slot_corres)
     apply wp+
   apply clarsimp
  apply simp
  done

lemma pte_relation'_Invalid_inv [simp]:
  "pte_relation' x X64_H.pte.InvalidPTE = (x = X64_A.pte.InvalidPTE)"
  by (cases x) auto

lemma pde_relation'_Invalid_inv [simp]:
  "pde_relation' x X64_H.pde.InvalidPDE = (x = X64_A.pde.InvalidPDE)"
  by (cases x) auto

lemma pdpte_relation'_Invalid_inv [simp]:
  "pdpte_relation' x X64_H.pdpte.InvalidPDPTE = (x = X64_A.pdpte.InvalidPDPTE)"
  by (cases x) auto

lemma pml4e_relation'_Invalid_inv [simp]:
  "pml4e_relation' x X64_H.pml4e.InvalidPML4E = (x = X64_A.pml4e.InvalidPML4E)"
  by (cases x) auto

definition
  "valid_slots' m \<equiv> case m of
    (VMPTE pte, p) \<Rightarrow> \<lambda>s. valid_pte' pte s
  | (VMPDE pde, p) \<Rightarrow> \<lambda>s. valid_pde' pde s
  | (VMPDPTE pdpte, p) \<Rightarrow> \<lambda>s. valid_pdpte' pdpte s"

lemma valid_slots_typ_at':
  assumes x: "\<And>T p. \<lbrace>typ_at' T p\<rbrace> f \<lbrace>\<lambda>rv. typ_at' T p\<rbrace>"
  shows "\<lbrace>valid_slots' m\<rbrace> f \<lbrace>\<lambda>rv. valid_slots' m\<rbrace>"
  unfolding valid_slots'_def
  apply (cases m)
   apply (case_tac a)
    apply simp
    apply (wpsimp wp: x valid_pte_lift' valid_pde_lift' valid_pdpte_lift')+
  done

lemma createMappingEntries_valid_slots' [wp]:
  "\<lbrace>valid_objs' and
    K (vmsz_aligned' base sz \<and> vmsz_aligned' vptr sz \<and> ptrFromPAddr base \<noteq> 0) \<rbrace>
  createMappingEntries base vptr sz vm_rights attrib pd
  \<lbrace>\<lambda>m. valid_slots' m\<rbrace>, -"
  apply (simp add: createMappingEntries_def)
  apply (rule hoare_pre)
   apply (wp|wpc|simp add: valid_slots'_def valid_mapping'_def)+
  apply (simp add: vmsz_aligned'_def)
  apply auto
  done

lemma mapping_map_pte: "\<lbrakk>mapping_map (vm_page_entry.VMPTE p, x) m'; page_entry_map_corres m'\<rbrakk> \<Longrightarrow> \<exists>p'. m' = (VMPTE p', VMPTEPtr x)"
  by (cases m'; clarsimp simp : mapping_map_def page_entry_map_def page_entry_ptr_map_def page_entry_map_corres_def)

lemma mapping_map_pde: "\<lbrakk>mapping_map (vm_page_entry.VMPDE p, x) m'; page_entry_map_corres m'\<rbrakk> \<Longrightarrow> \<exists>p'. m' = (VMPDE p', VMPDEPtr x)"
  by (cases m'; clarsimp simp : mapping_map_def page_entry_map_def page_entry_ptr_map_def page_entry_map_corres_def)

lemma mapping_map_pdpte: "\<lbrakk>mapping_map (vm_page_entry.VMPDPTE p, x) m'; page_entry_map_corres m'\<rbrakk> \<Longrightarrow> \<exists>p'. m' = (VMPDPTE p', VMPDPTEPtr x)"
  by (cases m'; clarsimp simp : mapping_map_def page_entry_map_def page_entry_ptr_map_def page_entry_map_corres_def)

lemma createMappingEntries_wf:
  "\<lbrace>\<top>\<rbrace> createMappingEntries base vptr sz R attrs vspace \<lbrace>\<lambda>rv s. page_entry_map_corres rv\<rbrace>, -"
  apply (simp add: createMappingEntries_def page_entry_map_corres_def)
  apply (rule hoare_pre)
   apply wpc
     apply (wp | simp split: vmpage_entry.splits)+
  by auto

lemma ensure_safe_mapping_corres:
  notes mapping_map_simps = mapping_map_def page_entry_map_def page_entry_ptr_map_def attr_mask_def
  shows
  "\<lbrakk>mapping_map m m'; page_entry_map_corres m'\<rbrakk> \<Longrightarrow>
  corres (ser \<oplus> dc) (valid_mapping_entries m)
                    (pspace_aligned' and pspace_distinct')
                    (ensure_safe_mapping m) (ensureSafeMapping m')"
  apply (simp add: ensureSafeMapping_def)
  apply (cases m)
  apply (case_tac a)
     apply simp
     apply (frule (1) mapping_map_pte, clarsimp)
     apply (case_tac x1)
      apply (simp add: mapping_map_simps corres_returnOk)
     apply (clarsimp simp: mapping_map_simps)
     apply (rule corres_guard_imp)
       apply (rule corres_initial_splitE [where Q="\<lambda>_. \<top>" and Q'="\<lambda>_. \<top>"])
          apply simp
          apply (rule get_pte_corres')
         apply (case_tac rv, simp_all add: corres_returnOk split:X64_H.pte.splits if_splits)[1]
        apply wp[2]
       apply (wp hoare_drop_imps | wpc | simp add: valid_mapping_entries_def)+
    apply (frule (1) mapping_map_pde, clarsimp)
    apply (case_tac x2)
      apply (simp add: mapping_map_simps corres_returnOk)
     apply (clarsimp simp: mapping_map_simps corres_fail)
    apply (clarsimp simp: mapping_map_simps)
    apply (rule corres_guard_imp)
      apply (rule corres_initial_splitE [where Q="\<lambda>_. \<top>" and Q'="\<lambda>_. \<top>"])
         apply simp
         apply (rule get_pde_corres')
        apply (case_tac rv, simp_all add: corres_returnOk split:X64_H.pde.splits if_splits)[1]
       apply wp[2]
      apply (wp hoare_drop_imps | wpc | simp add: valid_mapping_entries_def)+
   apply (frule (1) mapping_map_pdpte, clarsimp)
   apply (case_tac x3)
     apply (simp add: mapping_map_simps corres_returnOk)
    apply (clarsimp simp: mapping_map_simps corres_fail)
   apply (clarsimp simp: mapping_map_simps)
   apply (rule corres_guard_imp)
     apply (rule corres_initial_splitE [where Q="\<lambda>_. \<top>" and Q'="\<lambda>_. \<top>"])
        apply simp
        apply (rule get_pdpte_corres')
       apply (case_tac rv, simp_all add: corres_returnOk split:X64_H.pdpte.splits if_splits)[1]
      apply wp[2]
     apply (wp hoare_drop_imps | wpc | simp add: valid_mapping_entries_def)+
  done

lemma asidHighBitsOf [simp]:
  "asidHighBitsOf asid = ucast (asid_high_bits_of asid)"
  apply (simp add: asidHighBitsOf_def asid_high_bits_of_def asidHighBits_def)
  apply (rule word_eqI)
  apply (simp add: word_size nth_ucast)
  done

lemma find_vspace_for_asid_corres'':
  "corres (lfr \<oplus> op =) ((\<lambda>s. valid_arch_state s \<or> vspace_at_asid asid pd s)
                           and valid_arch_objs and pspace_aligned
                           and K (0 < asid \<and> asid \<le> mask asidBits))
                       (pspace_aligned' and pspace_distinct' and no_0_obj')
                       (find_vspace_for_asid asid) (findVSpaceForASID asid)"
  apply (simp add: find_vspace_for_asid_def findVSpaceForASID_def)
  apply (rule corres_gen_asm, simp)
  apply (simp add: liftE_bindE asidRange_def
                   mask_2pm1[symmetric])
  apply (rule_tac r'="\<lambda>x y. x = y o ucast"
             in corres_split' [OF _ _ gets_sp gets_sp])
   apply (clarsimp simp: state_relation_def arch_state_relation_def)
  apply (case_tac "rv (asid_high_bits_of asid)")
   apply (simp add: liftME_def lookup_failure_map_def)
  apply (simp add: liftME_def bindE_assoc)
  apply (simp add: liftE_bindE)
  apply (rule corres_guard_imp)
    apply (rule corres_split [OF _ get_asid_pool_corres'])
      apply (rule_tac P="case_option \<top> page_map_l4_at (pool (ucast asid)) and pspace_aligned"
                 and P'="no_0_obj' and pspace_distinct'" in corres_inst)
      apply (rule_tac F="pool (ucast asid) \<noteq> Some 0" in corres_req)
       apply (clarsimp simp: obj_at_def no_0_obj'_def state_relation_def
                             pspace_relation_def a_type_def)
       apply (simp split: Structures_A.kernel_object.splits
                          arch_kernel_obj.splits if_split_asm)
       apply (drule_tac f="\<lambda>S. 0 \<in> S" in arg_cong)
       apply (simp add: pspace_dom_def)
       apply (drule iffD1, rule rev_bexI, erule domI)
        apply simp
        apply (rule image_eqI[rotated])
         apply (rule rangeI[where x=0])
        apply simp
       apply clarsimp
      apply (simp add: mask_asid_low_bits_ucast_ucast returnOk_def
                       lookup_failure_map_def
                split: option.split)
      apply clarsimp
     apply (wp getObject_inv loadObject_default_inv | simp)+
   apply clarsimp
   apply (rule context_conjI)
    apply (erule disjE)
     apply (clarsimp simp: valid_arch_state_def valid_asid_table_def)
     apply fastforce
    apply (clarsimp simp: vspace_at_asid_def valid_arch_objs_def)
    apply (clarsimp simp: vs_asid_refs_def graph_of_def elim!: vs_lookupE)
    apply (erule rtranclE)
     apply simp
    apply (clarsimp dest!: vs_lookup1D)
    apply (erule rtranclE)
     apply (clarsimp simp: vs_refs_def graph_of_def obj_at_def
                           a_type_def
                    split: Structures_A.kernel_object.splits
                           arch_kernel_obj.splits)
    apply (clarsimp dest!: vs_lookup1D)
    apply (erule rtranclE)
     apply (clarsimp dest!: vs_lookup1D)
    apply (clarsimp dest!: vs_lookup1D)
   apply clarsimp
   apply (drule(1) valid_arch_objsD[rotated])
    apply (rule vs_lookupI)
     apply (rule vs_asid_refsI)
     apply simp
    apply (rule rtrancl_refl)
   apply (clarsimp split: option.split)
   apply fastforce
  apply simp
  done

lemma find_vspace_for_asid_corres:
  "corres (lfr \<oplus> op =) ((\<lambda>s. valid_arch_state s \<or> vspace_at_asid asid pd s) and valid_arch_objs
                           and pspace_aligned and K (0 < asid \<and> asid \<le> mask asidBits))
                       (pspace_aligned' and pspace_distinct' and no_0_obj')
                       (find_vspace_for_asid asid) (findVSpaceForASID asid)"
  apply (rule find_vspace_for_asid_corres'')
  done

lemma find_vspace_for_asid_corres':
  "corres (lfr \<oplus> op =) (vspace_at_asid asid pd and valid_arch_objs
                           and pspace_aligned and  K (0 < asid \<and> asid \<le> mask asidBits))
                       (pspace_aligned' and pspace_distinct' and no_0_obj')
                       (find_vspace_for_asid asid) (findVSpaceForASID asid)"
  apply (rule corres_guard_imp, rule find_vspace_for_asid_corres'')
   apply fastforce
  apply simp
  done

lemma setObject_arch:
  assumes X: "\<And>p q n ko. \<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> updateObject val p q n ko \<lbrace>\<lambda>rv s. P (ksArchState s)\<rbrace>"
  shows "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject t val \<lbrace>\<lambda>rv s. P (ksArchState s)\<rbrace>"
  apply (simp add: setObject_def split_def)
  apply (wp X | simp)+
  done

lemma setObject_ASID_arch [wp]:
  "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject p (v::asidpool) \<lbrace>\<lambda>_ s. P (ksArchState s)\<rbrace>"
  apply (rule setObject_arch)
  apply (simp add: updateObject_default_def)
  apply wp
  apply simp
  done

lemma setObject_PDE_arch [wp]:
  "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject p (v::pde) \<lbrace>\<lambda>_ s. P (ksArchState s)\<rbrace>"
  apply (rule setObject_arch)
  apply (simp add: updateObject_default_def)
  apply wp
  apply simp
  done

lemma setObject_PML4E_arch [wp]:
  "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject p (v::pml4e) \<lbrace>\<lambda>_ s. P (ksArchState s)\<rbrace>"
  apply (rule setObject_arch)
  apply (simp add: updateObject_default_def)
  apply wp
  apply simp
  done

lemma setObject_PDPTE_arch [wp]:
  "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject p (v::pdpte) \<lbrace>\<lambda>_ s. P (ksArchState s)\<rbrace>"
  apply (rule setObject_arch)
  apply (simp add: updateObject_default_def)
  apply wp
  apply simp
  done

lemma setObject_PTE_arch [wp]:
  "\<lbrace>\<lambda>s. P (ksArchState s)\<rbrace> setObject p (v::pte) \<lbrace>\<lambda>_ s. P (ksArchState s)\<rbrace>"
  apply (rule setObject_arch)
  apply (simp add: updateObject_default_def)
  apply wp
  apply simp
  done

lemma setObject_ASID_valid_arch [wp]:
  "\<lbrace>valid_arch_state'\<rbrace> setObject p (v::asidpool) \<lbrace>\<lambda>_. valid_arch_state'\<rbrace>"
  by (rule valid_arch_state_lift'; wp)

lemma setObject_PML4E_valid_arch [wp]:
  "\<lbrace>valid_arch_state'\<rbrace> setObject p (v::pml4e) \<lbrace>\<lambda>_. valid_arch_state'\<rbrace>"
  by (rule valid_arch_state_lift') (wp setObject_typ_at')+

lemma setObject_PDPTE_valid_arch [wp]:
  "\<lbrace>valid_arch_state'\<rbrace> setObject p (v::pdpte) \<lbrace>\<lambda>_. valid_arch_state'\<rbrace>"
  by (rule valid_arch_state_lift') (wp setObject_typ_at')+

lemma setObject_PDE_valid_arch [wp]:
  "\<lbrace>valid_arch_state'\<rbrace> setObject p (v::pde) \<lbrace>\<lambda>_. valid_arch_state'\<rbrace>"
  by (rule valid_arch_state_lift') (wp setObject_typ_at')+

lemma setObject_PTE_valid_arch [wp]:
  "\<lbrace>valid_arch_state'\<rbrace> setObject p (v::pte) \<lbrace>\<lambda>_. valid_arch_state'\<rbrace>"
  by (rule valid_arch_state_lift') (wp setObject_typ_at')+

lemma setObject_ASID_ct [wp]:
  "\<lbrace>\<lambda>s. P (ksCurThread s)\<rbrace> setObject p (e::asidpool) \<lbrace>\<lambda>_ s. P (ksCurThread s)\<rbrace>"
  apply (simp add: setObject_def updateObject_default_def split_def)
  apply (wp updateObject_default_inv | simp)+
  done

lemma setObject_PML4E_ct [wp]:
  "\<lbrace>\<lambda>s. P (ksCurThread s)\<rbrace> setObject p (e::pml4e) \<lbrace>\<lambda>_ s. P (ksCurThread s)\<rbrace>"
  apply (simp add: setObject_def updateObject_default_def split_def)
  apply (wp updateObject_default_inv | simp)+
  done

lemma setObject_PDPTE_ct [wp]:
  "\<lbrace>\<lambda>s. P (ksCurThread s)\<rbrace> setObject p (e::pdpte) \<lbrace>\<lambda>_ s. P (ksCurThread s)\<rbrace>"
  apply (simp add: setObject_def updateObject_default_def split_def)
  apply (wp updateObject_default_inv | simp)+
  done

lemma setObject_PDE_ct [wp]:
  "\<lbrace>\<lambda>s. P (ksCurThread s)\<rbrace> setObject p (e::pde) \<lbrace>\<lambda>_ s. P (ksCurThread s)\<rbrace>"
  apply (simp add: setObject_def updateObject_default_def split_def)
  apply (wp updateObject_default_inv | simp)+
  done

lemma setObject_pte_ct [wp]:
  "\<lbrace>\<lambda>s. P (ksCurThread s)\<rbrace> setObject p (e::pte) \<lbrace>\<lambda>_ s. P (ksCurThread s)\<rbrace>"
  apply (simp add: setObject_def updateObject_default_def split_def)
  apply (wp updateObject_default_inv | simp)+
  done

lemma setObject_ASID_cur_tcb' [wp]:
  "\<lbrace>\<lambda>s. cur_tcb' s\<rbrace> setObject p (e::asidpool) \<lbrace>\<lambda>_ s. cur_tcb' s\<rbrace>"
  apply (simp add: cur_tcb'_def)
  apply (rule hoare_lift_Pf [where f=ksCurThread])
   apply wp+
  done

lemma setObject_PML4E_cur_tcb' [wp]:
  "\<lbrace>\<lambda>s. cur_tcb' s\<rbrace> setObject p (e::pml4e) \<lbrace>\<lambda>_ s. cur_tcb' s\<rbrace>"
  apply (simp add: cur_tcb'_def)
  apply (rule hoare_lift_Pf [where f=ksCurThread])
   apply wp+
  done

lemma setObject_PDPTE_cur_tcb' [wp]:
  "\<lbrace>\<lambda>s. cur_tcb' s\<rbrace> setObject p (e::pdpte) \<lbrace>\<lambda>_ s. cur_tcb' s\<rbrace>"
  apply (simp add: cur_tcb'_def)
  apply (rule hoare_lift_Pf [where f=ksCurThread])
   apply wp+
  done

lemma setObject_PDE_cur_tcb' [wp]:
  "\<lbrace>\<lambda>s. cur_tcb' s\<rbrace> setObject p (e::pde) \<lbrace>\<lambda>_ s. cur_tcb' s\<rbrace>"
  apply (simp add: cur_tcb'_def)
  apply (rule hoare_lift_Pf [where f=ksCurThread])
   apply wp+
  done

lemma setObject_pte_cur_tcb' [wp]:
  "\<lbrace>\<lambda>s. cur_tcb' s\<rbrace> setObject p (e::pte) \<lbrace>\<lambda>_ s. cur_tcb' s\<rbrace>"
  apply (simp add: cur_tcb'_def)
  apply (rule hoare_lift_Pf [where f=ksCurThread])
   apply wp+
  done

lemma getASID_wp:
  "\<lbrace>\<lambda>s. \<forall>ko. ko_at' (ko::asidpool) p s \<longrightarrow> Q ko s\<rbrace> getObject p \<lbrace>Q\<rbrace>"
  by (clarsimp simp: getObject_def split_def loadObject_default_def
                     archObjSize_def in_magnitude_check pageBits_def
                     projectKOs in_monad valid_def obj_at'_def objBits_simps)

lemma page_map_l4_pml4e_at_lookupI':
  "page_map_l4_at' pm s \<Longrightarrow> pml4e_at' (lookup_pml4_slot pm vptr) s"
  apply (simp add: lookup_pml4_slot_def Let_def)
  apply (erule page_map_l4_pml4e_atI')
  apply (clarsimp simp: bit_simps getPML4Index_def mask_def, word_bitwise)
  done

lemma pd_pointer_table_pdpte_at_lookupI':
  "pd_pointer_table_at' pm s \<Longrightarrow> pdpte_at' (lookup_pdpt_slot_no_fail pm vptr) s"
  apply (simp add: lookup_pdpt_slot_no_fail_def Let_def)
  apply (erule pd_pointer_table_pdpte_atI')
  apply (clarsimp simp: bit_simps getPDPTIndex_def mask_def, word_bitwise)
  done

lemma page_directory_pde_at_lookupI':
  "page_directory_at' pm s \<Longrightarrow> pde_at' (lookup_pd_slot_no_fail pm vptr) s"
  apply (simp add: lookup_pd_slot_no_fail_def Let_def)
  apply (erule page_directory_pde_atI')
  apply (clarsimp simp: bit_simps getPDIndex_def mask_def, word_bitwise)
  done

lemma page_table_pte_at_lookupI':
  "page_table_at' pt s \<Longrightarrow> pte_at' (lookup_pt_slot_no_fail pt vptr) s"
  apply (simp add: lookup_pt_slot_no_fail_def)
  apply (erule page_table_pte_atI')
  apply (clarsimp simp: bit_simps getPTIndex_def mask_def, word_bitwise)
  done

lemma storePTE_ctes [wp]:
  "\<lbrace>\<lambda>s. P (ctes_of s)\<rbrace> storePTE p pte \<lbrace>\<lambda>_ s. P (ctes_of s)\<rbrace>"
  apply (rule ctes_of_from_cte_wp_at [where Q=\<top>, simplified])
  apply (rule storePTE_cte_wp_at')
  done

lemma storePDE_ctes [wp]:
  "\<lbrace>\<lambda>s. P (ctes_of s)\<rbrace> storePDE p pte \<lbrace>\<lambda>_ s. P (ctes_of s)\<rbrace>"
  apply (rule ctes_of_from_cte_wp_at [where Q=\<top>, simplified])
  apply (rule storePDE_cte_wp_at')
  done

lemma storePDPTE_ctes [wp]:
  "\<lbrace>\<lambda>s. P (ctes_of s)\<rbrace> storePDPTE p pte \<lbrace>\<lambda>_ s. P (ctes_of s)\<rbrace>"
  apply (rule ctes_of_from_cte_wp_at [where Q=\<top>, simplified])
  apply (rule storePDPTE_cte_wp_at')
  done

lemma storePML4E_ctes [wp]:
  "\<lbrace>\<lambda>s. P (ctes_of s)\<rbrace> storePML4E p pte \<lbrace>\<lambda>_ s. P (ctes_of s)\<rbrace>"
  apply (rule ctes_of_from_cte_wp_at [where Q=\<top>, simplified])
  apply (rule storePML4E_cte_wp_at')
  done

lemma storePML4E_valid_objs [wp]:
  "\<lbrace>valid_objs' and valid_pml4e' pml4e\<rbrace> storePML4E p pml4e \<lbrace>\<lambda>_. valid_objs'\<rbrace>"
  apply (simp add: storePML4E_def doMachineOp_def split_def)
  apply (rule hoare_pre)
   apply (wp hoare_drop_imps|wpc|simp)+
   apply (rule setObject_valid_objs')
   prefer 2
   apply assumption
  apply (clarsimp simp: updateObject_default_def in_monad)
  apply (clarsimp simp: valid_obj'_def)
  done

lemma storePDPTE_valid_objs [wp]:
  "\<lbrace>valid_objs' and valid_pdpte' pdpte\<rbrace> storePDPTE p pdpte \<lbrace>\<lambda>_. valid_objs'\<rbrace>"
  apply (simp add: storePDPTE_def doMachineOp_def split_def)
  apply (rule hoare_pre)
   apply (wp hoare_drop_imps|wpc|simp)+
   apply (rule setObject_valid_objs')
   prefer 2
   apply assumption
  apply (clarsimp simp: updateObject_default_def in_monad)
  apply (clarsimp simp: valid_obj'_def)
  done

lemma storePDE_valid_objs [wp]:
  "\<lbrace>valid_objs' and valid_pde' pde\<rbrace> storePDE p pde \<lbrace>\<lambda>_. valid_objs'\<rbrace>"
  apply (simp add: storePDE_def doMachineOp_def split_def)
  apply (rule hoare_pre)
   apply (wp hoare_drop_imps|wpc|simp)+
   apply (rule setObject_valid_objs')
   prefer 2
   apply assumption
  apply (clarsimp simp: updateObject_default_def in_monad)
  apply (clarsimp simp: valid_obj'_def)
  done

lemma setObject_ASID_cte_wp_at'[wp]:
  "\<lbrace>\<lambda>s. P (cte_wp_at' P' p s)\<rbrace>
     setObject ptr (asid::asidpool)
   \<lbrace>\<lambda>rv s. P (cte_wp_at' P' p s)\<rbrace>"
  apply (wp setObject_cte_wp_at2'[where Q="\<top>"])
    apply (clarsimp simp: updateObject_default_def in_monad
                          projectKO_opts_defs projectKOs)
   apply (rule equals0I)
   apply (clarsimp simp: updateObject_default_def in_monad
                         projectKOs projectKO_opts_defs)
  apply simp
  done

lemma setObject_ASID_ctes_of'[wp]:
  "\<lbrace>\<lambda>s. P (ctes_of s)\<rbrace>
     setObject ptr (asid::asidpool)
   \<lbrace>\<lambda>rv s. P (ctes_of s)\<rbrace>"
  by (rule ctes_of_from_cte_wp_at [where Q=\<top>, simplified]) wp

lemma loadWordUser_inv :
  "\<lbrace>P\<rbrace> loadWordUser p \<lbrace>\<lambda>_. P\<rbrace>"
  unfolding loadWordUser_def
  by (wp dmo_inv' loadWord_inv stateAssert_wp | simp)+

lemma clearMemory_vms':
  "valid_machine_state' s \<Longrightarrow>
   \<forall>x\<in>fst (clearMemory ptr bits (ksMachineState s)).
      valid_machine_state' (s\<lparr>ksMachineState := snd x\<rparr>)"
  apply (clarsimp simp: valid_machine_state'_def
                        disj_commute[of "pointerInUserData p s" for p s])
  apply (drule_tac x=p in spec, simp)
  apply (drule_tac P4="\<lambda>m'. underlying_memory m' p = 0"
         in use_valid[where P=P and Q="\<lambda>_. P" for P], simp_all)
  apply (rule clearMemory_um_eq_0)
  done

lemma ct_not_inQ_ksMachineState_update[simp]:
  "ct_not_inQ (s\<lparr>ksMachineState := v\<rparr>) = ct_not_inQ s"
  by (simp add: ct_not_inQ_def)

lemma ct_in_current_domain_ksMachineState_update[simp]:
  "ct_idle_or_in_cur_domain' (s\<lparr>ksMachineState := v\<rparr>) = ct_idle_or_in_cur_domain' s"
  by (simp add: ct_idle_or_in_cur_domain'_def tcb_in_cur_domain'_def)

lemma dmo_clearMemory_invs'[wp]:
  "\<lbrace>invs'\<rbrace> doMachineOp (clearMemory w sz) \<lbrace>\<lambda>_. invs'\<rbrace>"
  apply (simp add: doMachineOp_def split_def)
  apply wp
  apply (clarsimp simp: invs'_def valid_state'_def)
  apply (rule conjI)
   apply (simp add: valid_irq_masks'_def, elim allEI, clarsimp)
   apply (drule use_valid)
     apply (rule no_irq_clearMemory[simplified no_irq_def, rule_format])
    apply simp_all
  apply (drule clearMemory_vms')
  apply fastforce
  done

end
end