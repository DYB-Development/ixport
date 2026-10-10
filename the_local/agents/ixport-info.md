---
name: ixport-info
description: Use to learn what ixport offers — CSV import and export through a mounted Rails engine, the mapped imports and the fixed and chosen exports a host app registers, the importer and exporter classes behind them, uploading a file, matching its columns, previewing which rows will add, update or be refused, running the import inside the request or in the background through wallflower or the app's own runner, its result page, what a person sees when a file is refused or a run fails, the list of a person's past imports, downloading an export as a CSV file, saving named templates of picked columns for a chosen export, limiting each import or export to the people a rule allows, and the vocabulary the install and develop locals assume.
tools: Read
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports and the exports the host app registers, each import backed by an importer class and each export by an exporter class the host writes, where an export is either fixed or chosen, and a chosen export lets the account save named templates of picked columns
---

This local explains what ixport is and routes you to the local that does the work. It makes no changes and gives no steps.

## What ixport is

ixport is a Rails engine for loading a host app's records from CSV files and downloading them back out as CSV files. The host app mounts it at a path of its choosing. A signed-in person who visits that path sees the list of imports the host has set up, and a signed-in person who visits its exports page sees the list of exports, each shown by its title.

A person picks an import, uploads a CSV file, matches each column of the file to one of the columns the import reads or skips it, and then sees a preview. The preview counts how many rows will add a record, how many will update one, and how many will be refused, and lists the rows that will update and the rows that will be refused with the reason for each. Viewing the preview saves nothing in the host app, and a Back link returns to the mapping so the person can change it.

From the preview the person runs the import. The run saves every added and updated record in the host app, records each refused row with its reason, and sends the person to the import's result page, which shows how many rows were added and updated and lists each refused row. An import that has finished is never run again. Opening the preview of a running or finished import sends the person to its result page instead, so no Run button is offered for it, and opening the result page of an import that has not started running sends the person to its preview.

A run that stops on an error is marked Failed. Every row saved before the error stays saved, and the result page is headed Import failed, shows the error's message, and shows how many rows were added and updated before it stopped along with each refused row. ixport also reports the error to the host app's error reporting. A failed import is never run again.

Where the run happens depends on the host's background runner. With none, the run happens inside the request, as above. With one, every import runs through it whatever its size: running the import marks it Running and hands it to the runner, and its result page says the import is running until the run finishes. An import is handed to the runner only once: asking to run it again while it is running, or after it has finished, sends the person to its result page.

- **Wallflower** — the host can choose wallflower as the runner. Running an import then starts a wallflower task and takes the person to the task's page, which shows the run's progress and each refused row with its reason, and links to the import's result page once the run finishes. When the run fails, the task is marked failed with the import's error message and still links to the import's result page.
- **The app's own runner** — the host can instead name a class of its own. ixport hands each import to that class, and the class runs it later by calling ixport back, after which the result page shows the counts and refused rows as usual. Running the import takes the person to the import's result page.

ixport refuses a file on the upload page, before any import record is kept, when it is not UTF-8 text, when a line's quotes stop it being read, naming that line, or when it has no header row. With no background runner, it also refuses a file with more rows than the host's row limit there. Each refusal says what is wrong with the file.

Below the list of imports, the same page lists the person's own past imports in the current account, newest first. Each shows the import's title, the uploaded file's name, its status, the date it was uploaded, and, once it has finished, how many rows were added, updated and refused. A failed import shows its status as Failed and no counts. Each title opens the import at the step it has reached: the mapping when no mapping is saved, the preview when it has a mapping and has not started running, and the result page once it is running, finished or failed. Imports uploaded by other people, or by the same person in another account, are not listed, and neither are the person's imports of a kind their access rule now refuses.

An export is either fixed or chosen. A fixed export's title on the exports page links to a CSV download holding every column the exporter declares. A chosen export's title is not a link. Under it the page lists the templates the account has saved for that export, each linking to a download and to its edit page, with a button to make a new template.

A template is a name and an ordered pick of the exporter's columns. A person makes one on its own page, entering a name and choosing a column, or None, for each slot. Its download holds only the picked columns, in the order picked, and the file is named after the template. On the edit page a person can change the name and the picked columns, or delete the template. A template belongs to the account, so everyone working in that account sees, downloads, edits and deletes the same templates.

Every export file's first row holds the column labels, and each later row holds one of the host's records. The host decides which records an export holds, so an export can be limited to the person's current account. The file is built inside the request and nothing about it is stored.

By default every signed-in person can use every import and export. The host can give any import or export an access rule, which is handed the signed-in person and the current account and allows or refuses them, and which can ask the app's own permission checks, such as a Pundit policy. A person the rule refuses does not see that import or export listed, does not see their past imports of it, and is answered not found on every one of its pages and downloads, including its upload page, an existing import's mapping, preview, run and result pages, and a chosen export's template pages and downloads. The rule is checked again on every request, so a person whose permissions change is let in or kept out from their next page.

The engine owns the screens, the access check, and its own tables of import records, refused rows and export templates, with the uploaded file stored through Active Storage. The host owns what each import and export means: which columns it reads or writes, which column identifies an existing record, and which of the app's records a row is checked against, saved into, or read from. Reach for ixport when a Rails app needs people to load data from spreadsheets or take it out into one, rather than writing a one-off upload or download page per record type.

The engine renders its pages with Keystone UI inside a layout the host chooses, and it runs its access check through a method the host already has.

## Interface

ixport declares nothing for this local to document. Its surface is split between the other two locals:

- **ixport-install** owns hooking ixport into a host app: adding the gem, running its install generator, running its update generator to bring an existing install's tables up to date, mounting the engine, and the configuration that names the host's sign-in check, current person, current account, layout, row limit and background runner.
- **ixport-develop** owns building against ixport: registering a mapped import and the importer class behind it, registering a fixed or chosen export and the exporter class behind it, giving an import or export an access rule, writing the app's own background runner and running an import from it, the error a wallflower task raises when its import fails, the errors raised when a registration names a class that does not exist, and the engine's pages for imports, exports and export templates.

## How to use it

- The app does not have ixport yet, the app installed ixport before export templates or background runs existed and needs their tables, you are choosing whether imports run inside the request, through wallflower or through the app's own runner, or you are changing how ixport reaches the app's sign-in, people, accounts, layout or row limit: use **ixport-install**.
- ixport is already installed and you are adding or changing an import or an export, making an export chosen or fixed, changing how an import's rows are matched, checked or saved, changing which records or columns an export holds, limiting an import or export to some people, writing the app's own runner that runs imports in the background, linking to the engine's pages, or the app fails to boot naming a missing importer or exporter: use **ixport-develop**.

## Conventions

- **Mapped import** — one kind of import the host registers, made of a key, a title shown to people, and the name of its importer class.
- **Fixed export** — one kind of export the host registers, made of a key, a title shown to people, and the name of its exporter class, whose download always holds every declared column. An export is fixed unless the host registers it as chosen.
- **Chosen export** — an export registered the same way and marked as chosen, which has no download of its own and is downloaded only through the account's templates.
- **Export template** — a named, ordered pick of a chosen export's columns, saved by one person and shared by everyone in their account.
- **Picked columns** — the columns a template holds, in the order they were chosen. A slot left on None is dropped, a column picked twice is kept once, and a column the exporter no longer declares is left out of the download.
- **Key** — the short name an import or export is registered and looked up by, held as a symbol. A fixed export's file is named after its key.
- **Title** — the words a person sees for the import or export on the engine's pages.
- **Importer** — a class the host app writes that declares the columns the import reads, each with a key and a label, names the column that identifies an existing record, and supplies the set of the app's records the rows are checked against and saved into.
- **Exporter** — a class the host app writes that declares the columns the export writes, each with a key and a label, and supplies the set of the app's records the file holds.
- **Export column** — one column of an export's file, headed by its label and filled from the attribute its key names on each record.
- **Through** — an export column can be read from a record related to each row's record rather than from the record itself, and it is left blank when that related record is missing.
- **Match column** — the one declared import column whose value decides whether a row is an existing record or a new one.
- **Import record** — one upload by one person, stored by the engine with the key of its mapped import, the uploaded file, the mapping once it is saved, and the added and updated counts once it has run.
- **Headers** — the first row of the uploaded file, read as the names of its columns.
- **Mapping** — which of the importer's columns each header in the file fills, stored by the header's position in the row. A header left on "Skip" is not stored.
- **Row limit** — the most data rows an uploaded file may have, not counting the header row. It defaults to 1,000 and the host can change it. It applies only when the host has no background runner, and it does not apply to exports.
- **Background runner** — what runs an import outside the request: none, wallflower, or a class the host app writes. Having wallflower in the app does not choose it, the host has to.
- **Wallflower** — a separate gem that runs long tasks in the background and gives each task a page showing its progress. ixport registers its imports with it as a kind of task titled Import.
- **Row number** — a row's line in the file, counting the header as row 1, so the first data row is row 2.
- **Add** — a row whose match column value is found in no existing record, so it creates one.
- **Update** — a row whose match column value is found in an existing record, so it changes that record.
- **Refused** — a row whose record, new or changed, fails the host model's own validations. Its reason is that model's error messages.
- **Preview** — the page that shows the add, update and refused counts and lists the update and refused rows by row number. It builds each row's record in memory and saves none of them.
- **Run** — the step that saves the added and updated records one row at a time and stores each refused row's number and reason. A run that raises an error stops there and keeps the rows it already saved, and an import that has finished or failed is never run a second time.
- **Status** — an import record is Pending until it is run, Running while a background runner has it, and then Finished, or Failed when the run stopped on an error.
- **Running** — the state of an import record handed to a background runner and not yet finished. Its result page says it is running and shows no counts, its preview sends the person to that result page, and it is never handed to the runner a second time.
- **Finished** — the state of an import record once it has run to the end.
- **Failed** — the state of an import record whose run stopped on an error. It keeps the error's message and the added and updated counts reached before it stopped, and its result page shows them.
- **Refused file** — an upload ixport turns away on the upload page because it is not UTF-8, cannot be read past a line, has no header row, or has too many rows. Nothing is stored for it, unlike a refused row, which belongs to an import that ran.
- **Past imports** — the person's own import records in the current account, listed newest first under the imports on the engine's front page.
- **Step** — how far an import record has got: mapping when no mapping is saved, preview once one is, and result once it is running, finished or failed.
- **Result page** — the import's own page, showing the added and updated counts and each refused row as they were stored by the run, and the error's message when the run failed, so it shows the same thing each time it is opened.
- **Person** — whoever is signed in and running the import or downloading the export. ixport reaches them through a method the host names, so the host's user model needs no particular name.
- **Account** — the optional owner the person is working inside, such as a team or company, reached the same way. An app with no accounts runs without one. Both the importer and the exporter are given the person and the account.
- **Ownership** — an import record belongs to the person and account that uploaded it, and anyone else who opens it, including the same person from another account, is answered not found. An export template belongs to its account, and anyone opening it from another account is answered not found.
- **Access rule** — an optional check the host gives one import or export when registering it, handed the person and the account and answering whether they may use it. It is checked on top of ownership, so even the person who uploaded an import is answered not found for it once the rule refuses them. An import or export with no rule is open to every signed-in person.
- **Boot check** — when the app starts, ixport checks that every registered importer and exporter class exists and refuses to boot when one does not, so a misspelled class name fails at startup rather than when someone runs the import or downloads the export.
- Imports and exports are registered by the host app, never discovered: an importer or exporter class that is not registered does not appear on the page, asking for an export key that is not registered is answered not found, and asking to make a template for an export that is not chosen is answered not found.
