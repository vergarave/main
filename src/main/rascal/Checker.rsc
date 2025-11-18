module Checker

import AST;
import ParseTree;
import Syntax;
import Implode;
import TypePal;
import IO;
import Set;
import Map;
import String;

// Tipos del lenguaje ALU
data AType
    = tInt()
    | tBool()
    | tChar()
    | tReal()
    | tString()
    | tUnit()
    | tStruct(str name)
    | tFunction(list[AType] params, AType ret)
    | tUnknown()
    ;

// Configuración de TypePal
private TypePalConfig aluConfig() = tconfig(
    isSubType = subtype,
    getTypeNamesAndRole = getTypeNamesAndRole,
    getTypeInNamelessType = getTypeInNamelessType
);

// Relación de subtipos
bool subtype(tInt(), tReal()) = true;
bool subtype(AType t1, AType t2) = t1 == t2;
default bool subtype(AType t1, AType t2) = false;

tuple[list[str] typeNames, set[IdRole] idRoles] getTypeNamesAndRole(tStruct(str name)) 
    = <[name], {dataId()}>;
default tuple[list[str] typeNames, set[IdRole] idRoles] getTypeNamesAndRole(AType t) 
    = <[], {}>;

AType getTypeInNamelessType(AType t, loc scope, map[loc, Define] defines, TypePalConfig cfg) = t;

// Función principal de checking
TModel aluChecker(Tree pt) {
    Module m = implode(#Module, pt);
    return aluChecker(m, tmodel(modelName="ALU", config=aluConfig()));
}

TModel aluChecker(Module programa(vars, tops), TModel tm) {
    // Procesar variables globales
    if (size(vars) > 0) {
        vars(names) = vars[0];
        for (n <- names) {
            tm = define(tm, n, variableId(), n, defType(tUnknown()));
        }
    }
    
    // Procesar declaraciones top-level
    for (t <- tops) {
        tm = checkTop(t, tm);
    }
    
    return tm;
}

// Chequear Top
TModel checkTop(topFun(f), TModel tm) = checkFunction(f, tm);
TModel checkTop(topData(d), TModel tm) = checkData(d, tm);
TModel checkTop(topStmt(s), TModel tm) = checkStatement(s, tm);

// Chequear funciones
TModel checkFunction(fun(optAsg, params, body(stmts), name), TModel tm) {
    // Definir la función
    tm = define(tm, name, functionId(), name, defType(tFunction([], tUnknown())));
    
    // Nuevo scope para la función
    tm = enterScope(tm, name);
    
    // Definir parámetros
    if (size(params) > 0) {
        vars(pnames) = params[0];
        for (pn <- pnames) {
            tm = define(tm, pn, variableId(), pn, defType(tUnknown()));
        }
    }
    
    // Chequear cuerpo
    for (s <- stmts) {
        tm = checkStatement(s, tm);
    }
    
    tm = leaveScope(tm, name);
    return tm;
}

// Chequear data
TModel checkData(datos(optAsg, withVars, body, name), TModel tm) {
    // Definir el tipo struct
    tm = define(tm, name, dataId(), name, defType(tStruct(name)));
    
    // Chequear que las variables usadas en 'with' existan
    vars(wnames) = withVars;
    for (wn <- wnames) {
        tm = use(tm, wn, {variableId()});
    }
    
    return tm;
}

// Chequear statements
TModel checkStatement(stExpr(e), TModel tm) = checkExpression(e, tm);

TModel checkStatement(stRange(range(optAsg, from, to)), TModel tm) {
    tm = checkPrincipal(from, tm);
    tm = checkPrincipal(to, tm);
    tm = requireEqual(tm, tInt(), getPrincipalType(from), error(from, "Range bound must be Int"));
    tm = requireEqual(tm, tInt(), getPrincipalType(to), error(to, "Range bound must be Int"));
    return tm;
}

TModel checkStatement(stIter(iter(asg(name), inVars, outVars)), TModel tm) {
    tm = define(tm, name, variableId(), name, defType(tUnknown()));
    return tm;
}

TModel checkStatement(stLoop(var, r, body(stmts)), TModel tm) {
    tm = define(tm, var, variableId(), var, defType(tInt()));
    tm = checkStatement(stRange(r), tm);
    for (s <- stmts) {
        tm = checkStatement(s, tm);
    }
    return tm;
}

TModel checkStatement(stIf(cond, body(thenStmts), body(elseStmts)), TModel tm) {
    tm = checkExpression(cond, tm);
    tm = requireEqual(tm, tBool(), getExprType(cond, tm), error(cond, "Condition must be Bool"));
    
    for (s <- thenStmts) {
        tm = checkStatement(s, tm);
    }
    for (s <- elseStmts) {
        tm = checkStatement(s, tm);
    }
    return tm;
}

TModel checkStatement(stCond(scrut, pbody(lhs, rhs)), TModel tm) {
    tm = checkExpression(scrut, tm);
    tm = checkExpression(lhs, tm);
    tm = checkExpression(rhs, tm);
    return tm;
}

TModel checkStatement(stInvoke(inv), TModel tm) = checkInvocation(inv, tm);

// Chequear expresiones
TModel checkExpression(eP(p), TModel tm) = checkPrincipal(p, tm);

TModel checkExpression(ePar(e), TModel tm) = checkExpression(e, tm);

TModel checkExpression(eList(e), TModel tm) = checkExpression(e, tm);

TModel checkExpression(eNeg(e), TModel tm) {
    tm = checkExpression(e, tm);
    AType t = getExprType(e, tm);
    tm = requireEqual(tm, tInt(), t, error(e, "Negation requires Int or Real"));
    return tm;
}

TModel checkExpression(ePow(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);
TModel checkExpression(eMul(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);
TModel checkExpression(eDiv(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);
TModel checkExpression(eMod(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);
TModel checkExpression(eAdd(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);
TModel checkExpression(eSub(l, r), TModel tm) = checkBinaryNumeric(l, r, tm);

TModel checkExpression(eLT(l, r), TModel tm) = checkComparison(l, r, tm);
TModel checkExpression(eGT(l, r), TModel tm) = checkComparison(l, r, tm);
TModel checkExpression(eLE(l, r), TModel tm) = checkComparison(l, r, tm);
TModel checkExpression(eGE(l, r), TModel tm) = checkComparison(l, r, tm);
TModel checkExpression(eNE(l, r), TModel tm) = checkComparison(l, r, tm);
TModel checkExpression(eEQ(l, r), TModel tm) = checkComparison(l, r, tm);

TModel checkExpression(eAnd(l, r), TModel tm) = checkBinaryLogical(l, r, tm);
TModel checkExpression(eOr(l, r), TModel tm) = checkBinaryLogical(l, r, tm);
TModel checkExpression(eImp(l, r), TModel tm) = checkBinaryLogical(l, r, tm);

TModel checkExpression(eSep(l, r), TModel tm) {
    tm = checkExpression(l, tm);
    tm = checkExpression(r, tm);
    return tm;
}

TModel checkExpression(eInv(inv), TModel tm) = checkInvocation(inv, tm);

// Helpers para chequeo de expresiones
TModel checkBinaryNumeric(Expression l, Expression r, TModel tm) {
    tm = checkExpression(l, tm);
    tm = checkExpression(r, tm);
    AType lt = getExprType(l, tm);
    AType rt = getExprType(r, tm);
    tm = requireSubType(tm, lt, tReal(), error(l, "Numeric operation requires Int or Real"));
    tm = requireSubType(tm, rt, tReal(), error(r, "Numeric operation requires Int or Real"));
    return tm;
}

TModel checkComparison(Expression l, Expression r, TModel tm) {
    tm = checkExpression(l, tm);
    tm = checkExpression(r, tm);
    return tm;
}

TModel checkBinaryLogical(Expression l, Expression r, TModel tm) {
    tm = checkExpression(l, tm);
    tm = checkExpression(r, tm);
    AType lt = getExprType(l, tm);
    AType rt = getExprType(r, tm);
    tm = requireEqual(tm, tBool(), lt, error(l, "Logical operation requires Bool"));
    tm = requireEqual(tm, tBool(), rt, error(r, "Logical operation requires Bool"));
    return tm;
}

// Chequear Principal
TModel checkPrincipal(pTrue(), TModel tm) = tm;
TModel checkPrincipal(pFalse(), TModel tm) = tm;
TModel checkPrincipal(pChar(_), TModel tm) = tm;
TModel checkPrincipal(pInt(_), TModel tm) = tm;
TModel checkPrincipal(pFloat(_), TModel tm) = tm;
TModel checkPrincipal(pId(name), TModel tm) = use(tm, name, {variableId(), functionId()});

// Chequear Invocación
TModel checkInvocation(inv1(f, args), TModel tm) {
    tm = use(tm, f, {functionId()});
    if (size(args) > 0) {
        vars(argNames) = args[0];
        for (an <- argNames) {
            tm = use(tm, an, {variableId()});
        }
    }
    return tm;
}

TModel checkInvocation(inv2(recv, meth, args), TModel tm) {
    tm = use(tm, recv, {variableId()});
    if (size(args) > 0) {
        vars(argNames) = args[0];
        for (an <- argNames) {
            tm = use(tm, an, {variableId()});
        }
    }
    return tm;
}

// Helpers para obtener tipos
AType getPrincipalType(pTrue()) = tBool();
AType getPrincipalType(pFalse()) = tBool();
AType getPrincipalType(pChar(_)) = tChar();
AType getPrincipalType(pInt(_)) = tInt();
AType getPrincipalType(pFloat(_)) = tReal();
AType getPrincipalType(pId(_)) = tUnknown();

AType getExprType(eP(p), TModel tm) = getPrincipalType(p);
AType getExprType(eNeg(_), TModel tm) = tInt();
AType getExprType(ePow(_, _), TModel tm) = tInt();
AType getExprType(eMul(_, _), TModel tm) = tInt();
AType getExprType(eDiv(_, _), TModel tm) = tInt();
AType getExprType(eMod(_, _), TModel tm) = tInt();
AType getExprType(eAdd(_, _), TModel tm) = tInt();
AType getExprType(eSub(_, _), TModel tm) = tInt();
AType getExprType(eLT(_, _), TModel tm) = tBool();
AType getExprType(eGT(_, _), TModel tm) = tBool();
AType getExprType(eLE(_, _), TModel tm) = tBool();
AType getExprType(eGE(_, _), TModel tm) = tBool();
AType getExprType(eNE(_, _), TModel tm) = tBool();
AType getExprType(eEQ(_, _), TModel tm) = tBool();
AType getExprType(eAnd(_, _), TModel tm) = tBool();
AType getExprType(eOr(_, _), TModel tm) = tBool();
AType getExprType(eImp(_, _), TModel tm) = tBool();
default AType getExprType(Expression e, TModel tm) = tUnknown();

// Función pública para ejecutar el checker
public TModel checkALU(loc l) {
    Tree pt = parse(#start[Module], l);
    return aluChecker(pt);
}