module Syntax

// --- Layout & tokens base
layout Layout = WSorComment* !>> [\ \t\n\r#];
lexical WSorComment = [\ \t\n\r] | @category="Comment" "#" ![\n]* $;

// --- Palabras reservadas
keyword KW = "cond" | "do" | "data" | "end" | "for" | "from" | "then"
           | "function" | "else" | "if" | "in" | "iterator" | "sequence"
           | "struct" | "to" | "tuple" | "type" | "with" | "yielding"
           | "and" | "or" | "neg" | "true" | "false";

// --- Tokens
lexical Identifier = ([a-z][a-z]*) \ KW;
lexical IntLiteral = [0-9]+;
lexical FloatLiteral = [0-9]+ "." [0-9]+;
lexical CharLiteral = [a-z];

// --- Inicio
start syntax Module = module: Variables? vars (Top)* tops;

// --- Top-level declarations
syntax Top
  = topFun: Function
  | topData: Data
  | topStmt: Statement
  ;

// --- Variables y asignación
syntax Variables = vars: Identifier name ("," Identifier names)*;
syntax Assignment = asg: Identifier name "=";

// --- Funciones y data
syntax Function = fun:
  Assignment? optAsg "function" ("(" Variables? params ")")? "do" Body body "end" Identifier name;

syntax Data = data:
  Assignment? optAsg "data" "with" Variables withVars DataBody body "end" Identifier name;

syntax DataBody 
  = dCtor: Constructor
  | dFun: Function
  ;

syntax Constructor = ctor: Identifier name "=" "struct" "(" Variables fields ")";

// --- Cuerpo y sentencias
syntax Body = body: Statement* ss;

syntax Statement
  = stExpr: Expression
  | stVars: Variables
  | stRange: Range
  | stIter: Iterator
  | stLoop: Loop
  | stIf: "if" Expression cond "then" Body thenB "else" Body elseB "end"
  | stCond: "cond" Expression scrut "do" PatternBody pb "end"
  | stInvoke: Invocation
  ;

syntax Range = range: Assignment? optAsg "from" Principal from "to" Principal to;

syntax Iterator = iter: Assignment asg "iterator" "(" Variables inVars ")" "yielding" "(" Variables outVars ")";

syntax Loop = loop: "for" Identifier var Range r "do" Body body;

syntax PatternBody = pbody: Expression lhs "->" Expression rhs;

// --- Expresiones (con precedencias)
syntax Expression
  = bracket "(" Expression ")"
  > eNeg: "-" Expression
  > right ePow: Expression "" Expression
  > left (
      eMul: Expression MulOp Expression
    )
  > left (
      eAdd: Expression AddOp Expression
    )
  > non-assoc (
      eRel: Expression RelOp Expression
    )
  > left eAnd: Expression "and" Expression
  > left eOr: Expression "or" Expression
  > right eImp: Expression "->" Expression
  > left eSep: Expression ":" Expression
  | eP: Principal
  | eList: "[" Expression "]"
  | eInv: Invocation
  ;

syntax MulOp = "*" | "/" | "%";
syntax AddOp = "+" | "-";
syntax RelOp = "<=" | ">=" | "<>" | "<" | ">" | "=";

syntax Invocation
  = inv1: Identifier f "$" "(" Variables? args ")"
  | inv2: Identifier recv "." Identifier meth "(" Variables? args ")"
  ;

syntax Principal
  = pTrue: "true"
  | pFalse: "false"
  | pChar: CharLiteral c
  | pInt: IntLiteral n
  | pFloat: FloatLiteral x
  | pId: Identifier name
  ;