(*
Copyright 2021 DeepMind Technologies Limited.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*)

open HolKernel boolLib bossLib Parse
  pairTheory pred_setTheory arithmeticTheory stringTheory

val _ = new_theory"cf0";

(* Cartesian Frames *)

Datatype:
  cf = <| world: string set;
          agent: string set;
          env: string set;
          eval: string -> string -> string |>
End

(*
We restrict attention to finite Cartesian frames so as to allow the category of
Cartesian frames over W to include frames where, e.g., the agent is the set of
functions whose domain is the agent of some other frame in the category. A
category (at least according to categoryTheory) has a _set_ of objects. The
collection of frames including those with all such sets of functions for
agents, and where some agents are infinite, is too large to be a set.

We also require c.world to be finite so ensureables etc. are finite too. This
is important because, e.g., cf1 w s uses s as its environment and we sometimes
want s to be something in ensure c.

An alternative approach would be to axiomatise (or assume) an (uncountable)
Grothendieck universe from which to draw the agents and environments for our
frames. Our proofs should not be hard to fix if we need to switch to this
approach.
*)

Definition finite_cf_def:
  finite_cf c ⇔ FINITE c.agent ∧ FINITE c.env ∧ FINITE c.world
End

Definition wf_def:
  wf c ⇔
    (∀a e. a ∈ c.agent ∧ e ∈ c.env ⇒ c.eval a e ∈ c.world) ∧
    (∀a e. a ∉ c.agent ∨ e ∉ c.env ⇒ c.eval a e = ARB) ∧
    finite_cf c
End

Definition image_def:
  image c = { w | ∃a e. a ∈ c.agent ∧ e ∈ c.env ∧ c.eval a e = w }
End

Theorem finite_image[simp]:
  finite_cf c ⇒ FINITE (image c)
Proof
  rw[image_def, finite_cf_def]
  \\ qspec_then`UNCURRY c.eval`irule (Q.GEN`f`FINITE_SURJ)
  \\ qexists_tac`c`
  \\ qexists_tac`c.agent × c.env`
  \\ simp[SURJ_DEF, FORALL_PROD, EXISTS_PROD]
  \\ metis_tac[]
QED

Definition mk_cf_def:
  mk_cf c = c with eval := λa e. if a ∈ c.agent ∧ e ∈ c.env then c.eval a e else ARB
End

Theorem mk_cf_components[simp]:
  (mk_cf c).world = c.world ∧
  (mk_cf c).agent = c.agent ∧
  (mk_cf c).env = c.env
Proof
  rw[mk_cf_def]
QED

Theorem wf_mk_cf[simp]:
  wf (mk_cf c) ⇔ image c ⊆ c.world ∧ finite_cf c
Proof
  rw[wf_def, SUBSET_DEF, image_def, mk_cf_def, finite_cf_def]
  \\ rw[EQ_IMP_THM] \\ rw[]
  \\ metis_tac[]
QED

(* Initial definition of controllables *)

Definition ensure_def:
  ensure c = { s | s ⊆ c.world ∧ ∃a. a ∈ c.agent ∧ ∀e. e ∈ c.env ⇒ c.eval a e ∈ s }
End

Definition prevent_def:
  prevent c = { s | s ⊆ c.world ∧ ∃a. a ∈ c.agent ∧ ∀e. e ∈ c.env ⇒ c.eval a e ∉ s }
End

Definition ctrl_def:
  ctrl c = ensure c ∩ prevent c
End

Theorem ensure_empty_agent[simp]:
  c.agent = ∅ ⇒ (ensure c = {})
Proof
  rw[ensure_def]
QED

Theorem ensure_subset_pow[simp]:
  ensure c ⊆ POW c.world
Proof
  rw[ensure_def, Once SUBSET_DEF, IN_POW]
QED

Theorem prevent_subset_pow[simp]:
  prevent c ⊆ POW c.world
Proof
  rw[prevent_def, Once SUBSET_DEF, IN_POW]
QED

Theorem ctrl_subset_pow[simp]:
  ctrl c ⊆ POW c.world
Proof
  rw[ctrl_def]
  \\ mp_tac ensure_subset_pow
  \\ rewrite_tac[SUBSET_DEF]
  \\ simp[]
QED

Theorem finite_ensure[simp]:
  finite_cf c ⇒ FINITE (ensure c)
Proof
  rw[finite_cf_def]
  \\ irule SUBSET_FINITE
  \\ qexists_tac`POW (c.world)`
  \\ simp[]
QED

Theorem finite_prevent[simp]:
  finite_cf c ⇒ FINITE (prevent c)
Proof
  rw[finite_cf_def]
  \\ irule SUBSET_FINITE
  \\ qexists_tac`POW (c.world)`
  \\ simp[]
QED

Theorem finite_ctrl[simp]:
  finite_cf c ⇒ FINITE (ctrl c)
Proof
  rw[finite_cf_def]
  \\ irule SUBSET_FINITE
  \\ qexists_tac`POW (c.world)`
  \\ simp[]
QED

Theorem ctrl_closure:
  c.world = c'.world ∧ c.agent ⊆ c'.agent ∧ c'.env ⊆ c.env ∧
  (∀a e. a ∈ c.agent ∧ e ∈ c'.env ⇒ c'.eval a e = c.eval a e) ⇒
  ensure c ⊆ ensure c' ∧ prevent c ⊆ prevent c' ∧ ctrl c ⊆ ctrl c'
Proof
  rw[ensure_def, prevent_def, ctrl_def, SUBSET_DEF] \\ metis_tac[]
QED

Theorem ensure_superset:
  s1 ⊆ s2 ∧ s2 ⊆ c.world ∧ s1 ∈ ensure c ⇒ s2 ∈ ensure c
Proof
  rw[ensure_def, SUBSET_DEF] \\ metis_tac[]
QED

Theorem prevent_subset:
  s1 ⊆ s2 ∧ s2 ⊆ c.world ∧ s2 ∈ prevent c ⇒ s2 ∈ prevent c
Proof
  rw[prevent_def, SUBSET_DEF] \\ metis_tac[]
QED

Definition sup_closure_def:
  sup_closure u sos = { s | s ⊆ u ∧ ∃t. t ∈ sos ∧ t ⊆ s }
End

Definition sub_closure_def:
  sub_closure u sos = { s | s ⊆ u ∧ ∃t. t ∈ sos ∧ s ⊆ t }
End

Definition union_closure_def:
  union_closure sos = { BIGUNION s | s ⊆ sos }
End

Theorem union_closure_sing:
  union_closure {s} = {{}; s}
Proof
  rw[union_closure_def]
  \\ rw[Once EXTENSION]
  \\ Cases_on`x = {}` \\ fs[] >- (qexists_tac`{}` \\ simp[])
  \\ Cases_on`x = s` \\ fs[] >- (qexists_tac`{s}` \\ fs[])
  \\ qx_gen_tac`b`
  \\ Cases_on`b = {s}` \\ fs[]
  \\ reverse(Cases_on` b PSUBSET {s}`) >- fs[PSUBSET_DEF]
  \\ fs[PSUBSET_SING]
QED

Theorem union_closure_empty[simp]:
  union_closure ∅ = {∅}
Proof
  rw[union_closure_def]
  \\ rw[Once EXTENSION]
QED

Theorem union_closure_insert:
  union_closure (x INSERT ss) =
  IMAGE ((UNION) x) (union_closure ss) ∪ union_closure ss
Proof
  rw[union_closure_def, Once EXTENSION]
  \\ rw[EQ_IMP_THM]
  >- (
    reverse(Cases_on`x ∈ s` \\ fs[]) >- metis_tac[]
    \\ disj1_tac
    \\ simp[PULL_EXISTS]
    \\ qexists_tac`s DELETE x`
    \\ fs[SUBSET_DEF]
    \\ reverse conj_tac >- metis_tac[]
    \\ simp[Once EXTENSION]
    \\ metis_tac[])
  >- (
    qexists_tac`x INSERT s`
    \\ simp[] \\ fs[SUBSET_DEF] )
  \\ qexists_tac`s`
  \\ fs[SUBSET_DEF]
QED

(* Initial definition of observables *)

Definition ifs_def:
  ifs c s a0 a1 =
  { a | a ∈ c.agent ∧ ∀e. e ∈ c.env ⇒
    (c.eval a e ∈ s ⇒ c.eval a e = c.eval a0 e) ∧
    (c.eval a e ∉ s ⇒ c.eval a e = c.eval a1 e) }
End

Theorem ifs_compl:
  s ⊆ c.world ∧ wf c⇒
    ifs c s a0 a1 = ifs c (c.world DIFF s) a1 a0
Proof
  rw[ifs_def, wf_def]
  \\ fs[SUBSET_DEF]
  \\ rw[Once EXTENSION]
  \\ metis_tac[]
QED

Theorem ifs_same[simp]:
  a ∈ c.agent ⇒ a ∈ ifs c s a a
Proof
  rw[ifs_def]
QED

Definition obs_def:
  obs c = { s | s ⊆ c.world ∧ ∀a0 a1. a0 ∈ c.agent ∧ a1 ∈ c.agent ⇒
    ∃a. a ∈ ifs c s a0 a1 }
End

Theorem obs_compl:
  wf c ∧ s ∈ obs c ⇒ c.world DIFF s ∈ obs c
Proof
  rw[obs_def] \\ rw[GSYM ifs_compl]
QED

Theorem obs_union:
  s ∈ obs c ∧ t ∈ obs c ⇒ s ∪ t ∈ obs c
Proof
  rw[obs_def]
  \\ `∃a2. a2 ∈ ifs c s a0 a1` by metis_tac[]
  \\ `a2 ∈ c.agent` by fs[ifs_def]
  \\ `∃a3. a3 ∈ ifs c t a0 a2` by metis_tac[]
  \\ qexists_tac`a3` \\ rw[]
  \\ fs[ifs_def]
  \\ metis_tac[]
QED

Theorem obs_inter:
  wf c ∧ s ∈ obs c ∧ t ∈ obs c ⇒ s ∩ t ∈ obs c
Proof
  strip_tac
  \\ imp_res_tac obs_compl
  \\ `s ⊆ c.world ∧ t ⊆ c.world` by fs[obs_def]
  \\ `s ∩ t = c.world DIFF ((c.world DIFF s) ∪ (c.world DIFF t))` by (
    rw[EXTENSION] \\ fs[SUBSET_DEF] \\ metis_tac[] )
  \\ pop_assum SUBST1_TAC
  \\ match_mp_tac obs_compl \\ fs[]
  \\ match_mp_tac obs_union \\ fs[]
QED

Theorem obs_closure:
  c'.env ⊆ c.env ∧ c'.world = c.world ∧ c'.agent = c.agent ∧
  (∀a e. a ∈ c.agent ∧ e ∈ c'.env ⇒ c'.eval a e = c.eval a e) ⇒
  obs c ⊆ obs c'
Proof
  rw[obs_def, SUBSET_DEF]
  \\ first_x_assum (qspecl_then[`a0`,`a1`]mp_tac)
  \\ rw[]
  \\ fs[ifs_def]
  \\ metis_tac[]
QED

Theorem obs_empty:
  {} ∈ obs c
Proof
  rw[obs_def, ifs_def]
  \\ qexists_tac`a1` \\ rw[]
QED

Theorem obs_world:
  wf c ⇒ c.world ∈ obs c
Proof
  rw[obs_def, ifs_def, wf_def]
  \\ metis_tac[]
QED

Theorem union_closure_SUBSET_obs:
  FINITE s ⇒
  (union_closure s ⊆ obs c ⇔ s ⊆ obs c)
Proof
  rw[EQ_IMP_THM]
  >- (
    fs[union_closure_def, Once SUBSET_DEF, PULL_EXISTS]
    \\ rw[]
    \\ first_x_assum(qspec_then`{x}`mp_tac)
    \\ simp[SUBSET_DEF] )
  \\ rpt (pop_assum mp_tac)
  \\ qid_spec_tac`s`
  \\ ho_match_mp_tac FINITE_INDUCT
  \\ rw[obs_empty]
  \\ simp[union_closure_insert]
  \\ fs[SUBSET_DEF, PULL_EXISTS]
  \\ metis_tac[obs_union]
QED

Definition env_for_def:
  env_for c s = { e | e ∈ c.env ∧ ∀a. a ∈ c.agent ⇒ c.eval a e ∈ s }
End

Theorem finite_env_for[simp]:
  finite_cf c ⇒ FINITE (env_for c s)
Proof
  rw[finite_cf_def]
  \\ irule SUBSET_FINITE
  \\ qexists_tac`c.env`
  \\ simp[SUBSET_DEF, env_for_def]
QED

Theorem obs_env_for:
  wf c ∧ s ∈ obs c ⇒ ∀e. e ∈ c.env ⇒ e ∈ env_for c s ∨ e ∈ env_for c (c.world DIFF s)
Proof
  rpt strip_tac
  \\ CCONTR_TAC \\ fs[]
  \\ `∃a0. a0 ∈ c.agent ∧ c.eval a0 e ∉ s`
  by ( fs[env_for_def] \\ fs[] \\ metis_tac[] )
  \\ `∃a1. a1 ∈ c.agent ∧ c.eval a1 e ∈ s`
  by ( fs[wf_def, env_for_def] \\ fs[] \\ metis_tac[] )
  \\ `∃a. a ∈ ifs c s a0 a1` by fs[obs_def]
  \\ Cases_on`c.eval a e ∈ s`
  \\ fs[env_for_def] \\ fs[ifs_def] \\ metis_tac[]
QED

Theorem env_for_compl_disjoint:
  c.agent ≠ ∅ ⇒
  DISJOINT (env_for c s) (env_for c (c.world DIFF s))
Proof
  rw[IN_DISJOINT, env_for_def] \\ metis_tac[MEMBER_NOT_EMPTY]
QED

Theorem ctrl_obs_disjoint:
  wf c ∧ c.env ≠ {} ⇒ DISJOINT (ctrl c) (obs c)
Proof
  simp[IN_DISJOINT]
  \\ strip_tac
  \\ imp_res_tac obs_env_for
  \\ qx_gen_tac`s`
  \\ CCONTR_TAC \\ fs[]
  \\ `∃e. e ∈ c.env` by (Cases_on`c.env` \\ fs[] \\ metis_tac[])
  \\ `s ∈ prevent c ∧ s ∈ ensure c` by fs[ctrl_def]
  \\ `∃a0. a0 ∈ c.agent ∧ c.eval a0 e ∉ s` by (fs[prevent_def] \\ metis_tac[])
  \\ `∃a1. a1 ∈ c.agent ∧ c.eval a1 e ∈ s` by (fs[ensure_def] \\ metis_tac[])
  \\ fs[env_for_def, wf_def]
  \\ metis_tac[]
QED

Theorem image_subset_ensure_inter_obs:
wf c ⇒
  (s ∈ ensure c ∩ obs c ⇔ image c ⊆ s ∧ c.agent ≠ {} ∧ s ⊆ c.world)
Proof
  strip_tac
  \\ reverse EQ_TAC
  >- (
    strip_tac
    \\ simp[]
    \\ reverse conj_asm2_tac
    >- (
      fs[obs_def, image_def, wf_def]
      \\ rpt strip_tac
      \\ qexists_tac`a0`
      \\ simp[ifs_def]
      \\ fsrw_tac[][SUBSET_DEF]
      \\ metis_tac[])
    \\ simp[ensure_def]
    \\ Cases_on`c.agent` \\ fs[]
    \\ qexists_tac`x`
    \\ simp[]
    \\ fs[image_def, SUBSET_DEF, wf_def]
    \\ metis_tac[] )
  \\ strip_tac
  \\ Cases_on`c.agent = {}`
  >- fs[ensure_def]
  \\ fs[image_def]
  \\ reverse conj_tac
  >- fs[SUBSET_DEF, obs_def]
  \\ CCONTR_TAC \\ fs[SUBSET_DEF]
  \\ fs[ensure_def]
  \\ first_assum(mp_then Any mp_tac obs_env_for)
  \\ simp[]
  \\ goal_assum(first_assum o mp_then Any mp_tac)
  \\ simp[env_for_def]
  \\ fs[wf_def]
  \\ metis_tac[]
QED

Theorem ensure_inter_obs:
  wf c ∧ c.agent ≠ ∅ ⇒ ensure c ∩ obs c = sup_closure c.world {image c}
Proof
  strip_tac
  \\ rewrite_tac[EXTENSION]
  \\ simp[image_subset_ensure_inter_obs]
  \\ simp[sup_closure_def]
  \\ metis_tac[]
QED

Theorem small_agent_large_obs:
  FINITE c.agent ∧ CARD c.agent ≤ 1 ⇒ obs c = POW c.world
Proof
  strip_tac
  \\ Cases_on`c.agent` \\ rfs[CARD_INSERT]
  >- ( simp[obs_def, POW_DEF] )
  \\ reverse(Cases_on`t` \\ rfs[ADD1, CARD_INSERT])
  >- ( qpat_x_assum`_ ≤ 1`mp_tac \\ rw[] )
  \\ simp[obs_def]
  \\ `x ∈ c.agent` by fs[]
  \\ simp[EXTENSION, IN_POW, PULL_EXISTS]
  \\ metis_tac[ifs_same]
QED

Theorem empty_env_large_ctrl:
  c.agent ≠ ∅ ∧ c.env = ∅ ⇒
    ctrl c = POW c.world ∧
    prevent c = POW c.world ∧
    ensure c = POW c.world
Proof
  strip_tac
  \\ conj_asm2_tac
  \\ simp[ctrl_def]
  \\ simp[prevent_def, ensure_def, MEMBER_NOT_EMPTY]
  \\ simp[EXTENSION, IN_POW]
QED

Theorem small_env_large_ctrl:
  wf c ∧ c.agent ≠ ∅ ∧ c.env = {e} ⇒
    ctrl c = { s | s ⊆ c.world ∧ ¬DISJOINT s (image c) ∧ ¬DISJOINT (c.world DIFF s) (image c) } ∧
    ensure c = { s | s ⊆ c.world ∧ ¬DISJOINT s (image c) } ∧
    prevent c = { s | s ⊆ c.world ∧ ¬DISJOINT (c.world DIFF s) (image c) }
Proof
  strip_tac
  \\ conj_asm2_tac
  \\ simp[ctrl_def]
  >- (
    simp[EXTENSION]
    \\ fs[IN_DISJOINT, SUBSET_DEF]
    \\ metis_tac[])
  \\ fs[GSYM MEMBER_NOT_EMPTY]
  \\ simp[ensure_def, prevent_def]
  \\ simp[EXTENSION, GSYM FORALL_AND_THM]
  \\ qx_gen_tac`s`
  \\ Cases_on`s ⊆ c.world` \\ fs[]
  \\ fs[SUBSET_DEF]
  \\ simp[IN_DISJOINT, SUBSET_DEF, image_def]
  \\ conj_tac >- metis_tac[]
  \\ reverse(rw[EQ_IMP_THM])
  >- metis_tac[]
  \\ fs[wf_def]
  \\ rw[PULL_EXISTS]
  \\ metis_tac[]
QED

val _ = export_theory();
