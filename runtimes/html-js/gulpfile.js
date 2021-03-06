// Arrow
// HTML-JS Runtime
// Mor. H. Golkar

// This Gulp build helper (and the workarounds!) will generate `html-js.arrow-runtime` template file,
// which is used by the Arrow editor to make single-file playable HTML exports.

"use strict";

const SOURCE = __dirname;
const DESTINATION = `${SOURCE}/../`; // parent folder
const RUNTIME_TEMPLATE_FILENAME = {
    basename: 'html-js',
    extension: '.arrow-runtime'
};

const HTML_FILE = `./index.html`;
const CSS_CONCATNATION_LIST = [
    './arrow.css'
];
const SCRIPT_CONCATNATION_LIST = [
    './modules/shared-i18n.js',
    './modules/shared-bbcode-parser.js',
    './modules/shared.js',
    './modules/condition.js',
    './modules/content.js',
    './modules/dialog.js',
    './modules/entry.js',
    './modules/hub.js',
    './modules/interaction.js',
    './modules/jump.js',
    './modules/macro_use.js',
    './modules/marker.js',
    './modules/randomizer.js',
    './modules/user_input.js',
    './modules/variable_update.js',
    './arrow.js'
];
const DO_MANGLE = true; // if true makes a shorter and uglier file

const { normalize } = require('path');

const { src, dest, task } = require('gulp');
const concat = require('gulp-concat');
const terser = require('gulp-terser');
const change = require('gulp-change');
const rename = require('gulp-rename');
const htmlmin = require('gulp-htmlmin');
const cleanCSS = require('gulp-clean-css');
const preprocess = require('gulp-preprocess'); // for `@ifdef`
const runSequence = require('gulp4-run-sequence');

//---------
// Settings
//---------
//  Gulp settings note: for options that accept a function,
// the passed function will be called with each Vinyl object and must return a value of another listed type.

const DEFAULT_SRC_SETTINGS = {
    buffer: true,
    read: true,
    since: undefined, // date timestamp / function: When set, only creates Vinyl objects for files modified since the specified time.
    sourcemaps: false, // inline source maps
    resolveSymlinks: true, // When true, recursively resolves symbolic links to their targets. If false, preserves the symbolic links and sets the Vinyl object's symlink property to the original file's path
    follow: true, // If true, symlinked directories will be traversed when expanding ** globs. Note: This can cause problems with cyclical links.
    cwd: SOURCE, // default process.cwd, the directory that will be combined with any relative path to form an absolute path
    root: SOURCE, //The root path that globs are resolved against.
    base: SOURCE, // Explicitly set the base property on created Vinyl objects
    cwdbase: true, // If true, cwd and base options should be aligned
    allowEmpty: false, // When false, globs which can only match one file (such as foo/bar.js) causes an error to be thrown if they don't find a match.
    uniqueBy: 'path', // string/function: Remove duplicates from the stream by comparing the string property name or the result of the function. Note: When using a function, the function receives the streamed data (objects containing cwd, base, path properties).
    dot: true, // If true, compare globs against dot files, like `.gitignore`.
    mark: false, // If true, a / character will be appended to directory matches. Generally not needed because paths are normalized within the pipeline
    nosort: false, // If true, disables sorting the glob results.
    strict: true, // If true, an error will be thrown if an unexpected problem is encountered while attempting to read a directory.
    nounique: false, // When false, prevents duplicate files in the result set
    debug: false, // If true, [TOO MUCH] debugging information will be logged to the command line.
    silent: false, // [This is better than `debug`] When true, suppresses warnings from printing on stderr.
    nocase: false, // If true, performs a case-insensitive match
    matchBase: false, // If true and globs don't contain any / characters, traverses all directories and matches that glob - e.g. *.js would be treated as equivalent to **/*.js.
    nodir: false, // If true, only matches files, not directories. Note: To match only directories, end your glob with a /.
    nocomment: false, // When false, treat a # character at the start of a glob as a comment.
    // For options that accept a function, the passed function will be called with each Vinyl object and must return a value of another listed type.
};

const DEFAULT_DEST_SETTINGS = {
    cwd: DESTINATION, // string/function: The directory that will be combined with any relative path to form an absolute path. Is ignored for absolute paths. Use to avoid combining directory with path.join().
    // mode: undefined, // number/function: stat.mode of the Vinyl object	The mode used when creating files. If not set and stat.mode is missing, the process' mode will be used instead.
    // dirMode: undefined, // number/function: The mode used when creating directories. If not set, the process' mode will be used.
    overwrite: true, // boolean/function: When true, overwrites existing files with the same path.
    append: false, // boolean/function: If true, adds contents to the end of the file, instead of replacing existing contents.
    sourcemaps: false, // boolean/string/function: If true, writes inline sourcemaps to the output file. Specifying a string path will write external sourcemaps at the given path.
    relativeSymlinks: true, // boolean/function: When false, any symbolic links created will be absolute. Note: Ignored if a junction is being created, as they must be absolute.
    useJunctions: true, // boolean/function: This option is only relevant on Windows and ignored elsewhere. When true, creates directory symbolic link as a junction. Detailed in Symbolic links on Windows below.
};

const SETTINGS_HTML_MINIFIER = {
    // Wrapper: https://www.npmjs.com/package/gulp-htmlmin
    // Docs: https://github.com/kangax/html-minifier
    html5: true, caseSensitive: true,
    removeComments: true, processConditionalComments: false,
    collapseWhitespace: true, collapseInlineTagWhitespace: true, conservativeCollapse: true, preserveLineBreaks: false,
    removeEmptyAttributes: false, removeAttributeQuotes: false, removeTagWhitespace: true, /* caution! */
    minifyURLs: false, minifyCSS: false, minifyJS: false, collapseBooleanAttributes: false,
    includeAutoGeneratedTags: false, sortAttributes: false, sortClassName: false, useShortDoctype: false,
};

const SETTINGS_TERSER = {
    // Wrapper: https://www.npmjs.com/package/gulp-terser
    // Docs: https://github.com/terser/terser#minify-options
    ecma: 2018, // defaulf 5. pass 5 2015, 2016, etc to override compress and format's ecma options. Pass 2015 or greater to enable compress options that will transform ES5 code into smaller ES6+ equivalent forms
    parse: { // additional parse options.
        bare_returns: true, // (default false) -- support top level return statements
        html5_comments: true, // (default true)
        shebang: true, // (default true) -- support #!command as the first line
    },
    compress: { // pass false to skip compressing entirely. Pass an object to specify custom compress options.
        defaults: false, // (default: true) -- Pass false to disable most default enabled compress transforms. Useful when you only want to enable a few compress options while disabling the rest.
        passes: 1, // The maximum number of times to run compress
        arrows: false, arguments: false, booleans: false, booleans_as_integers: false,
        collapse_vars: false, comparisons: false, computed_props: false, conditionals: false, dead_code: false,
        directives: false, drop_console: false, drop_debugger: false, evaluate: false, expression: false,
        global_defs: {},  // You can use the --define (-d) switch in order to declare global variables that Terser will assume to be constants (unless defined in scope). For example if you pass --define DEBUG=false then, coupled with dead code removal Terser will discard the following from the output: `if (DEBUG) { console.log("debug stuff");`}
        hoist_funs: false, hoist_props: false, hoist_vars: false, if_return: false, inline: false, join_vars: true,
        keep_classnames: true, keep_fargs: true, keep_fnames: false, keep_infinity: true, loops: false,
        module: false, negate_iife: false, properties: false, pure_funcs: null, pure_getters: false, reduce_funcs: false, reduce_vars: false,
        sequences: false, side_effects: false, switches: false, typeofs: false, unsafe: false,
        unused: false, // drop unreferenced functions and variables (simple direct variable assignments do not count as references unless set to "keep_assign")
        toplevel: false, // drops unreferenced functions in top level
        top_retain: [], // prevent specific toplevel functions and variables from unused removal (can be array, comma-separated, RegExp or function. Implies toplevel)
    },
    mangle: DO_MANGLE, // (default true) — pass false to skip mangling names, or pass an object to specify mangle options (see below).
    /* {
        eval: false, keep_classnames: true, keep_fnames: false, module: false,
        toplevel: true, // true to mangle names declared in the top level scope (NOTE: differs with compress.toplevel)
        safari10: false,
        reserved: getPreservedKeywords(),
        properties: { // (default false) — a subcategory of the mangle option. Pass an object to specify custom mangle property options.
            builtins: false, // mangling of builtin DOM properties 
            debug: "_dbg_", // Mangle names with the original name still present. Pass an empty string "" to enable, or a non-empty string to set the debug suffix.
            keep_quoted: true, // Only mangle unquoted property names
            regex: null, // mangle property matching the regular expression
            reserved: getPreservedKeywords(),
            undeclared: false // Mangle those names when they are accessed as properties of known top level variables but their declarations are never found in input code
        }
    },*/
    format: { // (default null) — pass an object if you wish to specify additional format options. The defaults are optimized for best compression.
        ascii_only: false, beautify: false, braces: true,
        comments: false, //  (default "some") -- by default it keeps JSDoc-style comments that contain "@license" or "@preserve", pass true or "all" to preserve all comments, false to omit comments in the output, a regular expression string (e.g. /^!/) or a function
        indent_level: 0, indent_start: 0, inline_script: false, keep_numbers: true, keep_quoted_props: true,
        max_line_len: false, preamble: null, quote_keys: false, quote_style: 3, preserve_annotations: true,
        safari10: false, semicolons: true, shebang: true, webkit: true, wrap_iife: false, wrap_func_args: false,
    },
    module: false, // (default false) — Use when minifying an ES6 module. "use strict" is implied and names can be mangled on the top scope. If compress or mangle is enabled then the toplevel option will be enabled.
    sourceMap: false, // (default false) - pass an object if you wish to specify source map options.
    toplevel: true, // (default false) - set to true if you wish to enable top level variable and function name mangling and to drop unused variables and functions.
    nameCache: undefined, // (default null) - pass an empty object {} or a previously used nameCache object if you wish to cache mangled variable and property names across multiple invocations of minify(). Note: this is a read/write property. minify() will read the name cache state of this object and update it during minification so that it may be reused or externally persisted by the user.
    ie8: false, // (default false) - set to true to support IE8.
    keep_classnames: true, // (default: undefined) - pass true to prevent discarding or mangling of class names. Pass a regular expression to only keep class names matching that regex.
    keep_fnames: false, // (default: false) - pass true to prevent discarding or mangling of function names. Pass a regular expression to only keep class names matching that regex. Useful for code relying on Function.prototype.name. If the top level minify option keep_classnames is undefined it will be overridden with the value of the top level minify option keep_fnames.
    safari10: false, // (default: false) - pass true to work around Safari 10/11 bugs in loop scoping and await. See safari10 options in mangle and format for details.
};


// -----
// Tasks
// -----

var _MEMORY = {};

async function memorize(part_name, content, done){
    // console.log('Minified content generated:', part_name);
    _MEMORY[part_name] = content;
    done(null, content);
}

task( 'minifyScripts', function() {
    return (
        src( SCRIPT_CONCATNATION_LIST, DEFAULT_SRC_SETTINGS )
        .pipe( concat( { path: './scripts-concat.js', newLine: '\r\n' } ) )
        .pipe( terser( SETTINGS_TERSER ) )
        .pipe( change( memorize.bind( null, 'MINIFIED_SCRIPT' ) ) )
    );
});

task( 'minifyCss', function(){
    return (
        src( CSS_CONCATNATION_LIST, DEFAULT_SRC_SETTINGS )
        .pipe( concat( { path: './style-concat.css', newLine: '\r\n' } ) )
        .pipe( cleanCSS() )
        .pipe( change( memorize.bind( null, 'MINIFIED_CSS' ) ) )
    );
});

task( 'generateTemplateFile', function(){
    return (
        src( HTML_FILE, DEFAULT_SRC_SETTINGS )
        .pipe(
            preprocess({
                context: {
                    DEBUG: false, SINGLE_FILE_RUNTIME_BUILD: true,
                    MINIFIED_SCRIPT: `<script type="text/javascript"> const PROJECT = {{project_json}}; ${_MEMORY.MINIFIED_SCRIPT} </script>`,
                    MINIFIED_STYLE : `<style> ${_MEMORY.MINIFIED_CSS} </style>`  
                }
            })
        )
        .pipe( htmlmin( SETTINGS_HTML_MINIFIER ) )
        .pipe( rename(function (path) {
            // Updates the object in-place
            path.basename = RUNTIME_TEMPLATE_FILENAME.basename;
            path.extname = RUNTIME_TEMPLATE_FILENAME.extension;
        }))
        .pipe( dest( DESTINATION, DEFAULT_DEST_SETTINGS ) )
    );
});

task ( 'printGeneratedFilePath', function(cb){
    console.log(
        'Here is the Generated Runtime Template: \r\n',
        normalize( `${DESTINATION}${RUNTIME_TEMPLATE_FILENAME.basename}${RUNTIME_TEMPLATE_FILENAME.extension}` )
    );
    cb();
});

task( 'default', function (callback) {
    runSequence(
        [
            'minifyScripts',
            'minifyCss'
        ],
        'generateTemplateFile',
        'printGeneratedFilePath',
        callback
    );
});
