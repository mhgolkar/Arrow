# Arrow HTML-JS Runtime
This runtime helps you convert any Arrow project to a playable HTML document.


## How to

### Quick Export

HTML-JS official runtime is bundled with Arrow as a template (besides the source;)
so you can easily generate playable copies of any project, *as HTML*, with defaults, via:

`Inspector (Panel) > Project (Tab) > Export (Menu Button) > Export HTML`

This way you have a single, compressed `.html` document of your project
exported with all defaults, ready to play.

### The Other Way 

If you want to customize how the runtime plays your project, you have the source and here is the way:

0. Get a copy of this runtime

    > The runtime is bundled into the source and releases of Arrow,
    > but we only need files under the path `<Arrow>/runtimes/html-js/` for the purpose.

1. Make your project ready:

    > This runtime needs to have an Arrow project (object/dictionary)
    > as a global constant called `PROJECT`, and following is the quickest way to make it:

    + Export your project as `JSON` via `Inspector (Panel) > Project (Tab) > Export (Menu) > ...`.
    + Edit the `.json` file using a text editor:
        - add `const PROJECT = ` before everything else
        - and a semicolon `;` after all the text.
    + Rename this altered `.json` file to `project.js`.
    + Put this `project.js` file into your copy of the runtime (adjacent to the `index.html` file.)
    
    > Unlike the [quick standard way](#quick-export), exporting `.json`
    > won't clean up the extra node notes and metadata.
    > You might want to take care of them yourself,
    > if the project is going to be distributed or the data includes business secrets!

2. You might want to replace tags like `{{project_title}}` and `{{project_last_save}}` in the `./index.html` file.
3. Customize the `css` and `js` files as you wish.
4. You're Done. Open the `index.html` file to play your project.


## Building Customized Runtime Template

Arrow uses `html-js.arrow-runtime` template file
to [Quick Export](#quick-export) projects as playable HTML documents.
This template file is compressed and is not that suitable for customization.
In case you want to use a customized version of the runtime as the template,
you'll find it much more convenient to modify the main source files (*.js, *.html, etc.),
then rebuild the template using [Gulp](https://gulpjs.com/) and provided `gulpfile.js`.


### I18N

To add a new supported locale/language or edit default messages,
check out `_TRANSLATION_TABLE` in `./modules/shared-i18n.js` file.

To change the runtime's locale, change `_LOCALE` constant
in `./arrow.js` file to any supported locale.


## Removing the *Back* Button

If you don't intend to let players go backwards in the play,
find and remove the line

```html
<button id="play-back">Back</button>
```

from `index.html` or exported `.html` file of your project.

> Disclaimer:  
> It won't totally eliminate the ability of going backwards,
> and any curious user may find how to, if they put their minds on it.
> Therefor we recommend leaving it as is.


## CSS Styling Helpers

To style node types, you can edit `arrow.css` file, where you can find corresponding placeholder blocks.

You can also take advantage of style helper *data-attributes*, which will be set automatically by the runtime.

The most general of these helpers are set for every appended `.node` HTML block:

```css
.node[data-name][data-type][data-uid][data-played='true|false']
```

Other style helper data-attributes are:

+ current value of every variables set on the `#console` element:
    
    ```html
    <section id="console" data-[variable-name]="[current-value]" ...
    ```

+ space separated list of all appended nodes on the `#content` element:

    ```html
    <article id="content" data-open-nodes="[node-names space separated]" ...
    ```

> Node and variable names are lowercased and escaped by replacing whitespaces with dashes (`-`)

+ Node-type specific helpers, similar to the following for `dialog` nodes:

    ```css
    .character-profile[data-name='character-name']
    ```


## Hybrid Styling Options

Arrow and this runtime support `BBCode` for styling `content` nodes as well.
This is specially useful when you want to use playable exports directly from Arrow.
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

This method is specially useful when you don't intend to modify or rebuild the runtime template.

> Hybrid styling options are supported by Arrow's official runtime,
> but may or may not behave the exact same way in other runtimes or in the console.


Feel free to experiment with this runtime,  
and make it work for you.

