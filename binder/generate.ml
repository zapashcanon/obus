(*
 * generate.ml
 * -----------
 * Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, a ocaml implemtation of dbus.
 *)

module type TermType =
sig
  type var
  type t
end

module type ValueType =
sig
  type t
end

module Make (Term : TermType) (Value : ValueType) =
struct
  open Term
  type term =
      [ `Term of Term.t * term list ]
  type pattern =
      [ `Term of Term.t * pattern list
      | `Var of Term.var ]
  type eqn = term * term
  type maker = Value.t list -> Value.t
  type generator = {
    gen_left : pattern;
    gen_right : pattern;
    gen_vars : pattern list;
    gen_maker : maker;
  }

  let make_generator either_pattern right_pattern vars maker =
    { gen_left = either_pattern;
      gen_right = right_pattern;
      gen_vars = vars;
      gen_maker = maker }

  type sub = (var * term) list

  let rec substitute sub = function
    | `Var v -> List.assoc v sub
    | `Term(name, args) -> `Term(name, List.map (substitute sub) args)

  exception Cannot_unify

  let unify (pattern : pattern) (term : term) =

    let add var term sub =
      try
        if List.assoc var sub = term
        then sub
        else raise Cannot_unify
      with
        | Not_found -> (var, term) :: sub
    in

    let rec aux sub (pattern : pattern) (term : term) =
      match (pattern, term) with
        | `Var v, t -> add v t sub
        | `Term(ta, arga), `Term(tb, argb) when ta = tb ->
            begin try
              List.fold_left2 aux sub arga argb
            with
              | Invalid_argument _ -> raise Cannot_unify
            end
        | _ -> raise Cannot_unify
    in
      aux [] pattern term

  exception Cannot_generate

  type equation =
    | Equation of eqn
    | Branches of system list

  and system = System of maker * term list * (term * Value.t) list * (term * equation) list

  type 'a result =
    | Success of Value.t
    | Failure
    | Update of 'a

  let match_term (a : term) (b : term) : (term * equation) list =
    let rec aux eqns a b =
      match (a, b) with
        | `Term(ta, arga), `Term(tb, argb) when ta = tb -> begin try
            List.fold_left2 aux eqns arga argb
          with
            | Invalid_argument _ -> raise Cannot_unify
          end
        | a, b -> (b, Equation(a, b)) :: eqns
    in
      aux [] a b

  let generate (generators : generator list) : term -> term -> Value.t option =

    let gen_branches ((a, b) : eqn) : system list result =
      let rec aux acc = function
        | generator :: generators -> begin
            try
              let sub = unify generator.gen_right b in
              let left = substitute sub generator.gen_left in
                match match_term a left with
                  | [] -> Success(generator.gen_maker [])
                  | eqns -> aux
                      (System(generator.gen_maker,
                              List.map (substitute sub) generator.gen_vars,
                              [], eqns) :: acc) generators
            with
              | Cannot_unify -> aux acc generators
          end
        | [] -> begin match acc with
            | [] -> Failure
            | _ -> Update(acc)
          end
      in
        aux [] generators
    in

    let rec one_step_system (System(maker, vars, mapping, eqns)) : system result =
      let rec aux acc mapping = function
        | (t, eqn) :: eqns -> begin match one_step_equation eqn with
            | Success(v) -> aux acc ((t, v) :: mapping) eqns
            | Failure -> Failure
            | Update(eqn) -> aux ((t, eqn) :: acc) mapping eqns
          end
        | [] -> begin match acc with
            | [] -> Success(maker (List.map (fun var -> List.assoc var mapping) vars))
            | _ -> Update(System(maker, vars, mapping, acc))
          end
      in
        aux [] mapping eqns

    and one_step_equation : equation -> equation result = function
      | Equation(eqn) -> begin match gen_branches eqn with
          | Success(v) -> Success(v)
          | Failure -> Failure
          | Update(branches) -> Update(Branches(branches))
        end
      | Branches(branches) ->
          let rec aux acc = function
            | system :: branches -> begin match one_step_system system with
                | Success(v) -> Success(v)
                | Failure -> aux acc branches
                | Update(system) -> aux (system :: acc) branches
              end
            | [] -> begin match acc with
                | [] -> Failure
                | _ -> Update(Branches(acc))
              end
          in
           aux [] branches
    in

    let rec find (equation : equation) : Value.t option =
      match one_step_equation equation with
        | Success(v) -> Some(v)
        | Failure -> None
        | Update(equation) -> find equation
    in

      fun a b -> find (Equation(a, b))
end
