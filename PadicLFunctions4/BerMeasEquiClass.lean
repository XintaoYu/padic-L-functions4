/-
Copyright (c) 2021 Ashvni Narayanan. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ashvni Narayanan
-/
import PadicLFunctions4.padic_int_clopen
import PadicLFunctions4.padic_integral
import PadicLFunctions4.BerMeasEventuallyConstant
import PadicLFunctions4.BerMeasBerDist
--import Nat_properties

/-!
# Equivalence class on ℤ/(d * p^n)ℤ
This file deFines `equi_class` and its properties on `ZMod (d * p^n)`.
We also use `ZMod'`, which is the universal (sub)set of `ZMod`, to make computations on sums easier.

## Main deFinitions and theorems
 * `equi_class`
 * `ZMod'`
 * `equi_class.ZMod'_succ_eq_bUnion`
 * `bernoulli_distribution_sum`

## Implementation notes
 * Changed bernoulli_measure_one to bernoulli_measure_def and bernoulli_measure_two to equi_class

## References
Introduction to Cyclotomic Fields, Washington (Chapter 12, Section 2)

## Tags
p-adic, L-function, Bernoulli measure
-/

--local attribute [instance] ZMod.topological_space

namespace Nat
lemma lt_pow {n a : ℕ} (h1 : 1 < a) (h2 : 1 < n) : a < a^n := by
  conv =>
  { congr
    rw [←pow_one a] }
  apply pow_lt_pow_right h1 h2

lemma lt_mul_pow_right {m a b : ℕ} (h1 : 0 < b) (h2 : 1 < a) (h3 : 1 < m) : a < b * a^m :=
lt_of_le_of_lt ((le_mul_iff_one_le_left (lt_trans zero_lt_one h2)).2 h1)
  (mul_lt_mul' le_rfl (lt_pow h2 h3) (Nat.zero_le _) h1)

lemma pow_lt_mul_pow_succ_right {p d : ℕ} [NeZero d] [Fact p.Prime] (m : ℕ) : p ^ m < d * p ^ m.succ := by
  rw [pow_succ', ←mul_assoc]
  refine' lt_mul_of_one_lt_left (pow_pos (Nat.Prime.pos Fact.out) _)
    (one_lt_mul ((Nat.succ_le_iff).2 (Nat.pos_of_ne_zero (NeZero.ne _))) (Nat.Prime.one_lt Fact.out))

lemma mul_pow_lt_mul_pow_succ {p d : ℕ} [NeZero d] [Fact p.Prime] [NeZero d] (m : ℕ) : d * p ^ m < d * p ^ m.succ :=
mul_lt_mul' le_rfl (Nat.pow_lt_pow_succ (Nat.Prime.one_lt (fact_iff.1 inferInstance)) m)
    (Nat.zero_le _) (Nat.pos_of_ne_zero (NeZero.ne _))

lemma Coprime.mul_pow {a b c : ℕ} (n : ℕ) (hc' : c.Coprime a) (hc : c.Coprime b) :
  c.Coprime (a * b^n) := coprime_mul_iff_right.2 ⟨hc', Coprime.pow_right n hc⟩
end Nat

variable {p : ℕ} {d : ℕ} (R : Type*) [NormedCommRing R] {c : ℕ}
open eventually_constant_seq
open scoped BigOperators

/-- A variant of `ZMod` which has type `Finset _`. -/
def ZMod' (n : ℕ) (h : n ≠ 0) : Finset (ZMod n) :=
  @Finset.univ _ (@ZMod.fintype n (⟨h⟩))

open Nat PadicInt ZMod discrete_quotient_of_toZModPow

/-- Given `a ∈ ZMod (d * p^n)`, the set of all `b ∈ ZMod (d * p^m)` such that
  `b = a mod (d * p^n)`. -/
def equi_class {n : ℕ} (m : ℕ) (a : ZMod (d * p^n)) :=
 {b : ZMod (d * p^m) | (b : ZMod (d * p^n)) = a}
-- change def to a + k*dp^m
-- need h to be n ≤ m, not n < m for g_char_fn

variable [Fact p.Prime]

namespace Int
lemma fract_eq_self' {a : ℚ} (h : 0 ≤ a) (ha : a < 1) : Int.fract a = a :=
Int.fract_eq_iff.2 ⟨h, ha, ⟨0, by simp⟩⟩
end Int

--namespace Finset
/--- was initially named `sum_equiv` but that name is taken in mathlib
lemma sum_equiv' {α β γ : Type*} {s : Finset α} {s' : Finset β} {h : s ≃ s'} {f : α → γ}
  [AddCommMonoid γ] : ∑ x : s, f x = ∑ y : s', f (h.invFun y) := by
  apply Finset.sum_bij' _ _ _ _ _
  pick_goal 4
  { rintro a _
    exact h.toFun a }
  swap
  { intro a _
    exact h.inv_fun a }
  all_goals { simp }
end-/
--end Finset

lemma sum_rat_Fin (n : ℕ) : (((∑ x : Fin n, (x : ℤ)) : ℤ) : ℚ) = (n - 1) * (n : ℚ) / 2 := by
  have : ∀ (x : Fin n), (x : ℤ) = ((x : ℕ) : ℤ)
  { simp only [implies_true] }--simp only [_root_.coe_coe, eq_self_iff_true, implies_true_iff] }
  conv_lhs =>
  { congr
    congr
    · skip
    { ext x
      rw [this x] } }
  rw [←Finset.sum_range]
  induction n with
  | zero =>
    simp only [Finset.range_zero, Finset.sum_empty, Int.cast_zero, Nat.cast_zero, mul_zero,
      zero_div]
  | succ d hd =>
      rw [Finset.sum_range_succ, Int.cast_add, hd _]
      { simp only [Int.cast_Nat_cast, cast_succ, add_tsub_cancel_right]
        rw [div_add']
        { ring }
        { linarith } }
      { intro
        norm_cast }

namespace equi_class
lemma mem {n m : ℕ} (a : ZMod (d * p^n)) (b : ZMod (d * p^m)) :
  b ∈ equi_class m a ↔ (b : ZMod (d * p^n)) = a := Iff.rfl

variable [NeZero d]

lemma some {n : ℕ} (x : ZMod (d * p^n)) (y : equi_class n.succ x) : ∃ k : ℕ, k < p ∧
  (y : ZMod (d * p^n.succ)).val = x.val + k * d * p^n := by
  simp_rw [←((@mem p d n n.succ x y).1 (y.prop))]
  rw [← ZMod.nat_cast_val (y : ZMod (d * p^n.succ)), ZMod.val_nat_cast]
  refine' ⟨(y : ZMod (d * p^n.succ)).val / (d * p^n), Nat.div_lt_of_lt_mul _, _⟩
  { rw [Nat.mul_assoc, ←_root_.pow_succ']
    apply ZMod.val_lt (y : ZMod (d * p^n.succ)) }
  { rw [mul_assoc, Nat.mod_add_div' (y : ZMod (d * p^n.succ)).val (d * p^n)] }

/-- Giving an equivalence between `equi_class` and `Fin p`. -/
def equi_iso_Fin (m : ℕ) (a : ZMod (d * p^m)) : equi_class m.succ a ≃ Fin p :=
{ toFun := λ y => ⟨((y.val).val - a.val) / (d * p^m), Nat.div_lt_of_lt_mul
  (by
    rw [mul_assoc, ←_root_.pow_succ']
    exact lt_of_le_of_lt (Nat.sub_le (y.val).val a.val) (ZMod.val_lt y.val) )⟩,
  invFun := λ k => ⟨(a.val + k * d * p^m : ℕ), (by
    have g : (d * (p^m)) ∣ (d * p^(m.succ)) := mul_dvd_mul dvd_rfl (pow_dvd_pow p (Nat.le_succ _))
    · rw [mem, ZMod.cast_nat_cast g _, Nat.cast_add, ZMod.nat_cast_zmod_val, mul_assoc,
      Nat.cast_mul, ZMod.nat_cast_self, mul_zero, add_zero])⟩,
  left_inv := λ x => by
    rw [Subtype.ext_iff_val]
    --simp only [Nat.cast_add, nat_cast_val, Nat.cast_mul, Nat.cast_pow]
    simp only [_root_.cast_cast]
    rw [mul_assoc]
    obtain ⟨k, hk, h⟩ := some a x
    rw [Nat.div_mul_cancel]
    { rw [← Nat.add_sub_assoc _ _, Nat.add_sub_cancel_left]
      { rw [ZMod.nat_cast_val _]
        norm_cast }
      { rw [h]
        apply Nat.le_add_right } }
    { rw [h, Nat.add_sub_cancel_left, mul_assoc]
      simp }
  right_inv := λ x => by
    simp only [Nat.cast_pow]
    apply Fin.ext _
--    rw [@Subtype.ext_iff_val _ _ _ x]
    simp only [_root_.cast_cast]
    rw [Nat.div_eq_of_eq_mul_left (Nat.pos_of_ne_zero (NeZero.ne _)) (tsub_eq_of_eq_add _)]
--    { infer_instance }
    rw [mul_assoc, ZMod.val_nat_cast, Nat.mod_eq_of_lt]
    rw [add_comm]
    have h2 : ↑x * (d * p ^ m) ≤ (d * p ^ m) * (p - 1)
    { rw [mul_comm]
      apply Nat.mul_le_mul_left
      rw [←Nat.lt_succ_iff, Nat.succ_eq_add_one, Nat.sub_add_cancel]
      apply x.2
      { apply le_of_lt (fact_iff.1 (Nat.Prime.one_lt' p)) } }
    convert add_lt_add_of_lt_of_le (ZMod.val_lt a) h2 using 1
    rw [Nat.mul_sub_left_distrib, mul_one]
    rw [Nat.add_sub_cancel' _]
--    rw [Nat.sub_add_cancel]
    { rw [_root_.pow_succ, mul_comm p, mul_assoc] }
    { rw [le_mul_iff_one_le_right (Nat.pos_of_ne_zero (NeZero.ne _))]
      apply le_of_lt (fact_iff.1 (Nat.Prime.one_lt' p)) }}

noncomputable instance {n m : ℕ} (a : ZMod (d * p^n)) : Fintype (equi_class m a) :=
Set.Finite.fintype (Set.Finite.subset (Set.univ_finite_iff_nonempty_fintype.2
  (Nonempty.intro inferInstance)) (Set.subset_univ _))

open PadicInt ZMod Nat
lemma ZMod'_succ_eq_bUnion [NeZero d] (m : ℕ) :
  ZMod' (d * (p^m.succ)) (NeZero.ne _) = Finset.biUnion (ZMod' (d*p^m) (NeZero.ne _))
    (λ a : ZMod (d * p ^ m) => Set.toFinset ((equi_class m.succ) a)) :=
Finset.ext (λ y => Iff.trans (by
  simp only [exists_prop, Set.mem_toFinset]
  refine' ⟨λ h => ⟨(y : ZMod (d * p^m)), _, (equi_class.mem _ _).2 rfl⟩, λ h =>   Finset.mem_univ y⟩
  --rw [ZMod']
  apply Finset.mem_univ ) -- why is this a problem
  (Iff.symm Finset.mem_biUnion))

lemma eq [Fact (0 < d)] {m : ℕ} (hd : d.Coprime p)
  {f : LocallyConstant (ZMod d × ℤ_[p]) R} (h : Classical.choose (le hd f) ≤ m) (x : ZMod (d * p^m))
  (y : ZMod (d * p^m.succ)) (hy : y ∈ Set.toFinset ((equi_class m.succ) x)) : f y = f x :=
by
  -- note that y ≠ ↑x !
  rw [Set.mem_toFinset, equi_class.mem] at hy
  rw [←LocallyConstant.lift_comp_proj, Function.comp_apply]
  apply congr_arg
  have h' := Classical.choose_spec (le hd f)
  simp_rw [←DiscreteQuotient.ofLE_proj (le_trans (le_of_ge p d h) h')]--, Function.comp_apply]
  refine' congr_arg _ _
  change ↑y ∈ ((discrete_quotient_of_toZModPow p d m).proj)⁻¹'
    {(discrete_quotient_of_toZModPow p d m).proj x}
  simp_rw [DiscreteQuotient.fiber_eq, Set.mem_setOf_eq, discrete_quotient_of_toZModPow.rel,
    Prod.fst_zmod_cast, Prod.snd_zmod_cast, ←hy]
  have val_le_val : (y.val : ZMod (d * p^m)).val ≤ y.val := val_coe_val_le_val _
  have dvds : (d * p^m) ∣ y.val - (y.val : ZMod (d * p^m)).val
  { rw [←ZMod.nat_cast_zmod_eq_zero_iff_dvd, Nat.cast_sub val_le_val]
    simp only [ZMod.cast_id', id.def, sub_self, ZMod.nat_cast_val] }
  constructor
  { rw [←sub_eq_zero, ←RingHom.map_sub, ←RingHom.mem_ker, ker_toZModPow,
      Ideal.mem_span_singleton]
    --repeat { rw [←ZMod.nat_cast_val] }
    rw [←dvd_neg, neg_sub, ←Nat.cast_pow, ←ZMod.nat_cast_val, ←ZMod.nat_cast_val, ←ZMod.nat_cast_val, ←Nat.cast_sub val_le_val]
    apply Nat.coe_nat_dvd (dvd_trans (dvd_mul_left _ _) dvds) }
  { repeat { rw [←ZMod.nat_cast_val] }
    rw [←ZMod.nat_cast_val, ←ZMod.nat_cast_val, ←ZMod.nat_cast_val, ZMod.nat_cast_eq_nat_cast_iff, Nat.modEq_iff_dvd' val_le_val]
    apply dvd_trans (dvd_mul_right _ _) dvds }
-- This lemma has a lot of mini lemmas that can be generalized.

open equi_class
lemma card [NeZero d] {m : ℕ} (x : ZMod (d * p^m)) :
  Finset.card (@Finset.univ (equi_class m.succ x) _) = p := by
  rw [Finset.card_univ, ←Fintype.ofEquiv_card (equi_iso_Fin m x)]
  convert Fintype.card_fin p

lemma equi_iso_fun_inv_val [NeZero d] {m : ℕ} (x : ZMod (d * p^m)) (k : Fin p) :
  ((equi_iso_Fin m x).invFun k).val = x.val + ↑k * (d * p^m) := by
  unfold equi_iso_Fin
  dsimp
  norm_cast
  rw [mul_assoc]

variable (p d)
lemma helper_2 [NeZero d] (m : ℕ) (y : Fin p) : ((y * (d * p ^ m) : ZMod (d * p^m.succ)) : ℤ) =
  ↑y * (↑(d : ZMod (d * p^m.succ)) * ↑(p : ZMod (d * p^m.succ))^m) := by
  have prime_gt_one : 1 < p := Prime.one_lt Fact.out
  have le_mul_p : p ≤ d * p^m.succ
  { rw [mul_comm]
    apply le_mul_of_le_of_one_le (Nat.le_self_pow (NeZero.ne _)
      _) (Nat.succ_le_iff.2 (Nat.pos_of_ne_zero (NeZero.ne _))) } --(Nat.succ_le_iff.2 (succ_pos _)) }
  rw [←ZMod.nat_cast_val, ZMod.val_mul, Nat.mod_eq_of_lt _, Nat.cast_mul]
  { apply congr_arg₂
    { norm_cast --Int.nat_cast_eq_coe_nat,
      rw [cast_val_eq_of_le _ le_mul_p] }
    { rw [ZMod.val_mul, Nat.mod_eq_of_lt _]
      { rw [Nat.cast_mul, ZMod.nat_cast_val, ZMod.nat_cast_val, ←Nat.cast_pow]
        apply congr_arg₂ _ rfl _
        by_cases h : m = 0
        { rw [h, _root_.pow_zero, _root_.pow_zero, Nat.cast_one]
          have : Fact (1 < d * p^1)
          { apply fact_iff.2 (one_lt_mul (Nat.succ_le_iff.2 (Nat.pos_of_ne_zero (NeZero.ne _))) _)
            { rw [pow_one p]
              assumption } }
          apply cast_int_one }
        { rw [nat_cast_ZMod_cast_int (Nat.lt_mul_pow_right (Nat.pos_of_ne_zero (NeZero.ne _)) prime_gt_one
            (Nat.succ_lt_succ (Nat.pos_of_ne_zero h))), nat_cast_ZMod_cast_int
            (pow_lt_mul_pow_succ_right _), Int.coe_nat_pow] } }
      { rw [←Nat.cast_pow, ZMod.val_cast_of_lt _, ZMod.val_cast_of_lt (pow_lt_mul_pow_succ_right _)]
        apply mul_pow_lt_mul_pow_succ
        { apply lt_mul_of_one_lt_right (Nat.pos_of_ne_zero (NeZero.ne _)) (Nat.one_lt_pow _ _ (NeZero.ne _)
            (Nat.Prime.one_lt Fact.out)) } } } }
  { rw [←Nat.cast_pow, ←Nat.cast_mul, ZMod.val_cast_of_lt (mul_pow_lt_mul_pow_succ _),
      cast_val_eq_of_le _ le_mul_p]
    { apply fin_prime_mul_prime_pow_lt_mul_prime_pow_succ } }

-- should p be implicit or explicit?
variable {p d}
theorem sum_fract [NeZero d] {m : ℕ} (x : ZMod (d * p^m)) :
  ∑ x_1 : (equi_class m.succ x), Int.fract (((x_1 : ZMod (d * p^m.succ)).val : ℚ) /
    ((d : ℚ) * (p : ℚ)^m.succ)) = (x.val : ℚ) / (d * p^m) + (p - 1) / 2 := by
  conv_lhs =>
  { congr
    · skip
    ext q
    rw [← Nat.cast_pow, ← Nat.cast_mul,
    Int.fract_eq_self' ((zero_le_div_and_div_lt_one (q : ZMod (d * p ^ m.succ))).1)
    ((zero_le_div_and_div_lt_one (q : ZMod (d * p ^ m.succ))).2),  Nat.cast_mul, Nat.cast_pow] }
  rw [Fintype.sum_equiv (equi_iso_Fin m x) (λ y => _)
    (λ k => (((equi_iso_Fin m x).invFun k).val : ℚ) / (d * p ^ m.succ))]
  { rw [←Finset.sum_div]
    have h1 : ∀ y : Fin p, ((x.val : ZMod (d * p^m.succ)) : ℤ) + ↑((y : ZMod (d * p^m.succ)) *
      (d * p ^ m : ZMod (d * p^m.succ))) < ↑(d * p ^ m.succ : ℕ)
    { intro y
      rw [ZMod.nat_cast_val x, ←ZMod.nat_cast_val, ←ZMod.nat_cast_val (_ * ((d : ZMod (d * p ^ succ m)) * _)), ←Nat.cast_add]
      { convert (cast_lt).2 (val_add_fin_mul_lt x y) using 1
        apply congr (funext (λ z => rfl)) (congr_arg₂ _ _ _)
        { rw [←ZMod.nat_cast_val, coe_val_eq_val_of_lt (mul_pow_lt_mul_pow_succ _) _] }
        { rw [←Nat.cast_pow, ←Nat.cast_mul, fin_prime_coe_coe, ←Nat.cast_mul, ZMod.val_cast_of_lt]
          apply fin_prime_mul_prime_pow_lt_mul_prime_pow_succ }
        infer_instance
        infer_instance
        infer_instance } }
    conv_lhs =>
    { congr
      congr
      · rfl
      ext
      rw [equi_iso_fun_inv_val, ←ZMod.int_cast_cast, coe_add_eq_pos' (h1 _), Int.cast_add, helper_2 p d m _] }
      --rw [equi_iso_fun_inv_val, ←ZMod.int_cast_cast, coe_add_eq_pos' (h1 _), Int.cast_add, helper_2 p d m _] }
    { rw [Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin _]
      norm_cast
      rw [←Finset.sum_mul, _root_.add_div]
      apply congr_arg₂ _ ((div_eq_iff _).2 _) _
      { norm_cast
        apply NeZero.ne _ }
      { rw [div_mul_comm, _root_.nsmul_eq_mul]
        apply congr_arg₂ _ _ _
        { norm_num
          rw [mul_div_mul_left _, _root_.pow_succ, mul_div_cancel _]
          { norm_cast
            apply pow_ne_zero m (Nat.Prime.ne_zero (fact_iff.1 _))
            assumption }
          { norm_num
            apply NeZero.ne _ } }
        { rw [ZMod.int_cast_cast, ZMod.nat_cast_val, ←ZMod.nat_cast_val (x : ZMod (d * p^m.succ))]
          refine' congr_arg _ _
          rw [←ZMod.nat_cast_val x, coe_val_eq_val_of_lt _ _]
          --{ infer_instance }
          { rw [mul_comm d (p^m), mul_comm d (p^m.succ)]
            apply mul_lt_mul (pow_lt_pow_right (Nat.Prime.one_lt Fact.out) (Nat.lt_succ_self m))
              le_rfl ((Nat.pos_of_ne_zero (NeZero.ne _))) (Nat.zero_le _) } } }
      { rw [Int.cast_mul, mul_div_assoc, sum_rat_Fin, Nat.cast_mul, Int.cast_mul]
        have one : ((p : ℚ) - 1) * (p : ℚ) / 2 * (1 / (p : ℚ)) = ((p : ℚ) - 1) / 2
        { rw [_root_.div_mul_div_comm, mul_one, mul_div_mul_right]
          norm_cast
          apply _root_.ne_of_gt (Nat.Prime.pos Fact.out) }
        convert one using 2
        rw [div_eq_div_iff _ _]
        { rw [one_mul, ZMod.int_cast_cast, Int.cast_pow, ZMod.int_cast_cast, _root_.pow_succ',
            Nat.cast_mul, Nat.cast_pow, mul_assoc]
          apply congr_arg₂ _ _ _
          { rw [←ZMod.nat_cast_val _]
            { rw [ZMod.val_nat_cast]
              apply congr_arg _ (Nat.mod_eq_of_lt ((lt_mul_iff_one_lt_right (Nat.pos_of_ne_zero (NeZero.ne _))).2 _))
              { rw [←_root_.pow_succ']
                apply _root_.one_lt_pow (Nat.Prime.one_lt (fact_iff.1 _)) (succ_ne_zero _)
                { assumption } } } }
          { apply congr_arg₂ _ _ rfl
            { by_cases h : m = 0
              { rw [h, _root_.pow_zero, _root_.pow_zero] }
              apply congr_arg₂ _ _ rfl
              { rw [←ZMod.nat_cast_val _]
                { rw [ZMod.val_nat_cast]
                  apply congr_arg _ (Nat.mod_eq_of_lt _)
                  rw [←mul_assoc, lt_mul_iff_one_lt_left (Prime.pos Fact.out)]
                  { apply one_lt_mul (Nat.succ_le_iff.2 (Nat.pos_of_ne_zero (NeZero.ne _))) _
                    { apply _root_.one_lt_pow (Nat.Prime.one_lt Fact.out) h } } } } } } }
        { rw [←Nat.cast_mul]
          norm_cast
          apply _root_.ne_of_gt (Nat.pos_of_ne_zero (NeZero.ne _)) }
        { norm_cast
          apply _root_.ne_of_gt (Nat.Prime.pos Fact.out) }
        { rw [Rat.divInt_eq_div]
          norm_num } } } }
  { rintro y
    simp only [Equiv.symm_apply_apply, Equiv.invFun_as_coe,
      ZMod.nat_cast_val] }
-- break up into smaller pieces

variable {m : ℕ}
lemma helper_bernoulli_distribution_sum' (hc' : c.Coprime d) (hc : c.Coprime p) (x : ZMod (d * p^m)) :
  ∑ x_1 : (equi_class m.succ x), Int.fract (((c : ZMod (d * p^(2 * m.succ)))⁻¹.val : ℚ) *
  ↑(x_1 : ZMod (d * p^m.succ)) / (↑d * ↑p ^ m.succ)) =
  ∑ x_1 : (equi_class m.succ (↑((c : ZMod (d * p^(2 * m.succ)))⁻¹.val) * x : ZMod (d * p^m))),
  Int.fract (↑((x_1 : ZMod (d * p^m.succ)).val) / (↑d * ↑p ^ m.succ) : ℚ) :=
by
  have h1 : d * p ^ m ∣ d * p ^ m.succ
  { apply mul_dvd_mul_left
    rw [_root_.pow_succ']
    apply dvd_mul_right }
  have h2 : ∀ z : ℕ, d * p ^ z ∣ d * p ^ (2 * z)
  { intro z
    apply mul_dvd_mul_left _ (pow_dvd_pow p _)
    linarith }
  have h3 : d * p ^ m ∣ d * p ^ (2 * m.succ)
  { apply mul_dvd_mul_left _ (pow_dvd_pow p _)
    rw [Nat.succ_eq_add_one, mul_add]
    linarith }
  have h4 : (((c : ZMod (d * p^(2 * m.succ)))⁻¹  : ZMod (d * p^(2 * m.succ))) :
    ZMod (d * p^m.succ)).val ≤ (c : ZMod (d * p^(2 * m.succ)))⁻¹.val := val_coe_val_le_val' _
  refine' Finset.sum_bij (λ a ha => _) (λ a ha => Finset.mem_univ _) (λ a1 a2 ha1 ha2 h => _) _ (λ a ha => _)--(λ a1 a2 ha1 ha2 h => _) _
  { refine' ⟨(((c : ZMod (d * p^(2*m.succ)))⁻¹).val : ZMod (d * p^m.succ)) * a,
      (equi_class.mem _ _).2 _⟩
    rw [ZMod.cast_mul h1, cast_nat_cast h1 _]
    conv_rhs =>
    { congr
      · skip
      rw [←((@equi_class.mem p d _ m.succ x a).1 a.prop)] } }
  { simp only [Subtype.mk_eq_mk, nat_cast_val] at h
    rw [Subtype.ext ((IsUnit.mul_right_inj (isUnit_iff_exists_inv'.2
      ⟨((c : ZMod (d * p^(2 * (m.succ)))) : ZMod (d * p^(m.succ))), _⟩)).1 h)]
    rw [cast_inv (Nat.Coprime.mul_pow _ hc' hc) (h2 _), cast_nat_cast (h2 m.succ)]
    apply ZMod.mul_inv_of_unit _ (IsUnit_mul m.succ hc' hc) }
  { simp only [cast_nat_cast, nat_cast_val, Subtype.coe_mk, Finset.mem_univ, exists_true_left,
      SetCoe.exists, forall_true_left, SetCoe.forall, Subtype.mk_eq_mk, exists_prop]
    rintro a ha
    rw [equi_class.mem] at ha
    refine' ⟨((c : ZMod (d * p^(2 * m.succ))) : ZMod (d * p^m.succ)) * a, _, _⟩
    { rw [equi_class.mem, ZMod.cast_mul h1]
      { rw [ha, ←mul_assoc, cast_inv (Nat.Coprime.mul_pow _ hc' hc) h3,
          cast_nat_cast (h2 m.succ) _, cast_nat_cast h1 _, cast_nat_cast h3 _,
          ZMod.mul_inv_of_unit _ (IsUnit_mul m hc' hc), one_mul] } }
    { rw [←mul_assoc, ZMod.cast_inv (Nat.Coprime.mul_pow _ hc' hc) (h2 _),
        ZMod.inv_mul_of_unit _ _, one_mul a, true_and]
      rw [cast_nat_cast (h2 m.succ) c]
      apply IsUnit_mul _ hc' hc } }
  { rw [Int.fract_eq_fract, Subtype.coe_mk, div_sub_div_same, ← nat_cast_val
      (a : ZMod (d * p^m.succ)), ZMod.val_mul, ← Nat.cast_mul, ← Nat.cast_sub
      (le_trans (mod_le _ _) _), nat_cast_val, Nat.cast_sub (le_trans (mod_le _ _) _),
      ← sub_add_sub_cancel _ ((((c : ZMod (d * p^(2 * m.succ)))⁻¹ : ZMod (d * p^(2 * m.succ))) :
      ZMod (d * p^m.succ)).val * (a : ZMod (d * p^m.succ)).val : ℚ) _, ← Nat.cast_mul]
    obtain ⟨z₁, hz₁⟩ := @dvd_sub_mod (d * p^m.succ) ((((c : ZMod (d * p^(2 * m.succ)))⁻¹ :
      ZMod (d * p^(2 * m.succ))) : ZMod (d * p^m.succ)).val * (a : ZMod (d * p^m.succ)).val)
    obtain ⟨z₂, hz₂⟩ := dvd_val_sub_cast_val (d * p^m.succ) (c : ZMod (d * p^(2 * m.succ)))⁻¹
    rw [← Nat.cast_sub (mod_le _ _), hz₁, ← Nat.cast_sub, ← Nat.mul_sub_right_distrib, hz₂,
      mul_assoc (d * p^(m.succ)) _ _, Nat.cast_mul, Nat.cast_mul _ z₁, ← mul_add,
      ← Nat.cast_pow, ← Nat.cast_mul d _, mul_comm,
      mul_div_cancel _ _] --((@cast_ne_zero ℚ _ _ _ _).2 (NeZero.ne _))
    refine' ⟨((z₂ * (a : ZMod (d * p ^ m.succ)).val + z₁ : ℕ) : ℤ), by { norm_cast } ⟩
    · apply NeZero.ne _
    { refine' mul_le_mul_right' h4 _ }
    { refine' mul_le_mul_right' h4 _ }
    { rw [nat_cast_val]
      refine' mul_le_mul_right' h4 _ } }

open equi_class
lemma bernoulli_distribution_sum' (x : ZMod (d * p^m)) (hc : c.Coprime p) (hc' : c.Coprime d) :
  ∑ y : equi_class m.succ x, (bernoulli_distribution p d c m.succ y) = (bernoulli_distribution p d c m x) :=
by
  simp_rw [bernoulli_distribution, ←map_sum]
  apply congr_arg
  rw [Finset.sum_add_distrib, Finset.sum_sub_distrib, equi_class.sum_fract, ←Finset.mul_sum]
  have h2 : ∀ z : ℕ, d * p ^ z ∣ d * p ^ (2 * z)
  { intro z
    apply mul_dvd_mul_left _ (pow_dvd_pow p _)
    linarith }
  have h3 : d * p ^ m ∣ d * p ^ (2 * m.succ)
  { apply mul_dvd_mul_left _ (pow_dvd_pow p _)
    rw [Nat.succ_eq_add_one, mul_add]
    linarith }
  convert_to ((x.val : ℚ) / (d * p ^ m) + (p - 1) / 2) - (c : ℚ) *
    ∑ x_1 : (equi_class m.succ ( ((c : ZMod (d * p^(2*m.succ)))⁻¹.val) * x : ZMod (d * p^m))),
    Int.fract (((x_1 : ZMod (d * p^m.succ)).val : ℚ) / ((d : ℚ) * (p : ℚ)^m.succ)) +
    (∑ x : (equi_class m.succ x), ((c : ℚ) - 1) / 2) = _ - _ + _
  { rw [add_right_cancel_iff, sub_right_inj]
    refine' congr_arg _ (helper_bernoulli_distribution_sum' hc' hc _) }
  rw [sum_fract, ←Nat.cast_pow, ←Nat.cast_mul, Int.fract_eq_self' (zero_le_div_and_div_lt_one x).1
    (zero_le_div_and_div_lt_one x).2, mul_add, Finset.sum_const, equi_class.card,
    _root_.nsmul_eq_mul, sub_add_eq_add_sub, sub_add_eq_add_sub, sub_add_eq_sub_sub, sub_right_comm]
  apply congr_arg₂ _ _ (congr_arg _ _)
  { rw [add_assoc, add_sub_assoc]
    congr
    linarith }
  { rw [←fract_eq_val _, ← ZMod.nat_cast_val, ← ZMod.nat_cast_val, ← Nat.cast_mul]
    apply fract_eq_of_ZMod_eq
    rw [Nat.cast_mul, ZMod.nat_cast_val, ZMod.nat_cast_val, ZMod.nat_cast_val, ZMod.cast_mul',
      ZMod.nat_cast_val, ZMod.cast_id]
    apply congr_arg₂ _ _ rfl
    rw [cast_inv (Nat.Coprime.mul_pow _ hc' hc) h3, cast_inv (Nat.Coprime.mul_pow _ hc' hc) (h2 _),
      cast_nat_cast h3, cast_nat_cast (h2 _)] }

variable [Algebra ℚ_[p] R]
--`E_c_sum_equi_class` replaced with `bernoulli_distribution_sum`
lemma bernoulli_distribution_sum (x : ZMod (d * p^m)) (hc : c.gcd p = 1) (hc' : c.gcd d = 1) :
  ∑ y : ZMod (d * p ^ m.succ) in (λ a : ZMod (d * p ^ m) => ((equi_class m.succ) a).toFinset) x,
  ((algebraMap ℚ_[p] R) (bernoulli_distribution p d c m.succ y)) = (algebraMap ℚ_[p] R) (bernoulli_distribution p d c m x) :=
by
  rw [←bernoulli_distribution_sum']
  { rw [map_sum]
    refine' Finset.sum_bij (λ a ha => Subtype.mk a _) (λ a ha => Finset.mem_univ _) (λ a b ha hb h => _) (λ a ha => _) (λ b hb => _)
    { refine' Set.mem_toFinset.1 ha }
    { simp only [Subtype.mk_eq_mk, Subtype.ext_iff, Subtype.coe_mk] at h
      rw [h] }
    { simp only [Set.mem_toFinset]
      refine' ⟨a.val, a.prop, by { rw [Subtype.ext_iff_val] }⟩ }
    { simp only [Subtype.coe_mk] } }
  any_goals { assumption }

open clopen_from
-- does not require [Fact (0 < d)]
lemma clopen {n : ℕ} (a : ZMod (d * p^n)) (hm : n ≤ m) (b : (equi_class m a)) :
  (b.val : ZMod d × ℤ_[p]) ∈ (clopen_from a) :=
by
  simp_rw [mem_clopen_from, ←(mem _ _).1 b.prop]
  refine' ⟨_, _⟩
  { conv_rhs =>
    { congr
      rw [←nat_cast_val] }
    rw [Prod.fst_zmod_cast, cast_nat_cast (dvd_mul_right d _) _, nat_cast_val] }
  { rw [Prod.snd_zmod_cast]
    convert_to _ = ((b: ZMod (d * p^m)) : ZMod (p^n))
    { rw [←ZMod.int_cast_cast (b: ZMod (d * p^m))]
      conv_rhs => { rw [←ZMod.int_cast_cast (b: ZMod (d * p^m))] }
      change (RingHom.comp (toZModPow n) (Int.castRingHom ℤ_[p])) ((b : ZMod (d * p^m)) : ℤ) =
        (Int.castRingHom (ZMod (p^n))) ((b : ZMod (d * p^m)) : ℤ)
      apply _root_.congr_fun _ _
      congr
      rw [@RingHom.ext_zmod 0 (ZMod (p^n)) _ (Int.castRingHom (ZMod (p ^ n))) (RingHom.comp (toZModPow n) (Int.castRingHom ℤ_[p]))] }
    { rw [←castHom_apply' (ZMod (p^n)) (dvd_mul_left (p^n) d) _, ←castHom_apply' (ZMod (d * p^n))
        (mul_dvd_mul_left d (pow_dvd_pow p hm)) _, ←castHom_apply' (ZMod (p^n))
        (dvd_mul_of_dvd_right (pow_dvd_pow p hm) d) _, ←RingHom.comp_apply]
      apply _root_.congr_fun _ _
      congr
      simp only [castHom_comp] } }
end equi_class
