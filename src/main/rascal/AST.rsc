module AST

data Module = programa(list[Variables] vars, list[Top] tops);
data Top = topFun(Function) | topData(Data) | topStmt(Statement);

data Variables = vars(list[str] names);
data Assignment = asg(str name);

data Function = fun(list[Assignment] optAsg, list[Variables] params, Body body, str name);
data Data = datos(list[Assignment] optAsg, Variables withVars, DataBody body, str name);
data DataBody = dCtor(Constructor) | dFun(Function);
data Constructor = ctor(str name, Variables fields);

data Body = body(list[Statement] ss);

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

data Range = range(list[Assignment] optAsg, Principal from, Principal to);
data Iterator = iter(Assignment asg, Variables inVars, Variables outVars);
data Loop = loop(str var, Range r, Body body);

data PatternBody = pbody(Expression lhs, Expression rhs);

data Invocation = inv1(str f, list[Variables] args)
                | inv2(str recv, str meth, list[Variables] args);

data Principal = pTrue() | pFalse() | pChar(str c) | pInt(int n)
               | pFloat(real x) | pId(str name);

data Expression =
    eP(Principal)
  | ePar(Expression)
  | eList(Expression)
  | eNeg(Expression)
  | ePow(Expression, Expression)
  | eMul(Expression, Expression)     // ✅ Sin str op
  | eDiv(Expression, Expression)     // ✅ Nuevo
  | eMod(Expression, Expression)     // ✅ Nuevo
  | eAdd(Expression, Expression)     // ✅ Sin str op
  | eSub(Expression, Expression)     // ✅ Nuevo
  | eLT(Expression, Expression)      // ✅ 
  | eGT(Expression, Expression)      // ✅ >
  | eLE(Expression, Expression)      // ✅ <=
  | eGE(Expression, Expression)      // ✅ >=
  | eNE(Expression, Expression)      // ✅ <>
  | eEQ(Expression, Expression)      // ✅ =
  | eAnd(Expression, Expression)
  | eOr(Expression, Expression)
  | eImp(Expression, Expression)
  | eSep(Expression, Expression)
  | eInv(Invocation)
  ;