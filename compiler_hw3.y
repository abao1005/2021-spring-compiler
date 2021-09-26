/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    #define codegen(...) \
        do { \
            for (int i = 0; i < INDENT; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Other global variables */
    FILE *fout = NULL;
    bool HAS_ERROR = false;
    int INDENT = 0;
    int labelNum = 0;
    int labelNum_2 = 0;
    

    typedef struct SymbolEntry{
        int index;
        char *name;
        char *type;
        int address;
        int LineNo;
        char *elementType;
        struct SymbolEntry *next;
    }entry;

    typedef struct SymbolTable{
        int scopeLev;
        struct SymbolTable *prev;
        struct SymbolTable *next;
        entry *firstEntry;
        entry *lastEntry;
    }table;

    int scopeLevel = 0;
    int address = 0;
    int assign_address = 0;
    bool isLiteral = false;
    bool isLiteralError = false;
    table *firstTable = NULL;
    table *lastTable = NULL;
    entry *curEntry = NULL;
    
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol(/* ... */){
        table *newTable = malloc(sizeof(table));

        if(firstTable == NULL){
            newTable->scopeLev = scopeLevel;
            newTable->prev = NULL;
            newTable->firstEntry = NULL;
            newTable->next = NULL;
            firstTable = newTable;
            lastTable = newTable;
        }else{
            lastTable->next = newTable;
            newTable->prev = lastTable;
            newTable->scopeLev = scopeLevel;
            newTable->firstEntry = NULL;
            newTable->next = NULL;
            lastTable = newTable;
        }
    }
    static void insert_symbol(char *varName, char *varType, char *elmType){
        //malloc a new enrty
        entry *newEntry = malloc(sizeof(entry));
        newEntry->index = malloc(sizeof(int));
        newEntry->name = malloc(sizeof(varName)+1);
        newEntry->type = malloc(sizeof(varType)+1);
        newEntry->address = malloc(sizeof(address));
        newEntry->LineNo = malloc(sizeof(yylineno));
        newEntry->elementType = malloc(sizeof(elmType)+1);

        //assign member value of new entry
        if(lastTable->firstEntry ==NULL){ //first entry of the table
            newEntry->index = 0;
            strcpy(newEntry->name, varName);
            strcpy(newEntry->type, varType);
            newEntry->address = address;
            newEntry->LineNo = yylineno;
            strcpy(newEntry->elementType, elmType);
            newEntry->next = NULL;
            lastTable->firstEntry = newEntry;
            lastTable->lastEntry = newEntry;
        }else{  //there are already entries in the table
            newEntry->index = lastTable->lastEntry->index + 1;
            strcpy(newEntry->name, varName);
            strcpy(newEntry->type, varType);
            newEntry->address = address;
            newEntry->LineNo = yylineno;
            strcpy(newEntry->elementType, elmType);
            newEntry->next = NULL;
            lastTable->lastEntry->next = newEntry;
            lastTable->lastEntry = newEntry;
        }
    }
    static bool lookup_symbol(char *varName, int mode){ //mode 0:find in all scope , mode1:find in current scope
        switch(mode){
            case 0:
                if(lastTable!=NULL){
                    for(table *tableItor = lastTable;tableItor!=NULL;tableItor = tableItor->prev){
                        if(tableItor->firstEntry!=NULL){
                            for(entry *entryItor = tableItor->firstEntry;entryItor!=NULL;entryItor = entryItor->next){
                                if(strcmp(entryItor->name,varName) == 0){
                                    curEntry = entryItor;
                                    return true;
                                }
                            }
                        }
                    }
                }
                return false;
                break;
            case 1:
                if(lastTable!=NULL){
                    if(lastTable->firstEntry!=NULL){
                        for(entry *entryItor = lastTable->firstEntry;entryItor!=NULL;entryItor = entryItor->next){
                            if(strcmp(entryItor->name,varName) == 0){
                                curEntry = entryItor;
                                return true;
                            }
                        }
                    }
                }
                return false;
                break;
        }
        return false;
    }
    void freeTable(){
        table *tmp = lastTable;
        if(lastTable->prev!=NULL){
            lastTable = lastTable->prev;
            lastTable->next = NULL;
        }
        if(tmp->firstEntry!=NULL){
            entry *tmpEntry = tmp->firstEntry;
            entry *tmpEntry2;
            while(tmpEntry->next!=NULL){
                tmpEntry2 = tmpEntry;
                tmpEntry = tmpEntry->next;
                printf("%-10d%-10s%-10s%-10d%-10d%s\n", tmpEntry2->index, tmpEntry2->name, tmpEntry2->type, tmpEntry2->address, tmpEntry2-> LineNo, tmpEntry2->elementType);
                free(tmpEntry2);
            }
            printf("%-10d%-10s%-10s%-10d%-10d%s\n", tmpEntry->index, tmpEntry->name, tmpEntry->type, tmpEntry->address, tmpEntry-> LineNo, tmpEntry->elementType);
            free(tmpEntry);
        }
        free(tmp);        
    }
    
    static void dump_symbol(/* ... */){
        printf("> Dump symbol table (scope level: %d)\n", scopeLevel);
        printf("%-10s%-10s%-10s%-10s%-10s%s\n", "Index", "Name", "Type", "Address", "Lineno", "Element type");
        freeTable();
    }
    
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    bool b_val;
    char *s_val;

    struct st{
        char *id_name;
        char *type_name;
        char *op_name;
    }ctr;
    
    /* ... */
}

/* Token without return */
%token INT FLOAT BOOL STRING
%token '+' '-' '*' '/' '%' '"' ';' 
%token INC DEC GTR LSS GEQ LEQ EQL NEQ ASSIGN 
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token AND OR NOT '(' ')' '[' ']' '{' '}' COMMA
%token PRINT RETURN IF ELSE FOR WHILE
%token CONTINUE BREAK VOID

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <b_val> BOOL_LIT
%token <s_val> STRING_LIT
%token <ctr.id_name> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <ctr.type_name> TypeName Type
%type <ctr.type_name> Expression UnaryExpr PrimaryExpr Operand Literal IndexExpr ConversionExpr Condition
%type <ctr.type_name> Expression2 Expression3 Expression4 Expression5 Expression6 
%type <ctr.op_name> cmp_op add_op mul_op binary_op unary_op assign_op

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList
;

Expression
    : Expression OR Expression2 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, "OR", strcmp($1,"bool")==0?$3:$1);
        }else{
            if(strcmp($1,"bool")==0){
                codegen("ior\n");
            }
        }
        printf("%s\n", "OR");
    }
    | Expression2
;
Expression2
    : Expression2 AND Expression3 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, "AND", strcmp($1,"bool")==0?$3:$1);
        }else{
            if(strcmp($1,"bool")==0){
                codegen("iand\n");
            }
        }
        printf("%s\n", "AND");
    }
    | Expression3
;
Expression3
    : Expression3 cmp_op Expression4 { 
        if(strcmp($1,"int")==0){
            codegen("isub\n");
        }else if(strcmp($1,"float")==0){
            codegen("fcmpl\n");
        }
        if(strcmp($2,"EQL")==0){
            codegen("ifeq L_cmp_true_%d\n",labelNum);
        }else if(strcmp($2,"NEQ")==0){
            codegen("ifne L_cmp_true_%d\n",labelNum);
        }else if(strcmp($2,"LSS")==0){
            codegen("iflt L_cmp_true_%d\n",labelNum);
        }else if(strcmp($2,"LEQ")==0){
            codegen("ifle L_cmp_true_%d\n",labelNum);
        }else if(strcmp($2,"GTR")==0){
            codegen("ifgt L_cmp_true_%d\n",labelNum);
        }else if(strcmp($2,"GEQ")==0){
            codegen("ifge L_cmp_true_%d\n",labelNum);
        }
        codegen("iconst_0\n");
        codegen("goto L_cmp_%d\n",labelNum_2);
        codegen("L_cmp_true_%d:\n",labelNum);
        labelNum++;
        codegen("iconst_1\n");
        codegen("L_cmp_%d:\n",labelNum_2);
        labelNum_2++;

        $$ = "bool"; 
        printf("%s\n", $2);
    }
    | Expression4
;
Expression4
    : Expression4 add_op Expression5 {
        if(strcmp($1, $3) != 0){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
        }else{
            if(strcmp($1, "int") == 0 && strcmp($2, "ADD") == 0){
                codegen("iadd\n");
            }else if(strcmp($1, "int") == 0 && strcmp($2, "SUB") == 0){
                codegen("isub\n");
            }else if(strcmp($1, "float") == 0 && strcmp($2, "ADD") == 0){
                codegen("fadd\n");
            }else if(strcmp($1, "float") == 0 && strcmp($2, "SUB") == 0){
                codegen("fsub\n");
            }
        }
        
        printf("%s\n", $2);
    }
    | Expression5
;
Expression5
    : Expression5 mul_op Expression6 {
        if(strcmp($1, $3) != 0){
            if(strcmp($2, "REM") == 0){
                printf("error:%d: invalid operation: (operator %s not defined on %s)\n", yylineno, $2, strcmp($1,"int")==0?$3:$1);
            }    
        }else{
            if((strcmp($1, "float") == 0||strcmp($3, "float") == 0) && strcmp($2, "MUL") == 0){
                codegen("fmul\n");
            }else if((strcmp($1, "float") != 0 && strcmp($3, "float") != 0) && strcmp($2, "MUL") == 0){
                codegen("imul\n");
            }else if((strcmp($1, "float") == 0||strcmp($3, "float") == 0) && strcmp($2, "QUO") == 0){
                codegen("fdiv\n");
            }else if((strcmp($1, "float") != 0 && strcmp($3, "float") != 0) && strcmp($2, "QUO") == 0){
                codegen("idiv\n");
            }else if((strcmp($1, "int") == 0 && strcmp($3, "int") == 0) && strcmp($2, "REM") == 0){
                codegen("irem\n");
            }
        }
        printf("%s\n", $2);
    }
    | Expression6
;
Expression6
    :  UnaryExpr { $$ = $1; }
;

UnaryExpr
    : PrimaryExpr { $$ = $1; }
    | unary_op UnaryExpr {
        if(strcmp($1,"NOT")==0){
            codegen("iconst_1\n");
            codegen("ixor\n");
        }else if(strcmp($1,"NEG")==0 && strcmp($2,"int")==0){
            codegen("ineg\n");
        }else if(strcmp($1,"NEG")==0 && strcmp($2,"float")==0){
            codegen("fneg\n");
        }
        printf("%s\n", $1);
        $$ = $2;
    }
;

binary_op
    : OR { $$ = "OR"; }
    | AND { $$ = "AND"; }
    | cmp_op { $$ = $1; }
    | add_op { $$ = $1; }
    | mul_op{ $$ = $1; }
;

cmp_op 
    : EQL { $$ = "EQL"; }
    | NEQ { $$ = "NEQ"; }
    | LSS { $$ = "LSS"; }
    | LEQ { $$ = "LEQ"; }
    | GTR { $$ = "GTR"; }
    | GEQ { $$ = "GEQ"; }
;

add_op 
    : '+' { $$ = "ADD"; }
    | '-' { $$ = "SUB"; }
;

mul_op 
    : '*' { $$ = "MUL"; }
    | '/' { $$ = "QUO"; }
    | '%' { $$ = "REM"; }
;

unary_op 
    : '+' { $$ = "POS"; }
    | '-' { $$ = "NEG"; }
    | NOT { $$ = "NOT"; }
;

PrimaryExpr 
    : Operand { $$ = $1; }
    | IndexExpr { $$ = $1; }
    | ConversionExpr { $$ = $1; }
;

Operand 
    : Literal { $$ = $1; }
    | IDENT {
        if(lookup_symbol($1,0)){
            printf("IDENT (name=%s, address=%d)\n", $1, curEntry->address);
            if(strcmp(curEntry->type,"array") == 0){
                codegen("aload %d\n",curEntry->address);
                $$ = curEntry->elementType;
            }else{
                if(strcmp(curEntry->type,"int")==0){
                    codegen("iload %d\n",curEntry->address);
                }else if(strcmp(curEntry->type,"float")==0){
                    codegen("fload %d\n",curEntry->address);
                }else if(strcmp(curEntry->type,"bool")==0){
                    codegen("iload %d\n",curEntry->address);
                }else if(strcmp(curEntry->type,"string")==0){
                    codegen("aload %d\n",curEntry->address);
                }
                $$ = curEntry->type;
            }
        }else{
            printf("error:%d: undefined: %s\n", yylineno, $1);
            HAS_ERROR = true;
            $$ = "undefined";
        }
        isLiteral = false;
    }
    | '(' Expression ')' { $$ = $2; }
;

IndexExpr 
    : PrimaryExpr '[' Expression ']' { 
        if(strcmp($1,"int")==0){
            codegen("iaload\n");
        }else if(strcmp($1,"float")==0){
            codegen("faload\n");
        }
        $$ = $1; 
        isLiteral = false;
    }
;

ConversionExpr 
    : '(' Type ')' Expression {
        if(strcmp($2,"int") == 0){
            codegen("f2i\n");
            printf("F to I\n");
        }else if(strcmp($2,"float") == 0){
            codegen("i2f\n");
            printf("I to F\n");
        }
        $$ = $2;
    }
;

Type
    : TypeName { $$ = $1; }
;

TypeName
    : INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | STRING { $$ = "string"; }
    | BOOL { $$ = "bool"; }
;

Literal
    : INT_LIT {
        codegen("ldc %d\n",$<i_val>1);
        printf("INT_LIT %d\n", $<i_val>1);
        $$ = "int";
        isLiteral = true;
    }
    | FLOAT_LIT {
        codegen("ldc %f\n",$<f_val>1);
        printf("FLOAT_LIT %f\n", $<f_val>1);
        $$ = "float";
    }
    | BOOL_LIT {
        if($1){
            codegen("iconst_1\n");
        }else{
            codegen("iconst_0\n");
        }
        printf("%s\n", $1 ? "TRUE" : "FALSE");
        $$ = "bool";
    }
    | STRING_LIT {
        codegen("ldc \"%s\"\n",$1);
        printf("STRING_LIT %s\n", $1);
        $$ = "string";
    }
;

Statement
    : DeclarationStmt
    | AssignmentStmt
    | IncDecStmt
    | ExpressionStmt
    | Block
    | IfStmt
    | WhileStmt
    | ForStmt
    | PrintStmt
;

ExpressionStmt
    : Expression ';'
;

DeclarationStmt 
    : Type IDENT ';' {
        if(lookup_symbol($2,1)){
            HAS_ERROR = true;
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, $1, "-");
            if(strcmp($1,"int")==0){
                codegen("ldc 0\n");
                codegen("istore %d\n",address);
            }else if(strcmp($1, "float")==0){
                codegen("ldc 0.0\n");
                codegen("fstore %d\n",address);
            }else if(strcmp($1, "bool")==0){
                codegen("ldc 0\n");
                codegen("istore %d\n",address);
            }else if(strcmp($1, "string")==0){
                codegen("ldc \"\"\n");
                codegen("astore %d\n",address);
            }
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
    | Type IDENT ASSIGN Expression ';' {
        if(lookup_symbol($2,1)){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, $1, "-");
            if(strcmp($1,"int")==0){
                codegen("istore %d\n",address);
            }else if(strcmp($1, "float")==0){
                codegen("fstore %d\n",address);
            }else if(strcmp($1, "bool")==0){
                codegen("istore %d\n",address);
            }else if(strcmp($1, "string")==0){
                codegen("astore %d\n",address);
            }
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
    | Type IDENT '[' Expression ']' ';' {
        if(lookup_symbol($2,1)){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $2, curEntry->LineNo);
        }else{
            insert_symbol($2, "array", $1);
            codegen("newarray %s\n",$1);
            codegen("astore %d\n",address);
            ++address;
            printf("> Insert {%s} into symbol table (scope level: %d)\n", $2, scopeLevel);
        }
    }
;

AssignmentExpr 
    : Expression  assign_op {
            if(strcmp($1, "int") == 0 && isLiteral){
                isLiteralError = true;
                isLiteral = false;
            }
            assign_address = curEntry->address;
            if(strcmp($1,"int")==0 && strcmp($2,"ASSIGN")!=0){
                codegen("iload %d\n",assign_address);
            }else if(strcmp($1,"float")==0 && strcmp($2,"ASSIGN")!=0){
                codegen("fload %d\n",assign_address);
            }
        }
        Expression {
            if(strcmp($1,"undefined") != 0 && strcmp($1, $4) != 0){
                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $4);
            }
            if(isLiteralError){
                HAS_ERROR = true;
                printf("error:%d: cannot assign to int\n", yylineno);
                isLiteralError = false;
            }
            if(strcmp($2,"ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"float")==0){
                    codegen("fstore %d\n",assign_address);
                }else if(strcmp($1,"bool")==0){
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"string")==0){
                    codegen("astore %d\n",assign_address);
                }
            }else if(strcmp($2,"ADD_ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("iadd\n");
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"float")==0){
                    codegen("fadd\n");
                    codegen("fstore %d\n",assign_address);
                }
            }else if(strcmp($2,"SUB_ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("isub\n");
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"float")==0){
                    codegen("fsub\n");
                    codegen("fstore %d\n",assign_address);
                }
            }else if(strcmp($2,"MUL_ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("imul\n");
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"float")==0){
                    codegen("fmul\n");
                    codegen("fstore %d\n",assign_address);
                }
            }else if(strcmp($2,"QUO_ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("idiv\n");
                    codegen("istore %d\n",assign_address);
                }else if(strcmp($1,"float")==0){
                    codegen("fdiv\n");
                    codegen("fstore %d\n",assign_address);
                }
            }else if(strcmp($2,"REM_ASSIGN")==0){
                if(strcmp($1,"int")==0){
                    codegen("irem\n");
                    codegen("istore %d\n",assign_address);
                }
            }
            printf("%s\n",$2);
        }
;

AssignmentStmt 
    : AssignmentExpr ';'
;

assign_op 
    : ASSIGN { $$ = "ASSIGN";}
    | ADD_ASSIGN { $$ = "ADD_ASSIGN";}
    | SUB_ASSIGN { $$ = "SUB_ASSIGN";}
    | MUL_ASSIGN { $$ = "MUL_ASSIGN";}
    | QUO_ASSIGN { $$ = "QUO_ASSIGN";}
    | REM_ASSIGN { $$ = "REM_ASSIGN";}
;

IncDecExpr 
    : Expression INC {
        if(strcmp($1,"int")==0){
            codegen("ldc 1\n");
            codegen("iadd\n");
            codegen("istore %d\n",curEntry->address);
        }else if(strcmp($1,"float")==0){
            codegen("ldc 1.0\n");
            codegen("fadd\n");
            codegen("fstore %d\n",curEntry->address);
        }
        printf("INC\n");
    }
    | Expression DEC {
        if(strcmp($1,"int")==0){
            codegen("ldc 1\n");
            codegen("isub\n");
            codegen("istore %d\n",curEntry->address);
        }else if(strcmp($1,"float")==0){
            codegen("ldc 1.0\n");
            codegen("fsub\n");
            codegen("fstore %d\n",curEntry->address);
        }
        printf("DEC\n");
    }
;

IncDecStmt 
    : IncDecExpr ';'
;

Block 
    : '{' {
        ++scopeLevel;
        create_symbol();
    } StatementList '}' {
        dump_symbol();
        --scopeLevel;
    }
;

StatementList 
    : Statement StatementList
    | 
;

IfStmt 
    : IF Condition Block ElseStmt 
;

ElseStmt
    : ELSE IfStmt
    | ELSE Block
    |
;

Condition 
    : Expression { 
        $$ = $1;
        if(strcmp($1,"bool")!=0){
            printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, $1);
        }
    }
;

WhileStmt 
    : WHILE '(' Condition ')' Block 
;

ForStmt 
    : FOR '(' ForClause ')' Block
;

ForClause 
    : InitStmt ';' Condition ';' PostStmt 
;

InitStmt 
    : SimpleExpr
;

PostStmt 
    : SimpleExpr
;

SimpleExpr 
    : AssignmentExpr 
    | Expression 
    | IncDecExpr
;

PrintStmt 
    : PRINT '(' Expression ')' ';'{
        printf("PRINT %s\n", $3);
        if(strcmp($3,"int")==0){
            codegen("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            codegen("swap\n");
            codegen("invokevirtual java/io/PrintStream/print(I)V\n");
        }else if(strcmp($3,"string")==0){
            codegen("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            codegen("swap\n");
            codegen("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }else if(strcmp($3,"float")==0){
            codegen("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            codegen("swap\n");
            codegen("invokevirtual java/io/PrintStream/print(F)V\n");
        }else if(strcmp($3,"bool")==0){
            codegen("ifne L_cmp_true_%d\n",labelNum);
            codegen("ldc \"false\"\n");
            codegen("goto L_cmp_%d\n",labelNum_2);
            codegen("L_cmp_true_%d:\n",labelNum);
            labelNum++;
            codegen("ldc \"true\"\n");
            codegen("L_cmp_%d:\n",labelNum_2);
            labelNum_2++;
            codegen("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            codegen("swap\n");
            codegen("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }
    }
;


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    codegen(".source hw3.j\n");
    codegen(".class public Main\n");
    codegen(".super java/lang/Object\n");
    codegen(".method public static main([Ljava/lang/String;)V\n");
    codegen(".limit stack 100\n");
    codegen(".limit locals 100\n");
    INDENT++;

    create_symbol();
    yyparse();
    dump_symbol();

	printf("Total lines: %d\n", yylineno);


    /* Codegen end */
    codegen("return\n");
    INDENT--;
    codegen(".end method\n");
    fclose(fout);
    fclose(yyin);

    if (HAS_ERROR) {
        remove(bytecode_filename);
    }
    return 0;
}
