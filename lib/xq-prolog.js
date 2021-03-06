/** @babel */
import XQUtils from './xquery-helper';
import ASTVisitor from './visitor';

const namespaces = {
    tei: "http://www.tei-c.org/ns/1.0",
    xconf: "http://exist-db.org/collection-config/1.0",
    expath: "http://expath.org/ns/pkg",
    repo: "http://exist-db.org/xquery/repo"
};

export default class XQueryProlog extends ASTVisitor {

    constructor(editor) {
        super();
        this.editor = editor;
        this.version = null;
        this.module = null;
        this.importedModules = new Array();
        this.namespaces = new Array();
        const ast = editor.getBuffer()._ast;
        console.log(ast);
        this.visit(ast, this);
    }

    addImport(prefix, uri, at) {
        let code = `import module namespace ${prefix}="${uri}"`;
        if (at) {
            code += ` at "${at}"`;
        }
        code += ';';

        // determine insertion point
        let lastLine = 0;
        if (this.importedModules.length > 0) {
            lastLine = this.importedModules[this.importedModules.length - 1].line;
        } else if (this.namespaces.length > 0) {
            lastLine = this.namespaces[this.namespaces.length - 1].pos.el;
        } else if (this.module) {
            lastLine = this.module.line;
        } else if (this.version) {
            lastLine = this.version.pos.el;
        }
        this.editor.setCursorBufferPosition([lastLine, 0]);
        this.editor.moveToEndOfLine();
        this.editor.insertNewline();
        this.editor.insertText(code);
    }

    addNamespaceDecl(prefix) {
        let code;
        if (namespaces[prefix]) {
            code = `declare namespace ${prefix} = "${namespaces[prefix]}";\n`;
        } else {
            code = `declare namespace ${prefix} = "\${2:http://www.example.com/}";\n`;
        }
        let lastLine = 0;
        if (this.namespaces.length > 0) {
            lastLine = this.namespaces[this.namespaces.length - 1].pos.el;
        } else if (this.importedModules.length > 0) {
            lastLine = this.importedModules[this.importedModules.length - 1].line;
        } else if (this.module) {
            lastLine = this.module.line;
        } else if (this.version) {
            lastLine = this.version.pos.el;
        }
        this.editor.setCursorBufferPosition([lastLine, 0]);
        this.editor.moveToEndOfLine();
        this.editor.insertNewline();
        atom.packages.activatePackage('snippets').then((pkg) => {
            if (pkg && pkg.mainModule) {
                pkg.mainModule.insert(code, this.editor);
            }
        });
    }

    Prolog(prolog) {
        this.prolog = prolog;
        this.visitChildren(prolog, this);
    }

    VersionDecl(decl) {
        this.version = decl;
    }

    ModuleDecl(modDecl) {
        let child = XQUtils.findChild(modDecl, "NCName");
        const prefix = child ? XQUtils.getValue(child) : null;
        child = XQUtils.findChild(modDecl, 'URILiteral');
        const uri = child ? child.value.replace(/^"?(.*?)"?$/, "$1") : null;
        this.module = {
            prefix: prefix,
            uri: uri,
            line: modDecl.pos.el
        };

        this.visitChildren(modDecl, this);
    }

    NamespaceDecl(decl) {
        this.namespaces.push(decl);
    }

    ModuleImport(modImport) {
        const uris = XQUtils.findChildren(modImport, 'URILiteral');
        const props = {
            "uri": uris[0].value.replace(/^"?(.*?)"?$/, "$1"),
            "line": modImport.pos.el
        };
        if (uris.length > 1) {
            props.at = uris[1].value;
        }
        this.importedModules.push(props);
    }
}
