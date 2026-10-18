var plasma = getApiVersion(1);

var layout = plasma.desktopById("org.kde.desktopcontainment");

// Main bottom panel - ORIZON style
var panel = new Panel;
panel.height = 44;
panel.location = "bottom";
panel.alignment = "center";
panel.hiding = "none";
panel.floating = 1;

// Application launcher (Kickoff)
var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["Configuration", "General"];
kickoff.writeConfig("icon", "/usr/share/pixmaps/orizon/orizon-logo-48.png");
kickoff.writeConfig("showButtonIcon", true);

panel.addWidget("org.kde.plasma.marginsseparator");

// Task manager
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["Configuration", "General"];
tasks.writeConfig("showOnlyCurrentDesktop", true);
tasks.writeConfig("groupingStrategy", 1);

panel.addWidget("org.kde.plasma.marginsseparator");

// System tray
panel.addWidget("org.kde.plasma.systemtray");

// Digital clock
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Configuration", "Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "shortDate");
clock.writeConfig("use24hFormat", 2);

// Show Desktop button
panel.addWidget("org.kde.plasma.showdesktop");
