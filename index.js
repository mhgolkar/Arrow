document.addEventListener("DOMContentLoaded", function() {

    root = document.getRootNode().documentElement;
    
    const THEMES = ["Auto", "Dark", "Light"]
    const ICONS = ["⊙", "☾", "☀"]
    const DEFAULT_THEME = 0;

    function theme_switcher(ev) {
        ev.preventDefault();
        var current = THEMES.indexOf(root.getAttribute("data-theme"));
        var next = (current + 1) % THEMES.length;
        root.setAttribute("data-theme", THEMES[next]);
        ev.target.innerText = ICONS[next] + " " + THEMES[next];
        localStorage._arrow_theme = next
    }

    var initial_theme = localStorage.hasOwnProperty("_arrow_theme") ? (parseInt(localStorage._arrow_theme) || 0) % THEMES.length : DEFAULT_THEME;
    document.getElementById("theme-switcher").addEventListener("click", theme_switcher);
    document.getElementById("theme-switcher").innerText = ICONS[initial_theme] + " " + THEMES[initial_theme];
    root.setAttribute("data-theme", THEMES[initial_theme]);

})
