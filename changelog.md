# Arrow: Changelog


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

