Roadmap
----
- #BACKLOG: Add configuration editor view for .imdone/config.json +Roadmap id:106
  - Use copy/modified version of [settings-view/settings-panel.coffee at master · atom/settings-view](https://github.com/atom/settings-view/blob/master/lib/settings-panel.coffee)
- #DOING: As a user I would like to add content to descriptions from templates stored in my project id:104 gh:322 ic:gh
  - [ ] add multi-line comment lines with `t:<type>` in them. (e.g. `t:story`)
    - [ ] if it's a single line comment add template with single line comment prefix with the same indentation as the TODO comment
    - [ ] If it's a multiline comment, just add template at the same indentation as the TODO comment
  - [ ] templates.md will contain templates in the format...
  ```
  # <type>
  Any markdown for your template
  ```
  - [ ] Remove `t:story` after the template has been appended to the description
- #DOING: Add analytics for user actions
  - [ ] Open board
  - [ ] Create list
- #DOING: As a user I would like to clear the filter with the escape key so that I can be more productive with filtering. +story
