module Syntax

layout Layout = WSorComment* !>> [\ \t\n\r#];
lexical WSorComment = [\ \t\n\r] | @category="Comment" "#" ![\n]* $;

keyword KW = "cond" | "do" | "data" | "end" | "for" | "from" | "then"
           | "function" | "else" | "if" | "in" | "iterator" | "sequence"
           | "struct" | "to" | "tuple" | "type" | "with" | "yielding"
           | "and" | "or" | "neg" | "true" | "false"
           | "Int" | "Bool" | "Char" | "Real" | "String";  // ← NUEVOS TIPOS

lexical Identifier = ([a-z][a-zA-Z0-9]*) \ KW;
lexical TypeName = ([A-Z][a-zA-Z0-9]*) \ KW;  // ← NUEVO
lexical IntLiteral = [0-9]+;
lexical FloatLiteral = [0-9]+ "." [0-9]+;
lexical CharLiteral = [a-z];

start syntax Module = Variables? vars Top* tops;

syntax Top
  = topFun: Function
  | topData: Data
  | topStmt: Statement
  ;

syntax Variables = Identifier name ("," Identifier names)*;
syntax Assignment = Identifier name "=";

// Anotaciones de tipo (NUEVO)
syntax TypeAnnot = ":" Type;
syntax Type 
  = tInt: "Int"
  | tBool: "Bool"
  | tChar: "Char"
  | tReal: "Real"
  | tString: "String"
  | tStruct: TypeName name
  ;

// Función con tipos (ACTUALIZADO)
syntax Function = 
  Assignment? optAsg "function" ("(" Params? params ")")? TypeAnnot? retType "do" Body body "end" Identifier name;

syntax Params = Param p ("," Param ps)*;
syntax Param = Identifier name TypeAnnot annot;

// Data con tipos (ACTUALIZADO)
syntax Data = 
  Assignment? optAsg "data" TypeAnnot structType "with" Variables withVars DataBody body "end" Identifier name;

syntax DataBody 
  = dCtor: Constructor
  | dFun: Function
  ;

syntax Constructor = Identifier name "=" "struct" "(" Fields fields ")";
syntax Fields = Field f ("," Field fs)*;
syntax Field = Identifier name TypeAnnot annot;

syntax Body = Statement* ss;

syntax Statement
  = stExpr: Expression
  | stRange: Range
  | stIter: Iterator
  | stLoop: Loop
  | stIf: "if" Expression cond "then" Body thenB "else" Body elseB "end"
  | stCond: "cond" Expression scrut "do" PatternBody pb "end"
  | stInvoke: Invocation
  ;

syntax Range = range: Assignment? optAsg "from" Principal from "to" Principal to;

syntax Iterator = iter: Assignment asg "iterator" "(" Variables inVars ")" "yielding" "(" Variables outVars ")";

syntax Loop = loop: "for" Identifier var Range r "do" Body body "end";

syntax PatternBody = pbody: Expression lhs "-\>" Expression rhs;

syntax Expression
  = bracket ePar: "(" Expression ")"
  | eP: Principal
  | eList: "[" Expression "]"
  | eInv: Invocation
  > right eNeg: "neg" Expression
  > right ePow: Expression "**" Expression
  > left (
      eMul: Expression "*" Expression
    | eDiv: Expression "/" Expression
    | eMod: Expression "%" Expression
    )
  > left (
      eAdd: Expression "+" Expression
    | eSub: Expression "-" Expression
    )
  > non-assoc (
      eLE: Expression "\<=" Expression
    | eGE: Expression "\>=" Expression
    | eNE: Expression "\<\>" Expression
    | eLT: Expression "\<" Expression
    | eGT: Expression "\>" Expression
    | eEQ: Expression "=" Expression
    )
  > left eAnd: Expression "and" Expression
  > left eOr: Expression "or" Expression
  > right eImp: Expression "-\>" Expression
  > left eSep: Expression ":" Expression
  ;

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