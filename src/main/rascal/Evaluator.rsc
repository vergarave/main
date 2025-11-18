module Evaluator

import AST;
import IO;
import Map;
import Set;
import List;
import String;
import util::Math;
import Implode;

data Value = VBool(bool b) | VInt(int n) | VReal(real x) | VChar(str c) | VUnit();

alias Env = map[str, Value];

public void runFile(loc programLoc) {
  result = evalModule(loadModule(programLoc));
  println("ALU result: <pp(result)>");
}

public Value evalModule(Module m) {
  env = ();
  env = initVars(m.vars, env);
  // Ejecuta tops secuencialmente; retorna último valor (o VUnit)
  Value last = VUnit();
  for (t <- m.tops) {
    <env, last> = evalTop(t, env);
  }
  return last;
}

private Module loadModule(loc l) {
  return load(l);
}

private Env initVars(list[Variables] v, Env env) {
  if (size(v) == 0) return env;
  vars(names) = v[0];
  for (n <- names) {
    env[n] = VUnit();
  }
  return env;
}

private tuple[Env,Value] evalTop(Top t, Env env) {
  switch (t) {
    case topStmt(s): return evalStmt(s, env);
    case topFun(_):  return <env, VUnit()>;
    case topData(_): return <env, VUnit()>;
  }
  return <env, VUnit()>;
}

private tuple[Env,Value] evalStmt(Statement s, Env env) {
  switch (s) {
    case stExpr(e): return <env, evalExpr(e, env)>;
    case stVars(vars(ns)): {
      for (n <- ns) env[n] = VUnit();
      return <env, VUnit()>;
    }
    case stIf(cond, thenB, elseB): {
      v = evalExpr(cond, env);
      if (asBool(v)) return evalBody(thenB, env);
      else           return evalBody(elseB,  env);
    }
    case stLoop(var, r, b): {
      <fromV, toV> = evalRange(r, env);
      int a = asInt(fromV);
      int z = asInt(toV);
      Value last = VUnit();
      Env cur = env;
      for (i <- [a..z+1]) {
        cur[var] = VInt(i);
        <cur, last> = evalBody(b, cur);
      }
      return <cur, last>;
    }
    case stRange(_): return <env, VUnit()>;
    case stIter(_):  return <env, VUnit()>;
    case stCond(scrut, pbody(lhs, rhs)): {
      v = evalExpr(scrut, env);
      if (asBool(evalExpr(lhs, env))) return <env, evalExpr(rhs, env)>;
      return <env, VUnit()>;
    }
    case stInvoke(inv): {
      return <env, VUnit()>;
    }
  }
  return <env, VUnit()>;
}

private tuple[Env,Value] evalBody(Body body(ss), Env env) {
  Value last = VUnit();
  Env cur = env;
  for (s <- ss) {
    <cur, last> = evalStmt(s, cur);
  }
  return <cur, last>;
}

private tuple[Value,Value] evalRange(Range range(optAsg, from, to), Env env) {
  int a = asInt(evalPrincipal(from, env));
  int z = asInt(evalPrincipal(to, env));
  return <VInt(a), VInt(z)>;
}

private Value evalExpr(Expression e, Env env) {
  switch (e) {
    case eP(p):       return evalPrincipal(p, env);
    case ePar(x):     return evalExpr(x, env);
    case eList(x):    return evalExpr(x, env);
    case eNeg(x):     { v = evalExpr(x, env); return numNeg(v); }
    case ePow(l,r):   { return binPow(evalExpr(l,env), evalExpr(r,env)); }
    case eMul(l,op,r):{ return binMul(op, evalExpr(l,env), evalExpr(r,env)); }
    case eAdd(l,op,r):{ return binAdd(op, evalExpr(l,env), evalExpr(r,env)); }
    case eRel(l,op,r):{ return relCmp(op, evalExpr(l,env), evalExpr(r,env)); }
    case eAnd(l,r):   { return VBool(asBool(evalExpr(l,env)) && asBool(evalExpr(r,env))); }
    case eOr(l,r):    { return VBool(asBool(evalExpr(l,env)) || asBool(evalExpr(r,env))); }
    case eImp(l,r):   { return VBool(!asBool(evalExpr(l,env)) || asBool(evalExpr(r,env))); }
    case eSep(l,r):   { return evalExpr(r, env); }
    case eInv(_):     { return VUnit(); }
  }
  return VUnit();
}

private Value evalPrincipal(Principal p, Env env) {
  switch (p) {
    case pTrue():  return VBool(true);
    case pFalse(): return VBool(false);
    case pChar(c): return VChar(c);
    case pInt(n):  return VInt(n);
    case pFloat(x):return VReal(x);
    case pId(x):   return (x in env) ? env[x] : error("Undefined id: <x>");
  }
  return VUnit();
}

private Value numNeg(Value v)
  = (v is VInt)  ? VInt(-v.n)
  : (v is VReal) ? VReal(-v.x)
  : error("Unary - expects number");

private Value binPow(Value a, Value b) {
  int exp = asInt(b);
  if (a is VInt)  return VInt(toInt(pow(toReal(a.n), toReal(exp))));
  if (a is VReal) return VReal(pow(a.x, toReal(exp)));
  return error("** expects numeric base");
}

private Value binMul(str op, Value a, Value b) {
  Value A = widen(a,b);
  Value B = widen(b,a);
  switch (op) {
    case "*": return mul(A,B);
    case "/": return div(A,B);
    case "%": return modulo(A,B);
  }
  return error("Unknown MulOp");
}

private Value binAdd(str op, Value a, Value b) {
  Value A = widen(a,b);
  Value B = widen(b,a);
  switch (op) {
    case "+": return add(A,B);
    case "-": return sub(A,B);
  }
  return error("Unknown AddOp");
}

private Value relCmp(str op, Value a, Value b) {
  Value A = widen(a,b);
  Value B = widen(b,a);
  switch (op) {
    case "\<":  return VBool(cmp(A,B) < 0); 
    case "\>":  return VBool(cmp(A,B) > 0);     
    case "\<=": return VBool(cmp(A,B) <= 0);     
    case "\>=": return VBool(cmp(A,B) >= 0);     
    case "\<\>": return VBool(cmp(A,B) != 0);
    case "=":  return VBool(eq(A,B));
  }
  return error("Unknown RelOp");
}

// ---- aritmética & utilidades
private bool isInt(Value v)  = v is VInt;
private bool isReal(Value v) = v is VReal;

private Value widen(Value a, Value b) {
  if (a is VReal || b is VReal) {
    if (a is VInt) return VReal(toReal(a.n));
    if (a is VReal) return a;
  }
  return a;
}

private Value add(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal(asReal(a) + asReal(b)) : VInt(asInt(a) + asInt(b));
private Value sub(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal(asReal(a) - asReal(b)) : VInt(asInt(a) - asInt(b));
private Value mul(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal(asReal(a) * asReal(b)) : VInt(asInt(a) * asInt(b));
private Value div(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal(asReal(a) / asReal(b)) : VInt(asInt(a) / asInt(b));
private Value modulo(Value a, Value b) = VInt(asInt(a) % asInt(b));

private int cmp(Value a, Value b) {
  if (a is VInt && b is VInt) {
    if (a.n < b.n) return -1;      // < 
    if (a.n > b.n) return 1;       // > 
    return 0;
  }
  real ar = asReal(a);
  real br = asReal(b);
  if (ar < br) return -1;          //  < 
  if (ar > br) return 1;           // > 
  return 0;
}

private bool eq(Value a, Value b) {
  if (a is VInt && b is VInt)  return a.n == b.n;
  if (a is VReal && b is VReal) return a.x == b.x;
  if (a is VBool && b is VBool) return a.b == b.b;
  return false;
}

private bool asBool(Value v)
  = (v is VBool) ? v.b : error("Boolean expected");
private int  asInt(Value v)
  = (v is VInt)  ? v.n : error("Int expected");
private real asReal(Value v)
  = (v is VReal) ? v.x
  : (v is VInt)  ? toReal(v.n)
  : error("Real expected");


public str pp(Value v) = "<v>";