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
lexical Identifier = ([a-z][a-zA-Z0-9]*) \ KW;
lexical IntLiteral = [0-9]+;
lexical FloatLiteral = [0-9]+ "." [0-9]+;
lexical CharLiteral = [a-z];

// --- Inicio
start syntax Module = Variables? vars Top* tops;

// --- Top-level declarations
syntax Top
  = topFun: Function
  | topData: Data
  | topStmt: Statement
  ;

// --- Variables y asignación
syntax Variables = Identifier name ("," Identifier names)*;
syntax Assignment = Identifier name "=";

// --- Funciones y data
syntax Function = 
  Assignment? optAsg "function" ("(" Variables? params ")")? "do" Body body "end" Identifier name;

syntax Data = 
  Assignment? optAsg "data" "with" Variables withVars DataBody body "end" Identifier name;

syntax DataBody 
  = Constructor
  | Function
  ;

syntax Constructor = Identifier name "=" "struct" "(" Variables fields ")";

// --- Cuerpo y sentencias
syntax Body = Statement* ss;

syntax Statement
  = Expression
  | Variables
  | Range
  | Iterator
  | Loop
  | "if" Expression cond "then" Body thenB "else" Body elseB "end"
  | "cond" Expression scrut "do" PatternBody pb "end"
  | Invocation
  ;

syntax Range = Assignment? optAsg "from" Principal from "to" Principal to;

syntax Iterator = Assignment asg "iterator" "(" Variables inVars ")" "yielding" "(" Variables outVars ")";

syntax Loop = "for" Identifier var Range r "do" Body body "end";

syntax PatternBody = Expression lhs "-\>" Expression rhs;

// --- Expresiones (con precedencias) - CORREGIDO
syntax Expression
  = bracket "(" Expression ")"
  | Principal
  | "[" Expression "]"
  | Invocation
  > right eNeg: "neg" Expression                    // Usar "neg" en vez de "-"
  > right Expression "**" Expression
  > left (
      Expression "*" Expression
    | Expression "/" Expression
    | Expression "%" Expression
    )
  > left (
      Expression "+" Expression
    | Expression "-" Expression
    )
  > non-assoc (
      Expression "\<=" Expression
    | Expression "\>=" Expression
    | Expression "\<\>" Expression
    | Expression "\<" Expression
    | Expression "\>" Expression
    | Expression "=" Expression
    )
  > left Expression "and" Expression
  > left Expression "or" Expression
  > right Expression "-\>" Expression
  > left Expression ":" Expression
  ;

syntax Invocation
  = Identifier f "$" "(" Variables? args ")"
  | Identifier recv "." Identifier meth "(" Variables? args ")"
  ;

syntax Principal
  = "true"
  | "false"
  | CharLiteral c
  | IntLiteral n
  | FloatLiteral x
  | Identifier name
  ;