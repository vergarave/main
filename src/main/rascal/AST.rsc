module AST

data Module      = module(opt[Variables] vars, list[Top] tops);
data Top         = topFun(Function) | topData(Data) | topStmt(Statement);

data Variables   = vars(list[str] names);
data Assignment  = asg(str name);

data Function    = fun(opt[Assignment] optAsg, opt[Variables] params, Body body, str name);
data Data        = data(opt[Assignment] optAsg, Variables withVars, DataBody body, str name);
data DataBody    = dCtor(Constructor) | dFun(Function);
data Constructor = ctor(str name, Variables fields);

data Body        = body(list[Statement] ss);

data Statement =
    stExpr(Expression)
  | stVars(Variables)
  | stRange(Range)
  | stIter(Iterator)
  | stLoop(Loop)
  | stIf(Expression cond, Body thenB, Body elseB)
  | stCond(Expression scrut, PatternBody pb)
  | stInvoke(Invocation)
  ;

data Range       = range(opt[Assignment] optAsg, Principal from, Principal to);
data Iterator    = iter(Assignment asg, Variables inVars, Variables outVars);
data Loop        = loop(str var, Range r, Body body);

data PatternBody = pbody(Expression lhs, Expression rhs);

data Invocation  = inv1(str f, opt[Variables] args)
                 | inv2(str recv, str meth, opt[Variables] args);

data Principal   = pTrue() | pFalse() | pChar(str c) | pInt(int n)
                 | pFloat(real x) | pId(str name);

data Expression =
    eP(Principal)
  | ePar(Expression)
  | eList(Expression)
  | eNeg(Expression)                 // -E
  | ePow(Expression, Expression)     // **
  | eMul(Expression, str op, Expression)  // *, /, %
  | eAdd(Expression, str op, Expression)  // +, -
  | eRel(Expression, str op, Expression)  // <, >, <=, >=, <>, =
  | eAnd(Expression, Expression)
  | eOr(Expression, Expression)
  | eImp(Expression, Expression)     // ->
  | eSep(Expression, Expression)     // :
  | eInv(Invocation)
  ;
