---
name: keystone_ui-info
description: Use to learn what keystone_ui offers — its UI components for pages, forms, tables, navigation and dashboards, its look, colour and theme model, and the vocabulary the install and develop locals assume.
tools: Read
scope: UI — pages, forms, tables, navigation, dashboards
---

This local explains keystone_ui and says which local does the work. It changes
nothing and gives no steps.

## What keystone_ui is

keystone_ui is a Rails engine gem that supplies a host app's UI as view helpers
built on ViewComponent. Screens are built from named pieces — page shells,
sections, panels, grids, forms and fields, data tables, navigation, cards, stat
tiles, charts, funnels, goal buckets, pipelines, breakdowns and info buttons —
instead of hand-written ERB and Tailwind. Every class the UI renders lives in the
gem, so two pages built from the same helpers cannot disagree about spacing,
colour or dark-mode treatment, and a change to a component reaches every page
that uses it.

Reach for it whenever you build or change a screen in an app that has it
installed. It is mobile-first, because these apps are often shown in a native
web view: small screens get a mobile header and a bottom tab bar, and from the
`lg:` breakpoint up the app gets a full navigation bar or sidebar.

## Interface

This local declares no commands. The working surfaces belong to the other two:

- **Getting the gem into a host app** — the install generator, the
  configuration block, the theme and look attributes on the layout, the palette,
  registered looks, the navigation groups, and the suppliers for trails, themes,
  looks, the current tab and saved preferences → **`keystone_ui-install`**.
- **Building screens with it** — which helper renders what, the keywords each
  takes, and how they nest → **`keystone_ui-develop`**.

## How to use it

One decision: is keystone_ui set up in the app?

- No, or the setup is out of date → **`keystone_ui-install`**.
- Yes, and there is a screen to build or edit, or a question about which piece
  fits → **`keystone_ui-develop`**. Do not hand-write ERB or Tailwind for UI it
  covers.

## Conventions

- **Helpers, not classes.** Every piece of UI is a view helper prefixed `ui_`.
  Components sit under the `Keystone::Ui` namespace, but a host app does not
  name a component class. The one class a host does name is the table column
  value object, which is passed as an argument and renders nothing.
- **Containers take blocks, leaves take keywords.** Page shells, sections,
  panels, grids, forms and tables wrap a block. A button, badge, field, stat or
  bucket is set entirely by keyword arguments. The navigation bar takes named
  slots.
- **Options are symbols.** Appearance is chosen by name, such as `variant:`,
  `size:` or `padding:`, and each component accepts its own set. Most raise on a
  symbol they do not know, so a wrong guess fails at render time.
- **Numbers and text are different inputs.** Progress bars, funnels and buckets
  do arithmetic, so they take numbers, and a bucket raises on `"9,000"`. A
  breakdown, a calculation and a toned figure take already-formatted text, show
  it as written and add nothing up.
- **Going back.** A form or show page shell needs a way back: a back link, a
  trail of earlier pages shown as breadcrumbs, or a trail the app supplies for
  the request. A nav tab's own page passes an empty trail and shows no back
  link. A page with none of these raises `KeystoneUi::MissingBackLink`, and a
  trail link missing a label or an address raises `KeystoneUi::IncompleteTrail`.
- **Navigation.** The app declares navigation groups, each a label and its tabs,
  and each tab a key, label, address and permission check. Tabs the user may
  not see are left out, and a group left with no tabs is left out. A saved
  preference can place the navigation as a top bar or a left or right sidebar
  and set the order of groups and tabs. A supplier names the current tab, which
  is marked active with its group. A declaration with an empty group, a tab with
  no label or address, or two tabs sharing a key stops the app at boot with
  `KeystoneUi::NavigationCheck::Error`.
- **Saved table layouts.** A data table given a key reads the layout saved under
  it: which hideable columns to hide and their order. With a save address, a
  "Columns" menu lets the user change it. A locked first column stays in view
  while the table scrolls sideways and is never hidden or moved.
- **Action menus.** Each action is a label, an address and an HTTP method. A
  plain visit is a link, and any other method is a button, so an action that
  changes data is never a bare link. A delete asks for confirmation by default.
- **Semantic colour.** The themed hue is `accent-*` and the themed neutrals are
  `surface-*`, CSS custom properties whose defaults (blue and zinc) come from
  the keystone_ui-styles gem. Retheming changes those values, not the
  components.
- **Looks.** A look is one CSS file setting keystone_ui-styles' `--ks-`
  variables for radius, font, weight, border, spacing and colour, each colour
  with a `-dark` partner. Components render `ks-` classes that read them, and
  their own Tailwind constants hold only layout, size and behaviour. Looks can
  be registered by name, and the page's `html` tag carries `data-look` for the
  supplied look or the default, when that name is registered.
- **Themes.** Light, dark, system and custom. The mode comes from the user's
  cookie, then a mode another gem supplies, then light. System leaves the page
  to follow the operating system, and custom marks the page for a palette
  another gem defines, which the theme toggle does not offer.
- **Static Tailwind classes.** Class names are never interpolated, so Tailwind's
  scanner finds them. Sizes that depend on data, such as a progress bar's
  width, use an inline style. The host needs tailwindcss-rails v4+.
- **Interactivity is Stimulus.** Dropdowns, modals, tab switchers, the column
  picker, info buttons, charts, copy buttons and the theme toggle ship as
  Stimulus controllers, so a host writes no JavaScript. Components that post,
  such as the column picker and the pipeline, post to endpoints the host or
  another gem owns.
- Ruby >= 3.2, ViewComponent >= 2.0 and < 5, keystone_ui-styles >= 0.14.0.
