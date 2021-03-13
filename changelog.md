# Arrow: Changelog


## v1.0.1

+ Clarification for Project File Path and Work Directory
    + *Fix* The `Browse` button opens the current work directory
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
