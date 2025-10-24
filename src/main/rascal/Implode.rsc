module Implode

import Syntax, Parser, AST, ParseTree, Node;

// Mapea el ParseTree a AST automáticamente por nombre
public Module implodeModule(Tree pt) = implode(#Module, pt);
public Module load(loc l)            = implodeModule(parseModule(l));
