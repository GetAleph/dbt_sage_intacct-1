[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Sage Intacct ([docs](https://fivetran.github.io/dbt_sage_intacct/#!/overview)) 

This package models Sage Intacct data from [Fivetran's connector](https://fivetran.com/docs/applications/sage_intacct). It uses data in the format described by [this ERD](https://fivetran.com/docs/applications/sage-intacct#schemainformation).

The main focus of this package is to provide users with insights into their Sage Intacct data that can be used for financial reporting and analysis. This is achieved by the following:
- Creating the general ledger, balance sheet, and profile & loss statement on a month by month grain
- Creating an enhanced AR and AP model 
## Compatibility

> Please be aware that the [dbt_sage_intacct](https://github.com/fivetran/dbt_sage_intacct) and [dbt_sage_intacct_source](https://github.com/fivetran/dbt_sage_intacct_source) packages were developed with single-currency company data. As such, the package models will not reflect accurate totals if your account has multi-currency enabled. If multi-currency functionality is desired, we welcome discussion to support this in a future version. 

## Models
This package contains transformation models, designed to work simultaneously with our [Sage Intacct source package](https://github.com/fivetran/dbt_sage_intacct_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.
| **model**                | **description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [sage_intacct__general_ledger](https://github.com/fivetran/dbt_sage_intacct/blob/master/models/sage_intacct__general_ledger.sql) | Table containing all transactions with offsetting debit and credit entries for each account, category, and classification. |
| [sage_intacct__general_ledger_by_period](https://github.com/fivetran/dbt_sage_intacct/blob/master/models/sage_intacct__general_ledger_by_period.sql) | Table containing the beginning balance, ending balance, and net change of the dollar amount for each month and for each account, category, and classification. This table can be used to generate different financial statements for your business based on your customer accounting period. Examples include the balance sheet and income statement models. | 
| [sage_intacct__balance_sheet](https://github.com/fivetran/dbt_sage_intacct/blob/master/models/sage_intacct__balance_sheet.sql)             | Total amounts by period per account, category, and classification for all balance sheet transactions. 
| [sage_intacct__profit_and_loss](https://github.com/fivetran/dbt_sage_intacct/blob/master/models/sage_intacct__profit_and_loss.sql)       | Total amounts by period per account, category, and classification for all profit & loss transactions. 
| [sage_intacct__ap_ar_enhanced](https://github.com/fivetran/dbt_sage_intacct/blob/master/models/sage_intacct__ap_ar_enhanced.sql) | All transactions for each bill or invoice with their associated accounting period and due dates. Includes additional detail regarding the customer, location, department, vendor, and account. Lastly, contains fields like the line number and total number of items in the overall bill or invoice.

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in your `packages.yml`

```yaml
packages:
  - package: fivetran/sage_intacct
    version: [">=0.1.0", "<0.2.0"]
```

## Configuration
By default, this package looks for your Sage Intacct data in the `sage intacct` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). 
If this is not where your Sage Intacct data is, add the below configuration to your `dbt_project.yml` file.

```yml
# dbt_project.yml

...
config-version: 2

vars:
    sage_intacct_database: your_database_name
    sage_intacct_schema: your_schema_name
```
### Passthrough Columns
This package allows users to add additional columns to the `stg_sage_intacct__gl_account` table. 
Columns passed through must be present in the upstream source tables. See below for an example of how the passthrough columns should be configured within your `dbt_project.yml` file.

```yml
# dbt_project.yml

...
vars:
  sage_account_pass_through_columns: ['new_custom_field', 'custom_field_2']
```
### Custom Account Classification
Accounts roll up into different accounting classes based on their category. The categories are brought in from the `gl_account` table. We created a variable for each accounting class (`Asset`, `Liability`, `Equity`, `Revenue`, `Expense`) that can be modified to include different categories based on your business. You can modify the variables within your root `dbt_project.yml` file. The default values for the respective variables are as follows:

### Disabling and Enabling Models

When setting up your Sage Intacct (Sage) connection in Fivetran, it is possible that not every table this package expects will be synced. This can occur because you either don't use that functionality in Sage or have actively decided to not sync some tables. In order to disable the relevant functionality in the package, you will need to add the relevant variables.

By default, all variables are assumed to be `true`. You only need to add variables for the tables you would like to disable:

```yml
# dbt_project.yml

config-version: 2

vars:
    sage_intacct__using_invoices: false                 # default is true
```


```yml
# dbt_project.yml

...
vars:
  sage_intacct:
    sage_intacct_category_asset: ('Inventory','Fixed Assets','Other Current Assets','Cash and Cash Equivalents','Intercompany Receivable','Accounts Receivable','Deposits and Prepayments','Goodwill','Intangible Assets','Short-Term Investments','Inventory','Accumulated Depreciation','Other Assets','Unrealized Currency Gain/Loss','Patents','Investment in Subsidiary','Escrows and Reserves','Long Term Investments')
    sage_intacct_category_liability: ('Accounts Payable','Other Current Liabilities','Accrued Liabilities','Note Payable - Current','Deferred Taxes Liabilities - Long Term','Note Payable - Long Term','Other Liabilities','Deferred Revenue - Current')
    sage_intacct_category_equity: ('Partners Equity','Retained Earnings','Dividend Paid')
    sage_intacct_category_revenue: ('Revenue','Revenue - Sales','Dividend Income','Revenue - Other','Other Income','Revenue - Services','Revenue - Products')
    sage_intacct_category_expense: ('Advertising and Promotion Expense','Other Operating Expense','Cost of Sales Revenue', 'Professional Services Expense','Cost of Services Revenue','Payroll Expense','Payroll Taxes','Travel Expense','Cost of Goods Sold','Other Expenses','Compensation Expense','Federal Tax','Depreciation Expense')
```
### Changing the Build Schema
By default this package will build the Sage Intacct staging models within a schema titled (<target_schema> + `_stg_sage_intacct`) and the Sage Intacct final models with a schema titled (<target_schema> + `_sage_intacct`) in your target database. If this is not where you would like your modeled Sage Intacct data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml 

...
models:
  sage_intacct:
    +schema: my_new_schema_name # leave blank for just the target_schema
  sage_intacct_source:
    +schema: my_new_schema_name # leave blank for just the target_schema
```


## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing and running the package? If so, we highly encourage and welcome contributions to this package! 
Please create issues or open PRs against `main`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Database Support

This package has been tested on Spark, BigQuery, Snowflake, Redshift, Databricks, and Postgres.

### Databricks Dispatch Configuration
dbt `v0.20.0` introduced a new project-level dispatch configuration that enables an "override" setting for all dispatched macros. If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
# dbt_project.yml

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions or feedback, or need help? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or shoot us an email at solutions@fivetran.com.
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate dbt transformations with Fivetran [here](https://fivetran.com/docs/transformations/dbt).
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
