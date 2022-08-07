// Arrow HTML-JS Runtime: BBCode parser module

// This parser is a modified fork of
// [JS BBCode Parser v3.0.4 - License: MIT](https://github.com/DasRed/js-bbcode-parser)

const DEFAULT_BBCODE_MAPPING = {

    '\\[br\\]': '<br>',

    '\\[b\\](.+?)\\[/b\\]': '<strong>$1</strong>',
    '\\[i\\](.+?)\\[/i\\]': '<em>$1</em>',
    '\\[u\\](.+?)\\[/u\\]': '<u>$1</u>',

    '\\[h1\\](.+?)\\[/h1\\]': '<h1>$1</h1>',
    '\\[h2\\](.+?)\\[/h2\\]': '<h2>$1</h2>',
    '\\[h3\\](.+?)\\[/h3\\]': '<h3>$1</h3>',
    '\\[h4\\](.+?)\\[/h4\\]': '<h4>$1</h4>',
    '\\[h5\\](.+?)\\[/h5\\]': '<h5>$1</h5>',
    '\\[h6\\](.+?)\\[/h6\\]': '<h6>$1</h6>',

    '\\[p\\](.+?)\\[/p\\]': '<p>$1</p>',

    '\\[color=(.+?)\\](.+?)\\[/color\\]':  '<span style="color:$1">$2</span>',
    '\\[size=([0-9]+)\\](.+?)\\[/size\\]': '<span style="font-size:$1px">$2</span>',

    '\\[img\\](.+?)\\[/img\\]': '<img src="$1">',
    '\\[img=(.+?)\\]':          '<img src="$1">',

    '\\[email\\](.+?)\\[/email\\]':       '<a href="mailto:$1">$1</a>',
    '\\[email=(.+?)\\](.+?)\\[/email\\]': '<a href="mailto:$1">$2</a>',

    '\\[url\\](.+?)\\[/url\\]':                      '<a href="$1">$1</a>',
    '\\[url=(.+?)\\|onclick\\](.+?)\\[/url\\]':      '<a onclick="$1">$2</a>',
    '\\[url=(.+?)\\starget=(.+?)\\](.+?)\\[/url\\]': '<a href="$1" target="$2">$3</a>',
    '\\[url=(.+?)\\](.+?)\\[/url\\]':                '<a href="$1">$2</a>',

    '\\[a=(.+?)\\](.+?)\\[/a\\]': '<a href="$1" name="$1">$2</a>',

    '\\[list\\](.+?)\\[/list\\]': '<ul>$1</ul>',
    '\\[\\*\\](.+?)\\[/\\*\\]':   '<li>$1</li>',

    '\\[attr=(.+?)\\svalue=(.+?)\\](.+?)\\[/attr\\]': '<span $1="$2">$3</span>',
    '\\[attr=(.+?)\\](.+?)\\[/attr\\]':               '<span $1>$2</span>',
    
    '\\[style=(.+?)\\](.+?)\\[/style\\]': '<span style="$1">$2</span>',

};

class BBCodeParser {

    constructor(codes) {
        this.codes = [];
        this.setCodes(codes);
    }

    parse(text) {
        return this.codes.reduce((text, code) => text.replace(code.regexp, code.replacement), text);
    }

    add(regex, replacement) {
        this.codes.push({
            regexp: new RegExp(regex, 'igm'),
            replacement: replacement
        });
        return this;
    }

    setCodes(codes) {
        this.codes = Object.keys(codes).map(function (regex) {
            const replacement = codes[regex];
            return {
                regexp: new RegExp(regex, 'igm'),
                replacement: replacement
            };
        }, this);
        return this;
    }

}

const DEFAULT_BBCODE_PARSER = new BBCodeParser(DEFAULT_BBCODE_MAPPING); 
