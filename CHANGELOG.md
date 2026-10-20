# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- An import can add its rows to a record the app chooses, named by its Global ID in the link to the upload page, and its importer reads that record as `target`.
- A registration's `allow:` rule that takes a third argument receives the import's chosen record and can refuse it, and a link, upload or import page naming a refused or missing record answers not found.
- Run `bin/rails generate ixport:update` for the migration that lets an import keep its chosen record.
- An import registered with `refuse_whole_file: true` saves no row from a file with any refused row, and its preview offers no Run import button and says to fix the file and upload it again.
- An import registered with `refuse_whole_file: true` undoes every row it saved when its run stops on an error.

## [0.3.3] - 2026-10-12

### Fixed
- An import whose background runner raises while it is handed over goes back to pending, and its preview says it did not start so it can be run again.
- An import still marked running an hour after its last change shows as stalled on its page.
- Run import requests that arrive together hand an import to the background runner once.
- A past import, or an export template's download and edit pages, return not found once its key is no longer registered, instead of a server error.
- An import that fails while wallflower runs it is reported to the host's error reporting once, carrying the error the import raised.
- An export template cannot be saved or edited without a name, and the form says a name is needed.

## [0.3.2] - 2026-10-11

### Changed
- The mapping page shows each column's saved choice when a person returns to it, and puts each column's name beside its choice from small screens up.
- The result page shows the import's status and how many rows its file had.

## [0.3.1] - 2026-10-10

### Fixed
- An importer that names no match fields adds every passing row as a new record instead of matching every row to one existing record.
- Rows that match the same record each work on their own copy, so an invalid row no longer fails the valid rows before it.

## [0.3.0] - 2026-10-10

### Added
- `config.base_controller` names the controller ixport's pages inherit, so they run that controller's checks.
- `match_on` takes several fields, matching a row only when it equals a record on all of them, with values compared as the record's own types.

## [0.2.0] - 2026-10-10

### Added
- `Ixport.register_export` registers a fixed export by key, title and exporter class, and a host whose registered exporter class does not exist fails to boot.
- `Ixport::Exporter` lists its columns with labels, a column can come from a related record with `through:`, and `records` names the records to export.
- An exports page lists each registered export, and downloading a fixed export gives a CSV of the exporter's columns.
- `chosen: true` registers an export whose columns a person picks, saving the picks in order as a named template that every member of the account can download, edit and delete.
- A template whose column the exporter no longer lists still downloads, without that column.
- An update generator, `ixport:update`, copies the migrations added since an app installed ixport.
- The engine's root lists the person's imports in the current account, newest first, each opening at the step it has reached.
- `config.background_runner` runs every import through wallflower or the app's own runner, with no inline row limit. A wallflower task shows the import's progress, changes and refusals and links to its result page. An app's own runner is handed each import with `enqueue` and runs it with `Ixport.run_import`. `ixport:update` copies the migration linking an import to its wallflower task.
- An upload is refused with a message when the file is not UTF-8 or its quoting is broken, naming the line where reading stopped, and a byte order mark is ignored.
- An import whose run raises is marked failed, keeps the rows saved before the error, shows the error and how far it got, and reports it through `Rails.error`. `ixport:update` copies the migration that stores the error.
- `allow:` on `Ixport.register_import` and `Ixport.register_export` takes a rule receiving the person and account, which can call the app's own Pundit policy. A person it refuses does not see that kind, and its pages and downloads answer not found.

## [0.1.0] - 2026-10-10

### Added
- An install generator that copies the migrations for the imports table and the table of rows an import refused.
- An engine served under the path the host mounts it at, behind the host's sign-in check and in the layout the host names, with the person and account methods set in `Ixport.configure`.
- `Ixport.register_import` registers a mapped import by key, title and importer class, and a host whose registered importer class does not exist fails to boot.
- `Ixport::Importer` lists fields with the labels a person sees, declares the one field rows match on with `match_on`, and names the records a row may match with `records`.
- A person picks a registered import, uploads a CSV, and maps each column to a field or skips it. A file with no header row, or more rows than `config.inline_row_limit`, is refused on the upload page.
- A preview shows how many rows will add, update or be refused, lists the updates and the refusals by row number, and saves nothing.
- Running an import inside the request updates matched records, adds the rest, and keeps each refused row with its reason, and its result page shows the counts and refusals.
- An import is found only for the person and account that uploaded it.
- ixport ships install, develop and info agents for Claude Code through the_local.
