<!-- Arrow Logo -->
<h1 style="font-size: 3rem; line-height: 100%;">
    <span>Arrow</span>
    <img
        src="./icon.png"
        style="width: 1em; height: auto; display: inline-block; vertical-align: bottom;"
        alt="Arrow's logo"
    >
</h1>


<!-- # Arrow -->
***The Game Narrative Design Tool***

[Download](#download) | [Contribution](#contribution-to-arrow) | [Runtimes](#runtimes) | [Guides](#guides)

Arrow is the free, open-source and feature-rich tool for
*game narrative* design, *text-adventure* development,
and creation of *interactive nonlinear storytelling* documents.

![Arrow's Overall Look][arrow-screenshot]

Notable Features:

+ Free as in Freedom
+ 100% Visual Development
+ Extensible Node System
+ VCS-Friendly Save Files & JSON Export
+ One-Click Playable Export (HTML)
+ Support for Distributed Workflows
+ Continuum Safety

Arrow supports a rich palette of features, from scenes and macros, to variables and characters.
It also comes with built-in common node types, providing logic, interactive navigation, random data generation,
state management, and more.

> Check out [Guides](#guides) for detailed information.


## Download

Arrow prebuilt executables are available to download from the archive of [releases].

Following links are to the *latest* stable versions:

Linux (X11) [x86 (32-bit)][linux-x11-x86-latest] | [x86_64 (64-bit)][linux-x11-x86-64-latest]

Windows [32-bit][win-32-latest] | [64-bit][win-64-latest]

> MacOS builds are not available at this time.  
> Mac users can easily [build Arrow from source][wiki-build-from-source].


## Web App

[Arrow Progressive Web App][web-app] is also available.

This version provides full features as the latest downloadable releases.  
**It stores project data and configurations in your browser.**  
Convenience import/export options are available to ease working with file-system of devices as well.

> The experience is optimized for desktop (mode/) screens.

> PWA version requires your browser to have `WebGl` and `Canvas` element support,
> available `Web-Storage`, and `Java-Script` enabled
> (which any *modern browser* does by default).


## Runtime Projects

+ [Official HTML-JS Runtime][runtime-html-js]
    > Bundled with Arrow, this runtime is used in playable exports.


## Guides

Docs for Arrow are available in the [repository's Wiki][wiki-home],
including a [Quick Start Guide][wiki-quick-start-guide] as well as,
detailed instructions, documentation of the built-in nodes, and more.


## Contribution to Arrow

Contributions are welcome and appreciated.  
Please browse [Contribution][wiki-contribution] wiki page,
to find how you can help Arrow most.  

Thanks in advance.


## Licenses

Copyright (c) 2021-2022 Mor. H. Golkar and contributors

Unless otherwise specified, Arrow and files in this repository are
available under `MIT` license.
See [license][license-file] & [copyright][copyright-file] files for more information.


Have a Good Time



<!-- download -->
[releases]: https://github.com/mhgolkar/Arrow/releases
[linux-x11-x86-64-latest]: https://github.com/mhgolkar/Arrow/releases/download/v2.0.0/Arrow-v2.0.0-linux-x86_64.tar.gz
[linux-x11-x86-latest]: https://github.com/mhgolkar/Arrow/releases/download/v2.0.0/Arrow-v2.0.0-linux-x86.tar.gz
[win-32-latest]: https://github.com/mhgolkar/Arrow/releases/download/v2.0.0/Arrow-v2.0.0-win.32.zip
[win-64-latest]: https://github.com/mhgolkar/Arrow/releases/download/v2.0.0/Arrow-v2.0.0-win.64.zip
<!-- pwa -->
[web-app]: https://mhgolkar.github.io/Arrow/
<!-- wiki -->
[wiki-home]: https://github.com/mhgolkar/Arrow/wiki/
[wiki-build-from-source]: https://github.com/mhgolkar/Arrow/wiki/build-from-source
[wiki-quick-start-guide]: https://github.com/mhgolkar/Arrow/wiki/quick-start-guide
[wiki-contribution]: https://github.com/mhgolkar/Arrow/wiki/contribution
<!-- relative -->
[runtime-html-js]: ./runtimes/html-js/
[license-file]: ./license
[copyright-file]: ./copyright
<!-- resources -->
<!-- [arrow-logo]: ./icon.png -->
[arrow-screenshot]: https://mhgolkar.github.io/Arrow/images/screenshot_overall.png
