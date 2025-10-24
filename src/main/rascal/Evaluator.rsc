module Evaluator

import AST;
import IO;
import Map;
import Set;
import List;
import String;
import Math;

// Valor de runtime
data Value = VBool(bool) | VInt(int) | VReal(real) | VChar(str) | VUnit();

alias Env = map[str, Value];

public void runFile(loc programLoc) {
  result = evalModule(loadModule(programLoc));
  println("ALU result: <pp(result)>");
}

public Value evalModule(Module m) {
  env = ();
  // Variables globales iniciales (si hay)
  env = initVars(m.vars, env);
  // Ejecuta tops secuencialmente; retorna último valor (o VUnit)
  Value last = VUnit();
  for (t <- m.tops) {
    <env, last> = evalTop(t, env);
  }
  return last;
}

// helpers
private Module loadModule(loc l) {
  import Implode;
  return load(l);
}

private Env initVars(opt[Variables] v, Env env) {
  if (v ?== none()) return env;
  if (v ?== some(vars(names))) {
    for (n <- names) {
      env[n] = VUnit(); // sin valor inicial
    }
  }
  return env;
}

private tuple[Env,Value] evalTop(Top t, Env env) {
  switch (t) {
    case topStmt(s): return evalStmt(s, env);
    // TODO: registrar funciones y data en env si se requiere
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
    case stLoop(loop(var, r, b)): {
      // for x from a to b do Body
      <fromV, toV> = evalRange(r, env);
      int a = asInt(fromV);
      int z = asInt(toV);
      Value last = VUnit();
      Env cur = env;
      for (i <- [a..z]) {
        cur[var] = VInt(i);
        <cur, last> = evalBody(b, cur);
      }
      return <cur, last>;
    }
    case stRange(_): return <env, VUnit()>;      // no-op aislado
    case stIter(_):  return <env, VUnit()>;      // TODO
    case stCond(scrut, pbody(lhs, rhs)): {
      // Semántica simple: si eval(lhs) es true -> eval(rhs) ; si no, VUnit
      v = evalExpr(scrut, env);
      if (asBool(evalExpr(lhs, env))) return <env, evalExpr(rhs, env)>;
      return <env, VUnit()>;
    }
    case stInvoke(inv): {
      // invocación no implementada aún: retorna Unit
      return <env, VUnit()>;
    }
  }
  return <env, VUnit()>;
}

private tuple[Env,Value] evalBody(Body b, Env env) {
  Value last = VUnit();
  Env cur = env;
  for (s <- b.ss) {
    <cur, last> = evalStmt(s, cur);
  }
  return <cur, last>;
}

private tuple[Value,Value] evalRange(Range r, Env env) {
  int a = asInt(evalPrincipal(r.from, env));
  int z = asInt(evalPrincipal(r.to,   env));
  return <VInt(a), VInt(z)>;
}

private Value evalExpr(Expression e, Env env) {
  switch (e) {
    case eP(p):       return evalPrincipal(p, env);
    case ePar(x):     return evalExpr(x, env);
    case eList(x):    return evalExpr(x, env);   // placeholder (no listas reales)
    case eNeg(x):     { v = evalExpr(x, env); return numNeg(v); }
    case ePow(l,r):   { return binPow(evalExpr(l,env), evalExpr(r,env)); }
    case eMul(l,op,r):{ return binMul(op, evalExpr(l,env), evalExpr(r,env)); }
    case eAdd(l,op,r):{ return binAdd(op, evalExpr(l,env), evalExpr(r,env)); }
    case eRel(l,op,r):{ return relCmp(op, evalExpr(l,env), evalExpr(r,env)); }
    case eAnd(l,r):   { return VBool(asBool(evalExpr(l,env)) && asBool(evalExpr(r,env))); }
    case eOr(l,r):    { return VBool(asBool(evalExpr(l,env)) || asBool(evalExpr(r,env))); }
    case eImp(l,r):   { return VBool(!asBool(evalExpr(l,env)) || asBool(evalExpr(r,env))); }
    case eSep(l,r):   { /* interpretación como par/etq */ return evalExpr(r, env); }
    case eInv(_):     { return VUnit(); } // TODO: invocación/llamadas
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
    case pId(x):   return env?x ? env[x] : error("Undefined id: <x>");
  }
  return VUnit();
}

// ---- helpers numéricos
private Value numNeg(Value v)
  = (v is VInt)  ? VInt(-v.n)
  : (v is VReal) ? VReal(-v.x)
  : error("Unary - expects number");

private Value binPow(Value a, Value b) {
  int exp = asInt(b);
  if (a is VInt)  return VInt(toInt(pow(a.n, exp)));
  if (a is VReal) return VReal(pow(a.x, exp));
  return error("** expects numeric base");
}

private Value binMul(str op, Value a, Value b) {
  int ai? = isInt(a), bi? = isInt(b);
  real ar? = isReal(a), br? = isReal(b);
  Value A = widen(a,b), B = widen(b,a);
  switch (op) {
    case "*": return mul(A,B);
    case "/": return div(A,B);
    case "%": return mod(A,B);
  }
  return error("Unknown MulOp");
}

private Value binAdd(str op, Value a, Value b) {
  Value A = widen(a,b), B = widen(b,a);
  switch (op) {
    case "+": return add(A,B);
    case "-": return sub(A,B);
  }
  return error("Unknown AddOp");
}

private Value relCmp(str op, Value a, Value b) {
  Value A = widen(a,b), B = widen(b,a);
  switch (op) {
    case "<":  return VBool(cmp(A,B) < 0);
    case ">":  return VBool(cmp(A,B) > 0);
    case "<=": return VBool(cmp(A,B) <= 0);
    case ">=": return VBool(cmp(A,B) >= 0);
    case "<>": return VBool(cmp(A,B) != 0);
    case "=":  return VBool(eq(A,B));
  }
  return error("Unknown RelOp");
}

// ---- aritmética & utilidades
private bool isInt(Value v)  = v is VInt;
private bool isReal(Value v) = v is VReal;

private Value widen(Value a, Value b) {
  if (a is VReal || b is VReal) {
    real ax = (a is VReal) ? a.x : (a is VInt ? toReal(a.n) : error("num expected"));
    real bx = (b is VReal) ? b.x : (b is VInt ? toReal(b.n) : error("num expected"));
    return (a == a) ? VReal(ax) : VReal(bx); // dummy: el que pida el llamante
  }
  return a; // ambos int
}

private Value add(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal((asReal(a)) + (asReal(b))) : VInt(asInt(a) + asInt(b));
private Value sub(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal((asReal(a)) - (asReal(b))) : VInt(asInt(a) - asInt(b));
private Value mul(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal((asReal(a)) * (asReal(b))) : VInt(asInt(a) * asInt(b));
private Value div(Value a, Value b)
  = (a is VReal || b is VReal) ? VReal((asReal(a)) / (asReal(b))) : VInt(asInt(a) / asInt(b));
private Value mod(Value a, Value b) = VInt(asInt(a) % asInt(b));

private int cmp(Value a, Value b) {
  if (a is VInt && b is VInt)  return compare(a.n, b.n);
  return compare(asReal(a), asReal(b));
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

// Pretty print
public str pp(Value v) = "<v>";
