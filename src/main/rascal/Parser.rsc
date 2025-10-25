module Parser

import Syntax;
import ParseTree;

public start[Module] parseModule(loc l) = parse(#start[Module], l);
public start[Module] parseModule(str src, loc l) = parse(#start[Module], src, l);