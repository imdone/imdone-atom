Roadmap
----
- #BACKLOG: Add configuration editor view for .imdone/config.json id:138 gh:350 ic:gh
  - Use copy/modified version of [settings-view/settings-panel.coffee at master atom/settings-view](https://github.com/atom/settings-view/blob/master/lib/settings-panel.coffee)
- #DOING: As a user I would like to add content to my TODO descriptions from markdown templates stored in my project id:104 gh:322 ic:gh
  - [ ] Append templates to tasks with `t:<type>` metadata in them. (e.g. `t:story`)
    - [ ] if TODO appears in a single line comment, append template with single line comment prefix and the same indentation as the TODO comment
    - [ ] If TODO appears in a multiline comment, just append template at the same indentation as the TODO comment
    - [ ] Remove `t:story` after the template has been appended to the description
  - [ ] templates.md will contain templates in the format...
  ```
  # <type>
  Any markdown for your template
  ```
- #DOING: Add analytics for user actions id:107 gh:328 ic:gh
  - [ ] Open board
  - [ ] Create list
- #DOING: As a user I would like to clear the filter with the escape key so that I can be more productive with filtering. +story id:108 ic:gh gh:329
- #DOING: As a user I would like to save groups of visible lists so that I can have multiple process flows in a single project. id:139 gh:351 ic:gh
- #DOING: As a user I would like to add the github issue content to my TODO comment so that I can stay in the code while tracking my work. id:141 gh:354 ic:gh
Acceptance Criteria
----
- [ ] When a user creates a todo with no content and identifies a github issue with gh:123 then issue 123 should become the content of the TODO.
