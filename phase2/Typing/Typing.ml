open AST
open TypeError
open Type

type func_info = {
  ftype: Type.t;
  fargs: argument list
}

type curr_env = {
  returntype : Type.t;
  variables: (string, Type.t) Hashtbl.t
}

(* class definition environment *)
type class_env = {
  attributes : (string, Type.t) Hashtbl.t;
  constructors : (string, func_info) Hashtbl.t;
  methods : (string, func_info) Hashtbl.t;
  parent : Type.ref_type;
}

(* auxiliary print functions *)
let print_arguments tab arguments =
  List.iter (fun a -> print_string(tab ^ AST.stringOf_arg a)) arguments

let print_class_env class_env =
  Hashtbl.iter (fun k v -> print_string("attribute " ^ k ^ Type.stringOf v ^ "\n")) class_env.attributes;
  Hashtbl.iter (fun k v -> print_string("constructor " ^ k ^ Type.stringOf v.ftype); print_arguments " " v.fargs; print_endline("")) class_env.constructors;
  Hashtbl.iter (fun k v -> print_string("methods " ^ k ^ Type.stringOf v.ftype); print_arguments " " 
  v.fargs; print_endline("")) class_env.methods;
  print_string("parent " ^ Type.stringOf_ref class_env.parent);
  print_endline ("")

let print_class_envs class_envs =
  Hashtbl.iter (fun k v -> print_string("class " ^ k ^ "\n"); print_class_env v ) class_envs;
  print_endline ("")

let verify_argument current_env arguments =
  if (Hashtbl.mem current_env.variables arguments.pident) <> true
  then (
    (* print_arguments "   " arguments; *)
    Hashtbl.add current_env.variables arguments.pident arguments.ptype
  )
  else raise(ArgumentAlreadyExists(arguments.pident))

(* check the type of value *)
let verify_value v =
  match v with
  | String s -> Some(Ref({ tpath = []; tid = "String" }))
  | Int i -> Some(Primitive(Int))
  | Float f -> Some(Primitive(Float))
  | Char c -> Some(Primitive(Char))
  | Null -> None
  | Boolean b -> Some(Primitive(Boolean))



(* check the type of the assignment operation *)
let verify_assignop_type t1 t2 =
  if t1 <> t2 then
    begin
      raise(TypeError.WrongTypesAssignOperation(t1, t2))
    end

(* check the type of the expressions *)
let rec verify_expression env current_env e =
  print_string(string_of_expression_desc(e.edesc));
  match e.edesc with
  | New (None,n,al) -> () (*TODO*)
  (* | NewArray (Some n1,n2,al) -> () (*TODO*) *)
  | Call (r,m,al) -> () (*TODO*)
  | Attr (r,a) -> () (*TODO*)
  | If (e1, e2, e3) -> () (*TODO*)
  | Val v ->
      e.etype <- verify_value v
  | Name s -> () (*TODO*)
  | ArrayInit el -> () (*TODO*)
  | Array (e,el) -> () (*TODO*)
  | AssignExp (e1,op,e2) -> () (*TODO*)
  | Post (e,op) -> () (*TODO*)
  | Pre (op,e) -> () (*TODO*)
  | Op (e1,op,e2) -> () (*TODO*)
  | CondOp (e1,e2,e3) -> () (*TODO*)
  | Cast (t,e) -> () (*TODO*)
  | Type t -> () (*TODO*)
  | ClassOf t-> () (*TODO*)
  | Instanceof (e1, t)-> () (*TODO*)
  | VoidClass -> () (*TODO*)

(* add a local variable to the current environment *)
let add_local_variable current_env id t =
  if (Hashtbl.mem current_env.variables id) <> true
  then Hashtbl.add current_env.variables id t
  else raise(DuplicateLocalVariable((Type.stringOf t)^" "^id))

let verify_statement current_env envs statement =
  match statement with
  | VarDecl dl ->
    List.iter (fun (t,id,init) ->
      (match init with
      (* check int i;*)
      | None -> add_local_variable current_env id t
      (* check int j = 2; or int j = i;*)
      | Some e -> (verify_expression envs current_env e;
        let s = string_of_expression_desc e.edesc in
        match e.etype with
          (* check int j = i*)
          | None -> print_string ("["^s^"]"); (*TODO*)
          (* check int i =2*)
          | Some real_t -> (
            if real_t <> t
            then raise(IncompatibleTypes((Type.stringOf real_t)^" cannnot be converted to "^(Type.stringOf t)^" for "^id))
            else add_local_variable current_env id t
          )
        )
      );
	  ) dl
  | Block b -> () (*TODO*)
  | Nop -> () (*TODO*)
  | Expr e -> () (*TODO*)
  | Return None -> () (*TODO*)
  | Return Some(e) -> () (*TODO*)
  | Throw e -> () (*TODO*)
  | While(e,s) -> () (*TODO*)
  | If(e,s,None) -> () (*TODO*)
  | If(e,s1,Some s2) -> () (*TODO*)
  | For(fil,eo,el,s) -> () (*TODO*)
  | Try(body,catch,finally) -> () (*TODO*)

(* check type for constructors  *)
let verify_constructors envs current_class consts =
  (* consts is of astconst structure *)
  (* print_endline ("=====verify_constructors======");
  print_class_env(Hashtbl.find envs current_class);
  print_endline ("=====verify_constructors======"); *)
  let current_env = {returntype = Type.Ref({ tpath = []; tid = consts.cname }); variables = Hashtbl.create 17 } in
  List.iter (verify_argument current_env) consts.cargstype;
  List.iter (verify_statement current_env envs) consts.cbody

let verify_methods envs current_class meths =
  let current_env = {returntype = meths.mreturntype; variables = Hashtbl.create 17 } in
  List.iter (verify_argument current_env) meths.margstype;
  List.iter (verify_statement current_env envs) meths.mbody

(* check the type of the attibutes *)
let verify_attributes envs current_class attrs = 
  match attrs.adefault with
  | Some e ->
    let current_env = {returntype = Type.Void; variables = Hashtbl.create 1} in
    verify_expression envs current_env e;
    (* Verify the assignment operation's type is coherent *)
    let mytype = Some(attrs.atype) in
    verify_assignop_type mytype e.etype 
  | None -> ()

(* check the type of the class *)
let verify_class envs c current_class =
  List.iter (verify_attributes envs current_class) c.cattributes;
  List.iter (verify_methods envs current_class) c.cmethods;
  List.iter (verify_constructors envs current_class) c.cconsts

let verify_type class_envs t =
  match t.info with
  | Class c -> 
    let current_class = t.id in
    verify_class class_envs c current_class
  | Inter -> ()

let add_constructors env current_class consts =
  let consts_table = (Hashtbl.find env current_class).constructors in
  if (Hashtbl.mem consts_table consts.cname) <> true
  then (
    (* print_const "   " consts; *)
    Hashtbl.add consts_table consts.cname
    {ftype = Type.Ref {tpath=[]; tid=current_class}; 
     fargs = consts.cargstype }
  )
  else raise(ConstructorAlreadyExists(consts.cname))

(* check if method has alread exist in hash table *)
let add_methods env current_class meths =
  let meths_table = (Hashtbl.find env current_class).methods in
  if (Hashtbl.mem meths_table meths.mname) <> true
  then (
    (* print_method "   " meths; *)
    Hashtbl.add meths_table meths.mname
     {ftype = meths.mreturntype; 
      fargs = meths.margstype }
  )
  (*TODO: check override and overload*)
  else raise(MethodAlreadyExists(meths.mname)) 

(* check if attribute has already exist in hash table *)
let add_attributes env current_class attrs =
  let attrs_table = (Hashtbl.find env current_class).attributes in
  if (Hashtbl.mem attrs_table attrs.aname) <> true
  then (
    (* print_attribute "   " attrs; *)
    Hashtbl.add attrs_table attrs.aname attrs.atype
  )
  else raise(AttributeAlreadyExists(attrs.aname))

(* check class body*)
let add_class env c current_class =
  List.iter (add_attributes env current_class) c.cattributes;
  List.iter (add_methods env current_class) c.cmethods ;
  List.iter (add_constructors env current_class) c.cconsts 

(* add to class environment *)
let add_to_env class_envs t =
  match t.info with
  | Class c -> 
    let current_class = t.id in
    if (Hashtbl.mem class_envs t.id) <> true
    then (
      Hashtbl.add class_envs t.id
        {attributes = (Hashtbl.create 17);
        constructors = (Hashtbl.create 17);
        methods = (Hashtbl.create 17);
        parent = c.cparent };
      add_class class_envs c current_class
    )      
    else raise(ClassAlreadyExists(t.id))
  | Inter -> ()

let typing ast = 
  let class_envs = Hashtbl.create 17  in
  (*Step 1: Build the class definition environment*)
  List.iter (add_to_env class_envs) ast.type_list;
  (*Step 2: Check the type of the inside of the class*)
  List.iter (verify_type class_envs) ast.type_list
