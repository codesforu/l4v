(*
 * Copyright 2014, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(NICTA_BSD)
 *)

theory Arbitrary_Comm_Monoid
imports Main
begin

text {*
  We define operations "arbitrary_add" and "arbitrary_zero"
  to represent an arbitrary commutative monoid.
*}

definition
  arbitrary_add :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"
  (infixl "+\<^sub>?" 65)
where
  "arbitrary_add a b \<equiv> fst (SOME (f, z). comm_monoid f z) a b"

definition
  arbitrary_zero :: "'a"
  ("0\<^sub>?")
where
 "arbitrary_zero \<equiv> snd (SOME (f, z). comm_monoid f z)"

text {*
  For every type, there exists some function @{term f} and
  identity @{term e} on that type forming a monoid.
*}
lemma comm_monoid_exists:
      "\<exists>f e. comm_monoid f e"
proof cases
  assume two_elements: "\<exists>(a :: 'a) b. a \<noteq> b"

  obtain x e where diff: "x \<noteq> (e :: 'a)"
    by (atomize_elim, clarsimp simp: two_elements)

  define f where "f \<equiv> \<lambda>a b. (if a = e then b else (if b = e then a else x))"

  have "\<forall>a b. f a b = f b a"
    by (simp add: f_def)
  moreover have "\<forall>a b c. f (f a b) c = f a (f b c)"
    by (simp add: diff f_def)
  moreover have "\<forall>b. f e b = b"
    by (simp add: diff f_def)
  ultimately show ?thesis
    by (metis comm_monoid_def abel_semigroup_def semigroup_def
          abel_semigroup_axioms_def comm_monoid_axioms_def)
next
  assume single_element: "\<not> (\<exists>(a :: 'a) b. a \<noteq> b)"
  thus ?thesis
    by (metis (full_types) comm_monoid_def abel_semigroup_def
          semigroup_def abel_semigroup_axioms_def comm_monoid_axioms_def)
qed

text {*
  These operations form a commutative monoid.
*}
interpretation comm_monoid arbitrary_add arbitrary_zero
  unfolding arbitrary_add_def [abs_def] arbitrary_zero_def
  by (rule someI2_ex, auto simp: comm_monoid_exists)

locale idem_comm_monoid = comm_monoid +
  assumes comm_idem: "a \<^bold>* a = a"

locale canc_comm_monoid = comm_monoid +
  assumes canc: "a \<^bold>* b = a \<^bold>* c  \<Longrightarrow> b = c"

lemma idem_comm_monoid_not_canc:
  "((x :: 'a) \<noteq> e) \<Longrightarrow> idem_comm_monoid f (e :: 'a :: times) \<Longrightarrow> \<not> canc_comm_monoid f e"
  apply (clarsimp simp: idem_comm_monoid_def canc_comm_monoid_def canc_comm_monoid_axioms_def
                        idem_comm_monoid_axioms_def)
  apply (rule_tac x="x" in exI)
  apply (rule_tac x="x" in exI)
  apply (rule_tac x="e" in exI)
  apply (erule_tac x=x in allE, clarsimp)
  apply (clarsimp simp: comm_monoid_def comm_monoid_axioms_def abel_semigroup_def
                        abel_semigroup_axioms_def semigroup_def)
  by metis

lemma idem_comm_monoid_exists:
      "\<exists>f e. idem_comm_monoid f e"
  apply (cases "\<exists>(x :: 'a) e. x \<noteq> e")
   apply (clarsimp)
   apply (rule_tac x="\<lambda>a b. (if a = b then a else (if a = e then b else (if b = e then a else x)))"
                   in exI)
   apply (rule_tac x=e in exI)
   apply (intro_locales)
      apply (clarsimp simp: semigroup_def)
     apply (clarsimp simp: abel_semigroup_axioms_def)
    apply (clarsimp simp: comm_monoid_axioms_def)
   apply (clarsimp simp: idem_comm_monoid_axioms_def)
  apply (clarsimp)
  apply (rule_tac x="\<lambda>x. undefined" in exI)
  apply (rule_tac x="undefined" in exI)
  apply (intro_locales)
     apply (clarsimp simp: semigroup_def)
    apply (clarsimp simp: abel_semigroup_axioms_def)
   apply (clarsimp simp: comm_monoid_axioms_def)
  apply (clarsimp simp: idem_comm_monoid_axioms_def)
  done

end