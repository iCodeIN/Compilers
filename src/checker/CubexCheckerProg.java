 import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;
import java.lang.StringBuilder;
import java.util.BitSet;
import java.util.List;
import java.util.ArrayList;
import org.apache.commons.lang3.tuple.ImmutablePair;


public class CubexCheckerProg {
    public static void main(String[] args) throws Exception {
        // lex the file
        CubexLexer lex = new CubexLexer(new ANTLRFileStream(args[0]));
        CommonTokenStream tokens = new CommonTokenStream(lex);
        CubexParser par = new CubexParser(tokens);
        System.out.print(assignment3(lex, par));
    }

    public static String assignment3(CubexLexer lex, CubexParser parser) {
        if (hasLexerError(lex)) {
            return "reject";
        }
        StringBuilder output = new StringBuilder();
        parser.setBuildParseTree(true);
        try {
            CubexProg prog = parser.prog().cu;
            Triple<CubexClassContext, CubexFunctionContext, SymbolTable> trip = buildBase();
            // System.out.println(prog);


            return ((Boolean) prog.typeCheck(trip.getLeft(), trip.getMiddle(), trip.getRight())).toString();

        } catch(Exception e){
            // System.out.println(e);
            e.printStackTrace();
            // parser.reset();
            // viewTree(parser);
            return "reject";
        }
    }

    public static Triple<CubexClassContext, CubexFunctionContext, SymbolTable> buildBase() {
        try {
            CubexLexer baseLex = new CubexLexer(new ANTLRFileStream("../../src/checker/base_classes.cx"));
            CommonTokenStream baseTokens = new CommonTokenStream(baseLex);
            CubexParser basePar = new CubexParser(baseTokens);
            basePar.setBuildParseTree(true);
            CubexProg based = basePar.prog().cu;

            CubexClassContext cc = new CubexClassContext();
            CubexFunctionContext fc = new CubexFunctionContext();
            SymbolTable st = new SymbolTable();

            // follow until end
            while(based.prog != null) {
                // check instance
                if(based instanceof CubexClassProg) {
                    CubexClassProg b = (CubexClassProg) based;
                    cc = cc.set(b.cls.name, b.cls);
                } else if (based instanceof CubexInterfaceProg) {
                    CubexInterfaceProg b = (CubexInterfaceProg) based;
                    cc = cc.set(b.intf.name, b.intf);
                } else if (based instanceof CubexFuncsProg) {
                    List<CubexFunction> funs = ((CubexFuncsProg) based).funcs;
                    for(CubexFunction fun : funs) {
                        fc = fc.set(fun.name, fun);
                    }
                } else {
                    ArrayList<CubexType> param = new ArrayList<CubexType>();
                    param.add(new CubexCType("String"));
                    CubexType itString = new CubexCType(new CubexCName("Iterable"), param);
                    st = st.set(new CubexVName("input"), itString);
                }
                based = based.prog;
            }

            return new Triple<CubexClassContext, CubexFunctionContext, SymbolTable>(cc, fc, st);
            } catch(Exception e) {
                e.printStackTrace();
                return null;
            }
    }

    public static void viewTree(CubexParser parser) {
        ParserRuleContext tree = parser.prog();
        tree.inspect(parser);
        parser.reset();
    }


    public static boolean hasLexerError(CubexLexer lex) {
         for (Token token = lex.nextToken();
             token.getType() != Token.EOF;
             token = lex.nextToken()){
            int type = token.getType();
            String rule = lex.ruleNames[token.getType()-1];
            if (rule.equals("ERRORCHAR")) {
                lex.reset();
                return true;
            }
        }
        lex.reset();
        return false;
    }
}