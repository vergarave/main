module AST

data Module = programa(list[Variables] vars, list[Top] tops);

data Top
  = topFun(Function f)
  | topData(Data d)
  | topStmt(Statement s)
  ;

data Variables = vars(list[str] names);
data Assignment = asg(str name);

data Function = fun(
    list[Assignment] optAsg,
    list[Variables] params,
    Body body,
    str name
);

data Data = datos(
    list[Assignment] optAsg,
    Variables withVars,
    DataBody body,
    str name
);

data DataBody
  = dCtor(Constructor ctor)
  | dFun(Function funDecl)
  ;

data Constructor = ctor(str name, Variables fields);

data Body = body(list[Statement] ss);

data Statement =
    stExpr(Expression expr)
  | stVars(Variables varsDecl)
  | stRange(Range r)
  //| stIter(Iterator it)
  | stLoop(Loop loopStmt)
  | stIf(Expression cond, Body thenB, Body elseB)
  | stCond(Expression scrut, PatternBody pb)
  | stInvoke(Invocation inv)
  ;

data Range = range(
    list[Assignment] optAsg,
    Principal from,
    Principal to
);

data Iterator = iter(
    Assignment asg,
    Variables inVars,
    Variables outVars
);

data Loop = loop(str var, Range r, Body body);

data PatternBody = pbody(Expression lhs, Expression rhs);

data Invocation
  = inv1(str f, list[Variables] args)
  | inv2(str recv, str meth, list[Variables] args)
  ;

data Principal =
    pTrue()
  | pFalse()
  | pChar(str c)
  | pInt(int n)
  | pFloat(real x)
  | pId(str name)
  ;

data Expression =
    eP(Principal p)
  | ePar(Expression e)
  | eList(Expression e)
  | eNeg(Expression e)
  | ePow(Expression left, Expression right)
  | eMul(Expression left, Expression right)     // *
  | eDiv(Expression left, Expression right)     // /
  | eMod(Expression left, Expression right)     // %
  | eAdd(Expression left, Expression right)     // +
  | eSub(Expression left, Expression right)     // -
  | eLT(Expression left, Expression right)      // <
  | eGT(Expression left, Expression right)      // >
  | eLE(Expression left, Expression right)      // <=
  | eGE(Expression left, Expression right)      // >=
  | eNE(Expression left, Expression right)      // <>
  | eEQ(Expression left, Expression right)      // =
  | eAnd(Expression left, Expression right)
  | eOr(Expression left, Expression right)
  | eImp(Expression left, Expression right)
  | eSep(Expression left, Expression right)
  | eInv(Invocation inv)
  ;
