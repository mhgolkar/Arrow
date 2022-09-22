# Arrow HTML-JS Runtime

This runtime helps you convert any Arrow project to a playable HTML document.

HTML-JS runtime is integrated with Arrow editor (used in quick playable exports)
and _as is_ mainly targets development purposes such as play-testing and review.

> [Customization](#customization) helpers such as data-attribute reflections are also supported,
> which may be used to style and shape the final output for prototyping or production.


## How to

### Quick Export

HTML-JS official runtime is bundled with Arrow (editor) as a pre-built template (and the source;)
so you can easily generate playable copies of any project, *as a single file HTML*, using:

`Inspector (Panel) > Project (Tab) > Export (Menu Button) > Export HTML`

> After the first export, you can use `Ctrl + E` shortcut
> to re-export (with changes) even quicker, overwriting the last exported file.

This way you have a single `.html` document of your project
exported with all default configuration, ready to play.

> The single file template `<Arrow>/runtimes/html-js.arrow-runtime` is used in this process,
> which is built by inlining all the modules of `<Arrow>/runtimes/html-js` source directory into one file.

### Using source

If you want to customize how the runtime plays your project, you can work with the source directly.

The process of running a project is fairly simple.
The runtime reads and interprets data from a constant called `PROJECT` in `./project.js` file.
You can use content of a `.json` file exported (and purged from dev data) from editor or
even of a full `.arrow` project document directly as the value for the constant.

Here are the steps for normal scenarios:

1. Export your project as `JSON` via `Inspector (Panel) > Project (Tab) > Export (Menu) > ...`.
2. Edit the `./project.js` file using a text editor and replace `{/*project_json*/}` with the content of your export.
3. You may want to replace mustache tags (such as `{{project_title}}`) in the source files as well.

It's done.
Browse the `index.html` file to play your project.

### Hybrid!

Arrow editor is capable of (re-) building the `html-js.arrow-runtime` template from the bundled source.
It means you can [customize](#customization) the runtime as you wish,
and use [Quick Export](#quick-export) method
to have the playable with all your changes.

You only need to *activate `Auto Rebuild Runtime(s)`* from quick preferences.
Arrow will detect changes in source files (using their modification-time)
and builds the template automatically.


## Customization

### Building Customized Runtime Template

Arrow uses `html-js.arrow-runtime` template file
to [Quick Export](#quick-export) projects as playable HTML documents.
This template file is non-compressed and may be directly customized;
but an easier or cleaner approach may be to edit the source files
(in `<Arrow>/runtimes/html-js`) and then re-build the template.

> You can easily run any project [using source](#using-source) directly.
> The template approach is designed to help with 
> [Quick Export](#quick-export) and [Hybrid](#hybrid) methods.

Arrow editor is capable of re-building the `html-js.arrow-runtime`
template file with no extra dependency.

Rebuilding process runs automatically under one of following conditions:
+ If the template file does not exist (i.e. is manually removed.)
+ The source files are changed (by modification-time,) and `Auto Rebuild Runtime(s)` quick preference is active.

During the process, all the embedded `.css` and `.js` files
that are placed between `@inline` and `@inline-end` comments (in `<head>`,)
will be inlined to the `index.html` file, which will then be saved
as a single HTML file with a different extension.

The process is run only when user tries to export a project as playable `HTML`.

Rebuilt template will override the older file.

> The built template is not compressed or minified, just inlined (so are the quick exports.)
> Arrow currently does not plan to support any beautification (also minification) in this process.

### I18N

To add a new supported locale/language or edit default messages,
check out `_TRANSLATION_TABLE` in `./modules/shared-i18n.js` file.

To change the runtime's locale, change `_LOCALE` constant
in `./arrow.js` file to any supported locale.

### Removing the *Back* Button

If you don't intend to let players go backwards in the play,
find and remove the line

```HTML
<button id="play-back">Back</button>
```

from exported `.html` file, the runtime template, and/or
`index.html` file in the runtime's source for a permanent change.

> Remember to [re-build](#building-customized-runtime-template)
> the template if you need the changes to reflect in the quick exports as well.

> Disclaimer:  
> Technically it will not eliminate the ability of going backwards.
> It only removes an element from the user interface which invokes the underlying step-back process.
> Such functionality will still be accessible through scripting and browser console to the users.

### Fully Manual (Debug) Play

This runtime allows nodes (such as hubs, generators, etc.)
to auto-play in case no user interaction is normally needed during play.

You can force a fully manual play/skip by setting following constant in `arrow.js` file to `false`:

```JS
const _ALLOW_AUTO_PLAY = true;
```

It is also possible to keep skipped nodes displayed, by removing following block from `arrow.css` file:

```CSS
.node[data-played='true'][data-skipped='true'] {
    display: none;
}
```

### CSS Styling Helpers

To style node types, you can edit `arrow.css` file, where you can find corresponding placeholder blocks.

You can also take advantage of style helper *data-attributes*, which will be set automatically by the runtime.

The most general of these helpers are set for every appended `.node` HTML block:

```CSS
.node[data-name][data-type][data-uid][data-played='true|false']
```

Other style helper data-attributes are:

+ current value of every variables set on the `#console` element:
    
    ```HTML
    <section id="console" data-{variable-name}="{current-value}" ...
    ```

+ space separated list of all appended nodes on the `#content` element:

    ```HTML
    <article id="content" data-open-nodes="{node-names space separated}" ...
    ```

> Node and variable names are lowercase and escaped by replacing whitespaces with dashes (`-`)

+ Node-type specific helpers:

    + E.g. Attributes for `character-profile` elements of `dialog` nodes:

        ```CSS
        .character-profile[data-name='{character-name}']
        ```

        or

        ```CSS
        .character-profile[data-tag-{key}='{value}']
        /* set for each `key: value` tag of character's */
        ```
    
    > You can find more information about such helpers in `arrow.css` file.

### Hybrid Styling Options

Arrow and this runtime support `BBCode` for styling `content` nodes as well.
This is specially useful when you want to publish playable exports directly from Arrow,
or have styling in your own custom runtime.

The HTML-JS runtime supports
`[b]`, `[i]`, `[u]`, `[h1-6]`, `[color]`, `[size]`, `[img]`, `[url]`, `[p]`
and few more blocks out of the box.

But the most exciting part is that you can combine power of CSS
(and optionally the [styling helpers](#css-styling-helpers))
with the `[attr]` custom BBcode.

`[attr]` will add a data-attribute to the finally created HTML block,
so you can style inner parts of your content.

As an example, following line in a content node:

```BBCode
[attr=data-place value=home] Look at this place! [/attr]
```

will be translated to

```HTML
<span data-place="home"> Look at this place! </span>
```

so we can style it like this:

```CSS
[data-place="home"]{
    color: green;
}
```

Another option is the custom BBCode `[style]`:

```BBCode
I'm a brave [style=font-size:3rem; font-weight:bold; color:brown;] Big [/style] bear!
```

This quick-and-dirty style block, will be translated to
*inline css* for the final HTML created in runtime:

```HTML
I'm a brave <span style="font-size:3rem; font-weight:bold; color:brown;"> Big </span> bear!
```

This method is specially useful on fast iterations or
when you don't intend to modify or rebuild the runtime template.

> Hybrid styling options are supported by Arrow's official runtime,
> but may or may not behave the exact same way in other runtimes or in the console.


Feel free to experiment with this runtime,  
and make it work for you.

