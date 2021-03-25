# Arrow: Changelog


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

