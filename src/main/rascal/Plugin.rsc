module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Relation;
import Syntax;
import Parser;
import Implode;
import Evaluator;
import Checker;
import AST;

PathConfig pcfg = getProjectPathConfig(|project://main|);
Language aluLang = language(pcfg, "ALU", "alu", "Plugin", "contribs");

data Command = run(Module p) | check(Tree pt);

set[LanguageService] contribs() = {
  parser(start[Module] (str program, loc src) {
    return parse(#start[Module], program, src);
  }),
  lenses(rel[loc src, Command lens] (start[Module] p) {
    Module m = implode(#Module, p);
    return { 
      <p.src, run(m, title="Run ALU program")>,
      <p.src, check(p, title="Type check")> 
    };
  }),
  executor(exec),
  checker(aluChecker)  // Integración de TypePal
};

value exec(run(Module p)) {
  edit(|project://main/instance/output/last_run.txt|);
  println("Running ALU…");
  result = evalModule(p);
  writeFile(|project://main/instance/output/last_run.txt|, "Result: <pp(result)>");
  return ("result": true);
}

value exec(check(Tree pt)) {
  println("Type checking ALU program...");
  TModel tm = aluChecker(pt);
  msgs = validate(tm);
  for (m <- msgs) {
    println(m);
  }
  return ("result": size(msgs) == 0);
}

void main() { 
  registerLanguage(aluLang); 
  println("ALU language registered with type checking!");
}
