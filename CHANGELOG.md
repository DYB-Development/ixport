# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `Ixport.register_export` registers a fixed export by key, title and exporter class, and a host whose registered exporter class does not exist fails to boot.
- `Ixport::Exporter` lists its columns with labels, a column can come from a related record with `through:`, and `records` names the records to export.
- An exports page lists each registered export, and downloading a fixed export gives a CSV of the exporter's columns.
- `chosen: true` registers an export whose columns a person picks, saving the picks in order as a named template that every member of the account can download, edit and delete.
- A template whose column the exporter no longer lists still downloads, without that column.
- An update generator, `ixport:update`, copies the migrations added since an app installed ixport.

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
