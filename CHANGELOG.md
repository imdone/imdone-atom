## 1.2.7
* imdone-core update for arduino ino files

## 1.2.6
* imdone-core update for scala and sbt

## 1.2.5
* Fix todo.txt dates display

## 1.2.4
* Make PluginViewInterface an internal class that extends Emitter

## 1.2.3
* Don't add hash to code style tasks
* Add salesforce extensions

## 1.2.2
* Fix styles for light themes

## 1.2.1
* Update sortable package

## 1.2.0
* Official plugin release

## 1.1.60
* Just a readme update

## 1.1.59
* Update imdone-core.  Fix task text modification.

## 1.1.57
* Remove plugin view on plugin.removed

## 1.1.56
* Add emitter for plugins and emit board.update

## 1.1.55
* Only emit config.update on watched repo
* On renameList return if old and new name are the same

## 1.1.53
* Update readme and add padding to buttons

## 1.1.52
* Fix duplicate list issue and issues 38 and 39

## 1.1.51
* Fix height issue for rename and new task

## 1.1.50
* Prepare for plugin architecture
* Add close icon for bottom-pane
* Set size smaller for rename and new lists

## 1.1.49
* Add bottom panel resize

## 1.1.48
* Don't refresh repo on list modification (performance++)

## 1.1.47
* Update menu on tasks.move event (Bug introduced last release)

## 1.1.46
* Improved performance on move task

## 1.1.45
* Add React jsx
* Fix filtering issues

## 1.1.44
* Add HTML

## 1.1.43
* Fix hotkey task-board open for projects with prefix that is the same as a project name
* Visual fix for scrolling past menu

## 1.1.41
* Fix metadata links when same key is used more than once

## 1.1.40
* Add groovy language
* Handle errors on loading config.json

## 1.1.39
* Keep filter on board refresh
* Remove order number from UI

## 1.1.38
* Close rename/new list dialog when list is modified

## 1.1.35
* Add typescript support

## 1.1.34
* Add julia language support
* Fix task sorting issues

## 1.1.33
* Fix windows line endings issue
* Fix Windows .imdoneignore handling

## 1.1.32
* Implement serialization!

## 1.1.30
* Update imdone-core to allow **languages** in `.imdone/config.json`.  Previously required a change to [imdone-core/lib/languages](https://github.com/imdone/imdone-core/blob/master/lib/languages.js)

## 1.1.29
* Update imdone-core to include Jade and Stylus comments

## 1.1.28
* Fix vcsRepo equals null bug

## 1.1.27
* Sanitize task markdown

## 1.1.26
* Fix padding for task

## 1.1.25
* Added excludeVcsIgnoredPaths config setting
* Show menu when filter link is clicked

## 1.1.23
* Add prompt and config setting for max files

## 1.1.22
* Fix errors on destroy

## 1.1.21
* Add Earl-Grey support

## 1.1.18
* Update marked and show better error message on getFullPath

## 1.1.17
* Add .imdoneignore support

## 1.1.16
* Show more debug data on path.join error for getFullPath

## 1.1.15
* Show error text if list name does not conform to `^[\w\-]+$`

## 1.1.14
* If no files are open don't attempt to gather tasks

## 1.1.13
* Update version of imdone-core to allow haxe/.hx file extension

## 1.1.12
* Fix Path for windows users

## 1.1.10
* [Fix config path checking for windows git-iss:5](#DONE:100)
* Update version of imdone-core to allow pks and pkb files

## 1.1.9
* Fix funky white border on task drag

## 1.1.8
* Fix meta alignment

## 1.1.7
* enter and esc in rename and new list for save and cancel

## 1.1.5
* Add new list support

## 1.1.4
* Remove clunky transition on list rename

## 1.1.3
* Add list rename supprt

## 1.1.2
* Add filter link support #filter/*filter*
* Color ghost background on sort

## 1.1.1
* Add tab checklist icon
* Add file tree context menu item for projects

## 1.1.0
* Add task drag and drop sorting and moving between lists
* Add list delete

## 1.0.0
* Add syntax and configuration help
* Add filter
* Add meta table and external links

## 0.2.1
* Switch to html5sortable

## 0.2.0 - First Release
* Allow show and hide lists
* Allow Reorder lists

----

- #DOING:0 Remember to update changelog before @piascikj +publishing +package
