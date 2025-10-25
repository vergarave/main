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
import AST;

PathConfig pcfg = getProjectPathConfig(|project://alu|);
Language aluLang = language(pcfg, "ALU", "alu", "Plugin", "contribs");

data Command = run(Module p);

set[LanguageService] contribs() = {
  parser(start[Module] (str program, loc src) {
    return parse(#start[Module], program, src);
  }),
  lenses(rel[loc src, Command lens] (start[Module] p) {
    Module m = implode(#Module, p);
    return { <p.src, run(m, title="Run ALU program")> };
  }),
  executor(exec)
};

value exec(run(Module p)) {
  edit(|project://alu/instance/output/last_run.txt|);
  println("Running ALU…");
  result = evalModule(p);
  writeFile(|project://alu/instance/output/last_run.txt|, "Result: <pp(result)>");
  return ("result": true);
}

void main() { 
  registerLanguage(aluLang); 
  println("ALU language registered!");
}