open Pcfast;;

type pcfval =
  | Intval of int
  | Floatval of float
  | Boolval of bool
  | Stringval of string
  | Funval of { param: string; body: expr; env: environment }
  | Funrecval of { fname: string; param: string; body: expr; env: environment }

and environment = (string * pcfval) list
;;


let printval = function
  | Intval n -> Printf.printf "%d" n
  | Floatval f -> Printf.printf "%f" f
  | Boolval b -> Printf.printf "%s" (if b then "true" else "false")
  | Stringval s -> Printf.printf "%S" s
  | Funval _-> Printf.printf "<fun>"
  | Funrecval _ -> Printf.printf "<fun rec>"
;;

(* Environnement. *)
let init_env = [] ;;

let error msg = raise (Failure msg) ;;

let extend rho x v = (x, v) :: rho ;;

let lookup var_name rho =
  try List.assoc var_name rho
  with Not_found -> error (Printf.sprintf "Undefined ident '%s'" var_name)
;;


let rec eval e rho =
  match e with
  | Int n -> Intval n
  | Float f -> Floatval f
  | Bool b -> Boolval b
  | String s -> Stringval s
  | Ident v -> lookup v rho
  | App (e1, e2) -> (
      match (eval e1 rho, eval e2 rho) with
      | (Funval { param; body; env }, v2) ->
          let rho1 = extend env param v2 in
          eval body rho1
      | (Funrecval { fname; param; body; env } as fval, v2) ->
          let rho1 = extend env fname fval in
          let rho2 = extend rho1 param v2 in
          eval body rho2
      | (_, _) -> error "Apply a non-function"
     )
  | Monop ("-", e) -> (
      match eval e rho with
      | Intval n -> Intval (-n)
      | _ -> error "Opposite of a non-integer"
     )
  | Monop (op, _) -> error (Printf.sprintf "Unknown unary op: %s" op)
  | Binop (op, e1, e2) -> (
      match (op, eval e1 rho, eval e2 rho) with
      | ("+", Intval n1, Intval n2) -> Intval (n1 + n2)
      | ("-", Intval n1, Intval n2) -> Intval (n1 - n2)
      | ("*", Intval n1, Intval n2) -> Intval (n1 * n2)
      | ("/", Intval n1, Intval n2) -> Intval (n1 / n2)
      | (("+"|"-"|"*"|"/"), _, _) ->
          error "Arithmetic on non-integers"
      | ("<",  Intval n1, Intval n2) -> Boolval (n1 < n2)
      | (">",  Intval n1, Intval n2) -> Boolval (n1 > n2)
      | ("=",  Intval n1, Intval n2) -> Boolval (n1 = n2)
      | ("<=", Intval n1, Intval n2) -> Boolval (n1 <= n2)
      | (">=", Intval n1, Intval n2) -> Boolval (n1 >= n2)
      | (("<"|">"|"="|"<="|">="), _, _) ->
          error "Comparison of non-integers"
      | _ -> error (Printf.sprintf "Unknown binary op: %s" op)
     )
  | If (e, e1, e2) -> (
      match eval e rho with
      | Boolval b -> eval (if b then e1 else e2) rho
      | _ -> error "Test on a non-boolean"
     )
  | Fun (a, e) -> Funval { param = a; body = e; env = rho }
  | Let (x, e1, e2) ->
      let v1 = eval e1 rho in
      let rho1 = extend rho x v1 in
      eval e2 rho1
  | Letrec (f, Fun( x, e1), e2) ->
      let fval = Funrecval { fname = f; param = x; body = e1; env = rho } in
      let rho1 = extend rho f fval in
      eval e2 rho1
      | _ -> failwith "Not implemented"
;;


let eval e = eval e init_env ;;
