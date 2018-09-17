Require Import VST.veric.juicy_base.
Require Import VST.veric.juicy_mem VST.veric.juicy_mem_lemmas VST.veric.juicy_mem_ops.
Require Import VST.veric.res_predicates.
Require Import VST.veric.extend_tc.
Require Import VST.veric.seplog.
Require Import VST.veric.assert_lemmas.
Require Import VST.veric.Clight_new.
Require Import VST.sepcomp.extspec.
Require Import VST.sepcomp.step_lemmas.
Require Import VST.veric.tycontext.
Require Import VST.veric.expr2.
Require Import VST.veric.expr_lemmas.
Require Import VST.veric.juicy_extspec.
Require Import VST.veric.semax.
Require Import VST.veric.semax_lemmas.
Require Import VST.veric.Clight_lemmas.
Require Import VST.veric.own.

Local Open Scope pred.

Lemma _guard_mono: forall Espec ge Delta (P Q: assert) f k,
  (forall rho, P rho |-- Q rho) ->
  _guard Espec ge Delta Q f k |-- _guard Espec ge Delta P f k.
Proof.
  intros.
  unfold _guard.
  apply allp_derives; intros tx.
  apply allp_derives; intros vx.
  apply fash_derives.
  apply imp_derives; auto.
Qed.

Lemma guard_mono: forall Espec ge Delta (P Q: assert) k,
  (forall rho, P rho |-- Q rho) ->
  guard Espec ge Delta Q k |-- guard Espec ge Delta P k.
Proof.
  intros.
  unfold guard.
  apply _guard_mono; auto.
Qed.

Lemma rguard_mono: forall Espec ge Delta (P Q: ret_assert) k,
  (forall rk vl rho, proj_ret_assert P rk vl rho |-- proj_ret_assert Q rk vl rho) ->
  rguard Espec ge Delta Q k |-- rguard Espec ge Delta P k.
Proof.
  intros.
  unfold rguard.
  apply allp_derives; intros ek.
  apply allp_derives; intros vl.
  apply _guard_mono; auto.
Qed.

Definition bupd_ret_assert (Q: ret_assert): ret_assert :=
          {| RA_normal := fun rho => bupd (RA_normal Q rho);
             RA_break := fun rho => bupd (RA_break Q rho);
             RA_continue := fun rho => bupd (RA_continue Q rho);
             RA_return := fun v rho => bupd (RA_return Q v rho) |}.

Lemma proj_bupd_ret_assert: forall Q ek vl,
  proj_ret_assert (bupd_ret_assert Q) ek vl = fun rho => bupd (proj_ret_assert Q ek vl rho).
Proof.
  intros.
  destruct ek;
  auto.
Qed.

Lemma assert_safe_bupd':
  forall {Espec: OracleKind} gx vx tx rho (P: environ -> pred rmap) Delta f k,
    let PP1 := !! guard_environ Delta f rho in
    let PP2 := funassert Delta rho in
    PP1 && (P rho) && PP2 >=>
    assert_safe Espec gx vx tx k rho =
    PP1 && (bupd (P rho)) && PP2 >=>
    assert_safe Espec gx vx tx k rho.
Proof.
  intros.
  apply pred_ext.
  + hnf; intros.
    hnf; intros.
    hnf; intros.
    destruct H2 as [[? ?] ?].
    apply bupd_trans.
    hnf.
    intros.
    specialize (H3 _ H5).
    destruct H3 as [b [? [m' [? [? [? ?]]]]]].
    exists b; split; auto.
    exists m'; split; [| split; [| split]]; auto.
    change (assert_safe Espec gx vx tx k rho m').
    specialize (H m' ltac: (apply necR_level in H1; omega)).
    specialize (H m' ltac: (apply necR_refl)).
    apply H.
    split; [split |]; auto.
    subst PP2.
    pose proof funassert_resource Delta rho _ _ (eq_sym H6) (eq_sym H7).
    apply H10, H4.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    apply H.
    destruct H2 as [[? ?] ?].
    split; [split |]; auto.
    apply bupd_intro; auto.
Qed.

Lemma _guard_bupd':
  forall {Espec: OracleKind} ge Delta (P: environ -> pred rmap) f k,
    _guard Espec ge Delta P f k = _guard Espec ge Delta (fun rho => bupd (P rho)) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  apply assert_safe_bupd'.
Qed.
  
Lemma guard_bupd':
  forall {Espec: OracleKind} ge Delta (P: environ -> pred rmap) k,
    guard Espec ge Delta P k = guard Espec ge Delta (fun rho => bupd (P rho)) k.
Proof.
  intros.
  apply _guard_bupd'.
Qed.

Lemma rguard_bupd':
  forall {Espec: OracleKind} ge Delta (P: ret_assert) k,
    rguard Espec ge Delta P k = rguard Espec ge Delta (bupd_ret_assert P) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite proj_bupd_ret_assert.
  apply _guard_bupd'.
Qed.

Lemma assert_safe_bupd:
  forall {Espec: OracleKind} gx vx tx rho (F P: environ -> pred rmap) Delta f k,
    let PP1 := !! guard_environ Delta f rho in
    let PP2 := funassert Delta rho in
    PP1 && (F rho * P rho) && PP2 >=>
    assert_safe Espec gx vx tx k rho =
    PP1 && (F rho * bupd (P rho)) && PP2 >=>
    assert_safe Espec gx vx tx k rho.
Proof.
  intros.
  apply pred_ext.
  + hnf; intros.
    hnf; intros.
    hnf; intros.
    destruct H2 as [[? ?] ?].
    apply bupd_trans.
    hnf.
    intros.
    apply bupd_frame_l in H3.
    specialize (H3 _ H5).
    destruct H3 as [b [? [m' [? [? [? ?]]]]]].
    exists b; split; auto.
    exists m'; split; [| split; [| split]]; auto.
    change (assert_safe Espec gx vx tx k rho m').
    specialize (H m' ltac: (apply necR_level in H1; omega)).
    specialize (H m' ltac: (apply necR_refl)).
    apply H.
    split; [split |]; auto.
    subst PP2.
    pose proof funassert_resource Delta rho _ _ (eq_sym H6) (eq_sym H7).
    apply H10, H4.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    apply H.
    destruct H2 as [[? ?] ?].
    split; [split |]; auto.
    revert H3.
    apply sepcon_derives; auto.
    apply bupd_intro.
Qed.

Lemma _guard_bupd:
  forall {Espec: OracleKind} ge Delta (F P: environ -> pred rmap) f k,
    _guard Espec ge Delta (fun rho => F rho * P rho) f k = _guard Espec ge Delta (fun rho => F rho * bupd (P rho)) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  apply assert_safe_bupd.
Qed.
  
Lemma guard_bupd:
  forall {Espec: OracleKind} ge Delta (F P: environ -> pred rmap) k,
    guard Espec ge Delta (fun rho => F rho * P rho) k = guard Espec ge Delta (fun rho => F rho * bupd (P rho)) k.
Proof.
  intros.
  apply _guard_bupd.
Qed.

Lemma rguard_bupd:
  forall {Espec: OracleKind} ge Delta F (P: ret_assert) k,
    rguard Espec ge Delta (frame_ret_assert P F) k = rguard Espec ge Delta (frame_ret_assert (bupd_ret_assert P) F) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite !proj_frame.
  rewrite proj_bupd_ret_assert.
  apply _guard_bupd.
Qed.

Definition except_0_ret_assert (Q: ret_assert): ret_assert :=
          {| RA_normal := fun rho => (|> FF || RA_normal Q rho);
             RA_break := fun rho => (|> FF || RA_break Q rho);
             RA_continue := fun rho => (|> FF || RA_continue Q rho);
             RA_return := fun v rho => (|> FF || RA_return Q v rho) |}.

Lemma proj_except_0_ret_assert: forall Q ek vl,
  proj_ret_assert (except_0_ret_assert Q) ek vl = fun rho => |> FF || proj_ret_assert Q ek vl rho.
Proof.
  intros.
  destruct ek;
  auto.
Qed.

(* The following two lemmas is not now used. but after deep embedded hoare logic (SL_as_Logic) is
ported, the frame does not need to be quantified in the semantic definition of semax. Then,
these two lemmas can replace the other two afterwards. *)

Lemma assert_safe_except_0':
  forall {Espec: OracleKind} gx vx tx PP1 PP2 rho (P: environ -> pred rmap) k,
    PP1 && (P rho) && PP2 >=>
    assert_safe Espec gx vx tx k rho =
    PP1 && ((|> FF || P rho)) && PP2 >=>
    assert_safe Espec gx vx tx k rho.
Proof.
  intros.
  apply pred_ext.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    clear - H H2.
    destruct (level a') eqn:?H in |- *.
    - hnf.
      intros.
      eexists; split; [exact H1 |].
      eexists; split; [reflexivity |].
      split; auto.
      split; auto.
      simpl.
      intros.
      hnf.
      rewrite H0; constructor.
    - apply H.
      destruct H2 as [[? ?] ?].
      split; [split |]; auto.
      destruct H2; auto.
      hnf in H2.
      unfold laterM in H2; simpl in H2.
      pose proof levelS_age a' n (eq_sym H0) as [? [? ?]].
      exfalso; apply (H2 x).
      apply age_laterR.
      auto.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    apply H.
    destruct H2 as [[? ?] ?].
    split; [split |]; auto.
    right; auto.
Qed.

Lemma _guard_except_0':
  forall {Espec: OracleKind} ge Delta (P: environ -> pred rmap) f k,
    _guard Espec ge Delta P f k = _guard Espec ge Delta (fun rho => |> FF || P rho) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  apply assert_safe_except_0'.
Qed.
  
Lemma guard_except_0':
  forall {Espec: OracleKind} ge Delta (P: environ -> pred rmap) k,
    guard Espec ge Delta P k = guard Espec ge Delta (fun rho => |> FF || P rho) k.
Proof.
  intros.
  apply _guard_except_0'.
Qed.

Lemma rguard_except_0':
  forall {Espec: OracleKind} ge Delta (P: ret_assert) k,
    rguard Espec ge Delta P k = rguard Espec ge Delta (except_0_ret_assert P) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite proj_except_0_ret_assert.
  apply _guard_except_0'.
Qed.

Lemma assert_safe_except_0:
  forall {Espec: OracleKind} gx vx tx PP1 PP2 rho (F P: environ -> pred rmap) k,
    PP1 && (F rho * P rho) && PP2 >=>
    assert_safe Espec gx vx tx k rho =
    PP1 && (F rho * (|> FF || P rho)) && PP2 >=>
    assert_safe Espec gx vx tx k rho.
Proof.
  intros.
  apply pred_ext.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    clear - H H2.
    destruct (level a') eqn:?H in |- *.
    - hnf.
      intros.
      eexists; split; [exact H1 |].
      eexists; split; [reflexivity |].
      split; auto.
      split; auto.
      simpl.
      intros.
      hnf.
      rewrite H0; constructor.
    - apply H.
      destruct H2 as [[? ?] ?].
      split; [split |]; auto.
      destruct H2 as [? [? [? [? ?]]]]; auto.
      pose proof join_level _ _ _ H2 as [_ ?].
      rewrite <- H6 in H0; clear H6.
      hnf; eexists; eexists.
      split; [| split]; [exact H2 | exact H4 |].
      destruct H5; auto.
      hnf in H5.
      unfold laterM in H5; simpl in H5.
      pose proof levelS_age x0 n (eq_sym H0) as [? [? ?]].
      exfalso; apply (H5 x1).
      apply age_laterR.
      auto.
  + hnf; intros.
    hnf; intros.
    specialize (H y H0).
    hnf; intros.
    specialize (H a' H1).
    apply H.
    destruct H2 as [[? ?] ?].
    split; [split |]; auto.
    destruct H3 as [? [? [? [? ?]]]].
    hnf; eexists; eexists.
    split; [| split]; [exact H3 | exact H5 |].
    right; auto.
Qed.

Lemma _guard_except_0:
  forall {Espec: OracleKind} ge Delta (F P: environ -> pred rmap) f k,
    _guard Espec ge Delta (fun rho => F rho * P rho) f k = _guard Espec ge Delta (fun rho => F rho * (|> FF || P rho)) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  apply assert_safe_except_0.
Qed.

Lemma guard_except_0: 
  forall {Espec: OracleKind} ge Delta (F P: environ -> pred rmap) k,
    guard Espec ge Delta (fun rho => F rho * P rho) k =
    guard Espec ge Delta (fun rho => F rho * (|> FF || P rho)) k.
Proof.
  intros.
  apply _guard_except_0.
Qed.

Lemma rguard_except_0:
  forall {Espec: OracleKind} ge Delta (F: environ -> pred rmap) Q k,
    rguard Espec ge Delta (frame_ret_assert Q F) k =
    rguard Espec ge Delta (frame_ret_assert (except_0_ret_assert Q) F) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite !proj_frame.
  rewrite proj_except_0_ret_assert.
  apply _guard_except_0.
Qed.

Lemma semax_pre_except_0:
  forall {CS: compspecs} {Espec: OracleKind} Delta P c Q,
    semax Espec Delta (fun rho => |> FF || P rho) c Q <->
    semax Espec Delta P c Q.
Proof.
  intros.
  unfold semax.
  apply Morphisms_Prop.all_iff_morphism; intros n.
  rewrite semax_fold_unfold.
  match goal with
  | |- ?A <-> ?B => assert (A = B); [| rewrite H; tauto]
  end.
  f_equal.
  f_equal. extensionality gx.
  f_equal. extensionality Delta'.
  f_equal.
  f_equal.
  f_equal. extensionality k.
  f_equal. extensionality F.
  f_equal.
  symmetry; apply guard_except_0.
Qed.

Lemma semax_post_except_0:
  forall {CS: compspecs} {Espec: OracleKind} Delta P c Q,
    semax Espec Delta P c Q <->
    semax Espec Delta P c
          {| RA_normal := fun rho => |> FF || RA_normal Q rho;
             RA_break := fun rho => |> FF || RA_break Q rho;
             RA_continue := fun rho => |> FF || RA_continue Q rho;
             RA_return := fun v rho => |> FF || RA_return Q v rho |}.
Proof.
  intros.
  unfold semax.
  apply Morphisms_Prop.all_iff_morphism; intros n.
  rewrite semax_fold_unfold.
  match goal with
  | |- ?A <-> ?B => assert (A = B); [| rewrite H; tauto]
  end.
  f_equal.
  f_equal. extensionality gx.
  f_equal. extensionality Delta'.
  f_equal.
  f_equal.
  f_equal. extensionality k.
  f_equal. extensionality F.
  f_equal.
  f_equal.
  apply rguard_except_0.
Qed.

Definition allp_fun_id (Delta : tycontext) (rho : environ): pred rmap :=
(ALL id : ident ,
 (ALL fs : funspec ,
  !! ((glob_specs Delta) ! id = Some fs) -->
  (EX b : block, !! (Map.get (ge_of rho) id = Some b) && func_at fs (b, 0)))).

Lemma corable_allp_fun_id: forall Delta rho,
  corable (allp_fun_id Delta rho).
Proof.
  intros.
  apply corable_allp; intros id.
  apply corable_allp; intros fs.
  apply corable_imp; [apply corable_prop |].
  apply corable_exp; intros b.
  apply corable_andp; [apply corable_prop |].
  apply corable_func_at.
Qed.
  
Lemma funassert_allp_fun_id_sub: forall Delta Delta' rho,
  tycontext_sub Delta Delta' ->
  funassert Delta' rho |-- allp_fun_id Delta rho.
Proof.
  intros.
  unfold funassert, allp_fun_id.
  apply andp_left1.
  apply allp_derives; intros id.
  apply allp_derives; intros fs.
  apply imp_derives; auto.
  intros ? ?; simpl in *.
  destruct H as [_ [_ [_ [_ [? _]]]]].
  specialize (H id).
  hnf in H.
  rewrite H0 in H.
  destruct ((glob_specs Delta') ! id); [| tauto].
  auto.
Qed.

Lemma _guard_allp_fun_id:
  forall {Espec: OracleKind} ge Delta' Delta (F P: environ -> pred rmap) f k,
    tycontext_sub Delta Delta' ->
    _guard Espec ge Delta' (fun rho => F rho * P rho) f k = _guard Espec ge Delta' (fun rho => F rho * (allp_fun_id Delta rho && P rho)) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  f_equal.
  f_equal.
  rewrite !andp_assoc.
  f_equal.
  rewrite corable_sepcon_andp1 by apply corable_allp_fun_id.
  rewrite (andp_comm (allp_fun_id _ _ )), andp_assoc.
  f_equal.
  apply pred_ext; [apply andp_right; auto | apply andp_left2; auto].
  apply funassert_allp_fun_id_sub; auto.
Qed.

Lemma guard_allp_fun_id: forall {Espec: OracleKind} ge Delta' Delta (F P: environ -> pred rmap) k,
  tycontext_sub Delta Delta' ->
  guard Espec ge Delta' (fun rho => F rho * P rho) k = guard Espec ge Delta' (fun rho => F rho * (allp_fun_id Delta rho && P rho)) k.
Proof.
  intros.
  apply _guard_allp_fun_id; auto.
Qed.

Lemma rguard_allp_fun_id: forall {Espec: OracleKind} ge Delta' Delta (F: environ -> pred rmap) P k,
  tycontext_sub Delta Delta' ->
  rguard Espec ge Delta' (frame_ret_assert P F) k = rguard Espec ge Delta' (frame_ret_assert (conj_ret_assert P (allp_fun_id Delta)) F) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite !proj_frame.
  rewrite proj_conj.
  apply _guard_allp_fun_id; auto.
Qed.

Lemma semax_pre_allp_fun_id:
  forall {CS: compspecs} {Espec: OracleKind} Delta P c Q,
    semax Espec Delta (fun rho => allp_fun_id Delta rho && P rho) c Q <->
    semax Espec Delta P c Q.
Proof.
  intros.
  unfold semax.
  apply Morphisms_Prop.all_iff_morphism; intros n.
  rewrite semax_fold_unfold.
  match goal with
  | |- ?A <-> ?B => assert (A = B); [| rewrite H; tauto]
  end.
  f_equal.
  f_equal. extensionality gx.
  f_equal. extensionality Delta'.
  apply prop_imp.
  intros [? _].
  f_equal.
  f_equal. extensionality k.
  f_equal. extensionality F.
  f_equal.
  symmetry; apply guard_allp_fun_id; auto.
Qed.

Lemma semax_post_allp_fun_id:
  forall {CS: compspecs} {Espec: OracleKind} Delta P c Q,
    semax Espec Delta P c Q <->
    semax Espec Delta P c (conj_ret_assert Q (allp_fun_id Delta)).
Proof.
  intros.
  unfold semax.
  apply Morphisms_Prop.all_iff_morphism; intros n.
  rewrite semax_fold_unfold.
  match goal with
  | |- ?A <-> ?B => assert (A = B); [| rewrite H; tauto]
  end.
  f_equal.
  f_equal. extensionality gx.
  f_equal. extensionality Delta'.
  apply prop_imp.
  intros [? _].
  f_equal.
  f_equal. extensionality k.
  f_equal. extensionality F.
  f_equal.
  f_equal.
  apply rguard_allp_fun_id; auto.
Qed.

Lemma _guard_tc_environ:
  forall {Espec: OracleKind} ge Delta' Delta (F P: environ -> pred rmap) f k,
    tycontext_sub Delta Delta' ->
    _guard Espec ge Delta' (fun rho => F rho * P rho) f k = _guard Espec ge Delta' (fun rho => F rho * (!! typecheck_environ Delta rho && P rho)) f k.
Proof.
  intros.
  unfold _guard.
  f_equal; extensionality tx.
  f_equal; extensionality vx.
  f_equal.
  f_equal.
  f_equal.
  rewrite corable_sepcon_andp1 by apply corable_prop.
  rewrite <- andp_assoc.
  f_equal.
  apply pred_ext; [apply andp_right; auto | apply andp_left1; auto].
  intros ? ?; simpl in *.
  destruct H0 as [? _].
  eapply typecheck_environ_sub; eauto.
Qed.

Lemma guard_tc_environ: forall {Espec: OracleKind} ge Delta' Delta (F P: environ -> pred rmap) k,
  tycontext_sub Delta Delta' ->
  guard Espec ge Delta' (fun rho => F rho * P rho) k = guard Espec ge Delta' (fun rho => F rho * (!! typecheck_environ Delta rho && P rho)) k.
Proof.
  intros.
  apply _guard_tc_environ; auto.
Qed.

Lemma rguard_tc_environ: forall {Espec: OracleKind} ge Delta' Delta (F: environ -> pred rmap) P k,
  tycontext_sub Delta Delta' ->
  rguard Espec ge Delta' (frame_ret_assert P F) k = rguard Espec ge Delta' (frame_ret_assert (conj_ret_assert P (fun rho => !! typecheck_environ Delta rho)) F) k.
Proof.
  intros.
  unfold rguard.
  f_equal; extensionality ek.
  f_equal; extensionality vl.
  rewrite !proj_frame.
  rewrite proj_conj.
  apply _guard_tc_environ; auto.
Qed.

Lemma semax_conseq {CS: compspecs} {Espec: OracleKind}:
 forall P' (R': ret_assert) Delta P c (R: ret_assert) ,
   (forall rho,  !!(typecheck_environ Delta rho) && (allp_fun_id Delta rho && P rho)
                   |-- bupd (|> FF || P' rho) )%pred ->
   (forall rho,  !!(typecheck_environ Delta rho) && (allp_fun_id Delta rho && RA_normal R' rho)
                   |-- bupd (|> FF || RA_normal R rho)) ->
   (forall rho, !! (typecheck_environ Delta rho) && (allp_fun_id Delta rho && RA_break R' rho)
                   |-- bupd (|> FF || RA_break R rho)) ->
   (forall rho, !! (typecheck_environ Delta rho) && (allp_fun_id Delta rho && RA_continue R' rho)
                   |-- bupd (|> FF || RA_continue R rho)) ->
   (forall vl rho, !! (typecheck_environ Delta rho) && (allp_fun_id Delta rho && RA_return R' vl rho)
                   |-- bupd (|> FF || RA_return R vl rho)) ->
   semax Espec Delta P' c R' ->  semax Espec Delta P c R.
Proof.
  intros.
  assert (semax' Espec Delta P' c R' |-- semax' Espec Delta P c R);
    [clear H4 | exact (fun n => H5 n (H4 n))].
  rewrite semax_fold_unfold.
  apply allp_derives; intros gx.
  apply allp_derives; intros Delta'.
  apply prop_imp_derives; intros [? _].
  apply imp_derives; auto.
  apply allp_derives; intros k.
  apply allp_derives; intros f.
  apply imp_derives; [apply andp_derives; auto |].
  + erewrite (rguard_allp_fun_id _ _ _ _ R') by eauto.
    erewrite (rguard_tc_environ _ _ _ _ (conj_ret_assert _ _)) by eauto.
    rewrite (rguard_except_0 _ _ _ R).
    rewrite (rguard_bupd _ _ _ (except_0_ret_assert _)).
    apply rguard_mono.
    intros.
    rewrite proj_frame, proj_conj, proj_conj.
    rewrite proj_frame, proj_bupd_ret_assert, proj_except_0_ret_assert.
    apply sepcon_derives; auto.
    destruct rk; unfold proj_ret_assert; auto.
  + erewrite (guard_allp_fun_id _ _ _ _ P) by eauto.
    erewrite (guard_tc_environ _ _ _ _ (fun rho => allp_fun_id Delta rho && P rho)) by eauto.
    rewrite (guard_except_0 _ _ _ P').
    rewrite (guard_bupd _ _ _ (fun rho => |> FF || P' rho)).
    apply guard_mono.
    intros.
    apply sepcon_derives; auto.
Qed.

