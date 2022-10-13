# Arrow: Changelog


## v2.0.0

This major release introduces many changes in Arrow,
including few structural updates that may affect your projects.

> **CAUTION!**  
> Although no major trouble is expected,
> create a backup of your old projects (created with v1.x)
> before opening them with the new v2.x generation.

### Notable Changes

Following is a list of updates you may find impacting your workflow:

+ New distributed resource identifier system
    > Resources (nodes, scenes, etc.) are now getting distributed UIDs.
    > They ease workflows where multiple authors work on the same project simultaneously,
    > or when a project is divided to different chapters/documents and no UID conflict is desired.
    >> Older documents will be modified automatically, by moving `next_resource_seed` to `authors` metadata.
    >> Although no conflict with existing identifiers is expected, it *will affect* the UIDs and names you'll get later.
+ Content node's `brief` is updated to display a substring of the content instead of an independent text
    > Any content node being inspected will be automatically updated
    > by using the current brief's length as the new `brief`'s integer value,
    > and then moving the old textual `brief` to top of the main content.
+ Arrow is now capable of building the HTML-JS runtime template automatically from the bundled source
    > This change comes with deprecation of the `gulp.js` builder and removing all the related dependencies.
    > Some changes in directory structure and placeholder tags are also introduced.
    > The template generated this way is not enhanced or minified, and is considered a debug tool,
    > therefore no beautification or compression support is planned.
    >> For more information, check out readme file of the official HTML-JS runtime.
+ Representation of color values is changed from `ARGB` to more common `RGBA`
    > This *will affect your projects* in the most visible way, by changing color of markers, frames and possibly characters.
    >> One quick fix is to use RegEx search and replace for `("color":\W")([\d\w]{2})([\d\w]{6})(")` with `$1$3$2$4` on saved documents.
+ Representation of `last_save` time  of projects is changed from dictionary to date-time (ISO 8601) string.
    > This shall not affect your projects, unless your (custom) runtime depends on `last_save` property being a dictionary/map.
    > The value will be automatically updated on first next save.
+ Projects list serialization is changed from Godot's binary (variant) to `JSON`
    > Arrow reads the old project listing format with no problem;
    > but they will be updated on first next save.
    > This change allows manual hacks in path listing.
+ Project (document) file extension is changed from `.arrow-project` to `.arrow`
    > This does not affect the projects listing process.
    > You just need to rename existing files and they work fine.
+ Console and the official HTML-JS runtime have undergone many revisions
    > These changes are mostly quality-of-life updates such as better display, debug and manual control,
    > as well as standardization of auto-play/skip, macro scoping, and tracking of nodes and variable states.
    > In general, they have no effect on normal projects, but production code directly depending on such behaviors.
+ Many node types are revised, and in some cases, their inner structure is changed
    > All these changes are meant to be backward compatible. Your old projects shall work with least problem.
    > But if you use a custom runtime, make sure to check out the updates. Following change(s) are the most notable:
    + Frequently used nodes with commonly empty fields (i.e. `Content` and `Dialog` types,) are optimized for file size
    > If a parameter is set to its known default value, it might be left from save files and exports to optimize for size and load.
    > This behavior is node type specific, depends on `SAVE_UNOPTIMIZED` constant, and is applied to nodes being inspected.
    > We expect it not to interfere with how your projects behave in console and the official runtime.
+ Arrow now uses its own custom path for user directory
    + `user://` will point to `<OS-user-data-directory>/arrow`
    > If your files are not listed anymore, you have been using the old default path for your workspace.
    > You need to move your documents from that path (`./godot`) to the new default `./arrow` in the same parent directory.
    >> Any path you wish (including the old default) can as well be set for work-directory,
    >> by changing the respective configuration form *Preferences* panel.

### New Features

This version (`v2`) comes with many quality-of-life improvements, and new features as well.
Most notable ones are:

+ Customizable User-Input nodes (e.g. number range, string pattern, etc.)
+ *Auto-play* control in the console (and the official runtime _as a global constant_)
+ Branch selection using `Shift + Selection` (and `Shift + Alt + Selection` for waterfall mode)
+ New `Sequencer` node
+ New **Character Tag System** with full console, inspector, and runtime support (including resource exposure)
+ New `Tag Edit` and `Tag Pass` nodes to dynamically interact with our new Character Tag System
+ New `Monolog` node to ease creation of conversations with much longer content
+ New string operations for `Variable-Update` nodes, including *find-and-replace*
+ List filtering and alphabetical sort for the resource inspectors
+ History System (undo/redo) with variable memory size
    > History system is experimental and disabled by default.
    > You can activate it by choosing any history size higher than `0` from the preferences panel.

For more information, browse the repository's wiki.


## v1.6.0

+ Binary saving is **deprecated**
    > Now both `.json` exports and `.arrow-project` save files have the same JSON format.
    > But the `.json` files are exported as purged (without editor's meta-data and nodes' developer notes,)
    > which makes them more suitable for distribution purposes.
    + All existent (binary) save files can still be opened and will be converted to textual format on save.
    > If you need binary saves anyway, it's still revivable for custom builds by `USE_DEPRECATED_BIN_SAVE` setting.
+ Progressive Web App
    > From this version forward we'll support `HTML5` (web-app) export as well.
    > You can try this new release online in your browser. Find the link in the repo.
    >> The official build is intended to be optimized for desktop (-mode/ and) screen size.
    + Full import and export support.


## v1.5.0

+ New built-in `Frame` node
+ New shortcuts with some existent ones being remapped, including:
    + `CTRL+E` for quick re-export
    + Node removal with `Del` instead of `CTRL+Del`
    + Moving selected nodes on focused grid using `CTRL+Arrow-Keys`
+ Tracking and restore window state from configuration file
+ Revising project regarding recent Godot updates
+ Jumping to target nodes or underlying macros by double-clicking on `Jump` or `Macro_Use` nodes.
+ More fixed issues and minor improvements


## v1.4.0

+ New Features:
    + Connection Assist

+ Enhancements:
    + UI Retouch
    + New Quick Preferences
        > ... for `connection assist` and `quick node insertion`

+ Updated License


## v1.3.0

+ New Features:
    + Quick Node Insertion
    + Generator (New Built-in Node Type)

+ Enhancements:
    + Better negative number handling
        + New `Absoulute` operator for `Variable_Update`
    + Query scope option
        > Now you can set if you want to search within the open scene or project-wide.

+ Other minor improvements


## v1.2.0

+ Enhanced Continuum Safety
    > Now Arrow takes care of continuum safety
    > for exposed/parsed variables in content-oriented nodes as well.
    >> Caution! We can't use curly brackets, dots or spaces in variable names anymore.


## v1.1.1

+ New Feature:
    + Official HTML-JS Runtime: Hybrid Styling

+ Enhancements:
    + New project filename validation and suggestion
    + Snapshot editing feature is back

+ Documentation (wiki) revision
+ Other minor fixes


## v1.1.0

+ New Features:

    + New *quick preference*: **Auto-Node-Update**
        + In-memory history of node modifications (fairly stable)
        + UI & keybindings `Ctrl + I|U|P`

    + Variable parsing in playable exports
        > Variable parsing existed in the Arrow's console but,
        > was missed from the official HTML-JS runtime

    + We can now remove snapshots (useful for huge projects)

+ Some other minor fixes


## v1.0.2

+ Better `New Blank Project` Handling
    > When the new (blank) project is *modified and unsaved*,
    > if user tries to create another blank project, open a saved project or close the app,
    > a heads-up will be shown.
    >> Importing a project won't affect the state of the open (new) project.

+ New Release Checker
    > A button linked to the archive of releases shows up,
    > indicating availability of a new release
    + Updating third-party license to comply with the [MBedTLS](https://tls.mbed.org/) Apache license

+ Other Minor Changes
    + Comment cleanup, in favor of more detailed wiki
    + Fix typos with word 'match' and its plurals
    + `playable|auto` indicator for dialog nodes


## v1.0.1

+ Clarification on Project File Path and Work Directory
    + *Fix:* The `Browse` button opens the current work directory
    + Absolute file path is shown for new projects (on prompt)
    + Heads-up when the selected filename is already used and will be renamed

+ Renaming `Inspector::Project::More` button to `Export`

+ Textual Save Preference
    + Now `Arrow` prefers `text/json` to format saved project data by default
    + Users can override this default unchecking `Prefer Textual Save` in the `Preferences` panel
    + The setting `USE_JSON_FOR_PROJECT_FILES` now accepts three values
        > null | false | true  
        > Default is `null` which activates and follows the `Prefer Textual Save` preference
        >> Note: Though it's much more portable and VCS friendly,
        >> JSON save and open processes may be a bit slower on huge projects,
        >> due to the project data refactoring on io (integer type conversion for UIDs.)


## v1.0.0

+ First Release

