# Nairobi customizations

This repository is a fork of [CONSUL DEMOCRACY](https://github.com/consuldemocracy/consuldemocracy) adapted for the participatory budgets of Nairobi City County. This document gives a high-level overview of what has been customized and explains how to use the Nairobi rake tasks.

## Customized parts

Almost all the custom code lives in the `custom` folders (`app/*/custom/`, `config/locales/custom/`, `config/routes/custom.rb`, `spec/**/custom/`), following the [CONSUL DEMOCRACY customization guide](https://docs.consuldemocracy.org/devs_docs/customization). Original CONSUL DEMOCRACY tests that no longer apply are tagged with `:consul` and excluded from the test run.

### General

- **Branding:** Nairobi logo, colors and a full width banner image.
- **Currency:** Kenyan Shilling (`KSh`) is available as a budget currency.
- **Languages:** Kiswahili (`sw-KE`) is enabled. The Nairobi texts are translated into English, Spanish and Kiswahili.

### Boroughs, subcounties and wards

Budgets are organized in three geographic levels:

| Nairobi | CONSUL DEMOCRACY |
| --- | --- |
| Borough | `Budget::Set` (new model, optional) |
| Subcounty | `Budget::Group` |
| Ward | `Budget::Heading` |

- **Admin:**
  - Groups and headings are called subcounties and wards everywhere.
  - The budget page shows boroughs, subcounties and wards as a single tree table, folded by default.
  - Ward budgets have no length limit, since amounts in KSh can be very large.
- **Budgets wizard:** the steps are budget, zones and phases. In the zones step, boroughs, subcounties and wards can be created in one table or imported from a CSV file.
- **Public budget page:**
  - Each borough is a button that reveals its subcounties and wards.
  - Wards and subcounties link to their investments in every phase except informing. CONSUL DEMOCRACY also disables these links when the budget is finished.
  - The list of investments is not shown. A "See all investments" button is shown in every phase except informing.
- **Investments list:**
  - The budget name is shown above the title.
  - Investments can be filtered by subcounty, and the advanced search has subcounty and ward selects.
  - In finished budgets, investments can also be sorted by price, unless the budget hides money. CONSUL DEMOCRACY only sorts them randomly in that phase.

### Projects

Investments represent Nairobi City County projects. They have these extra fields, editable in the admin investment form and shown on the investment page:

- Sector and sub-sector
- Target and performance indicator
- Implementing agency and contractor
- Actual cost
- Start and end dates
- Source of funds

The investment page also shows the current milestone status and the implementation percentage.

Sectors and their sub-sectors are a catalog managed in **Admin > Sectors**. Projects can be imported from a CSV file in the admin page of each budget (**Import projects**) or with a rake task.

## Rake tasks

All the tasks are in `lib/tasks/nairobi.rake`. Run them from the application root.

- **Arguments:** quote the task name so the shell doesn't interpret the brackets. Avoid commas in file paths, since rake uses them to separate arguments.
- **CSV files:** values can be separated by commas or tabs, so they can be pasted from a spreadsheet. Files can be in UTF-8 or Windows-1252, and headers are case insensitive.
- **Re-importing:** existing records are matched by name, ignoring case. Importing the same file again updates them instead of creating duplicates.
- **Errors:** errors are reported with their line number, and the rest of the file is still imported.

Some tasks can also be done from the admin panel:

| Task | From the admin panel |
| --- | --- |
| `nairobi:import_sectors` | Partly: sectors can only be created one by one |
| `nairobi:import_projects` | Yes, by uploading the same CSV file |
| `nairobi:milestone_statuses` | Yes: runs automatically when projects are imported from the admin panel |
| `nairobi:destroy_investments` | No |

### `nairobi:import_sectors`

Creates the sectors and sub-sectors from a CSV file.

```bash
bin/rake "nairobi:import_sectors[path/to/sectors.csv]"
```

| Column | Required | Description |
| --- | --- | --- |
| `sector` | Yes | Name of the sector |
| `sub_sector` | No | Name of a sub-sector of that sector |

Use one row per sub-sector. A row without `sub_sector` only creates the sector:

```
sector	sub_sector
Health	Clinics
Health	Hospitals
Water
```

At the end, the task prints the number of sectors and sub-sectors created, the totals and the errors.

Import the sectors **before** the projects: a project whose sector doesn't exist is imported with a blank sector.

**From the admin panel:** there is no CSV import for sectors. Go to **Admin > Sectors** (`/admin/sectors`):

- Click **Create sector** to create a sector.
- Click **Add sub-sector** in the row of a sector to create one of its sub-sectors.

### `nairobi:import_projects`

Imports projects from a CSV file as **winning investments** of a budget, so they appear as funded projects with their status and progress.

```bash
bin/rake "nairobi:import_projects[BUDGET_ID_OR_SLUG,path/to/projects.csv]"
```

The projects are authored by the `admin@consul.dev` user, who must exist.

**From the admin panel:**

1. Go to **Admin > Participatory budgets** and open the budget.
2. Click **Import projects**. The same button is also in the budget's list of investments.
3. Optionally, click **Download a template** to get a CSV file with the expected columns and an example row.
4. Click **Import projects** and choose the CSV file. The import starts as soon as the file is chosen.
5. Review the import results: the number of projects created and updated, the warnings, and the rows that weren't imported.

The import works the same way as the rake task, except that the projects are authored by the admin who uploads the file.

| Column | Required | Description |
| --- | --- | --- |
| `project_name` | Yes | Title of the investment |
| `ward` | Yes | Ward of the project; it must exist in the budget |
| `description` | Yes | Description |
| `sub_county` | No | Subcounty of the ward; disambiguates wards with the same name |
| `sector`, `sub_sector` | No | Must exist in the sectors catalog |
| `location` | No | Location |
| `performance_indicator`, `target` | No | Performance indicator and target |
| `implementing_agency`, `contractor` | No | Implementing agency and contractor |
| `project_cost_ksh`, `actual_cost_ksh` | No | Price and actual cost in KSh |
| `start_date`, `end_date` | No | `YYYY-MM` or `YYYY-MM-DD` |
| `implementation_pct` | No | Implementation percentage, from 0 to 100 |
| `status` | No | One of the milestone statuses below |
| `funds` | No | Source of funds |

How the import behaves:

- **Existing projects:** projects are matched by name and ward, so importing a file again updates them.
- **Rows that are skipped:** a row whose ward doesn't exist, or matches several wards, is not imported and is reported as an error.
- **Values that don't match:** sectors, statuses, amounts or dates that don't match are left blank and reported as warnings.
- **Status:** a new milestone is added only when the status changes.
- **Ward budgets:** each ward that receives projects gets its budget set to the sum of its projects' prices.

### `nairobi:milestone_statuses`

Creates the predefined project statuses, or restores them if they were deleted, and updates their descriptions. `nairobi:import_projects` runs this automatically.

```bash
bin/rake nairobi:milestone_statuses
```

The statuses are: Awarded, Not started, Ongoing, Delayed, Stalled, Substantially Complete, Completed, Operational and Terminated.

**From the admin panel:** importing projects from the admin panel also creates the statuses. They can be reviewed and edited one by one in `/admin/milestone_statuses`, which is linked as **Manage statuses** from the milestone form of any investment. Note that every project import resets the descriptions of the predefined statuses.

### `nairobi:destroy_investments`

Permanently deletes the investments of a budget, so its projects can be imported again from scratch. Hidden investments are deleted too, along with their comments, votes, ballot lines, milestones, progress bars, images and documents.

```bash
bin/rake "nairobi:destroy_investments[BUDGET_ID_OR_SLUG]"
```

**Without a budget, it deletes the investments of ALL budgets.**

The task shows how many investments will be deleted and asks for confirmation. To skip the question, set `CONFIRM=yes`.

**This cannot be undone.** Back up the database before running it in production.

**From the admin panel:** not available. CONSUL DEMOCRACY's admin panel can't delete investments; moderators can only hide them, which keeps them in the database.

### Running the tasks in production

The tasks read the CSV file from the server's disk:

1. Deploy a version that includes the task.
2. Copy the file to the shared `tmp` folder, which is kept between deployments:

   ```bash
   scp sectors.csv USER@SERVER:DEPLOY_TO/shared/tmp/
   ```

3. Run the task from the current release:

   ```bash
   cd DEPLOY_TO/current
   RAILS_ENV=production bin/rake "nairobi:import_sectors[tmp/sectors.csv]"
   ```

`USER`, `SERVER` and `DEPLOY_TO` are defined in `config/deploy-secrets.yml`. Try the task in staging first, and delete the CSV file from the server afterwards.
