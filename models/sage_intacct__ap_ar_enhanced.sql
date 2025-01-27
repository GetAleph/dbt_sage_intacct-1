with ap_bill as (
    select * 
    from {{ ref('stg_sage_intacct__ap_bill') }} 
), 


ap_bill_item as (
    select * 
    from {{ ref('stg_sage_intacct__ap_bill_item') }} 
),

{% if var('sage_intacct__using_invoices', True) %}
    ar_invoice as (
        select * 
        from {{ ref('stg_sage_intacct__ar_invoice') }} 
    ),

    ar_invoice_item as (
        select * 
        from {{ ref('stg_sage_intacct__ar_invoice_item') }} 
    ),
{% endif %}

ap_bill_enhanced as (
    select
        ap_bill_item.bill_id,
        ap_bill_item.bill_item_id,
        cast(null as {{ dbt_utils.type_string() }}) as invoice_id,
        cast(null as {{ dbt_utils.type_string() }}) as invoice_item_id,
        ap_bill_item.account_no,
        ap_bill_item.account_title,
        ap_bill_item.amount,
        ap_bill_item.class_id,
        ap_bill_item.class_name,
        ap_bill_item.currency,
        ap_bill_item.customer_id,
        ap_bill_item.customer_name,
        ap_bill_item.department_id,
        ap_bill_item.department_name,
        ap_bill_item.entry_date_at,
        ap_bill_item.entry_description,
        ap_bill_item.item_id,
        ap_bill_item.item_name,
        ap_bill_item.line_no,
        ap_bill_item.line_item,
        ap_bill_item.location_id,
        ap_bill_item.location_name,
        ap_bill_item.offset_gl_account_no,
        ap_bill_item.offset_gl_account_title,
        ap_bill_item.total_item_paid,
        ap_bill_item.vendor_id,
        ap_bill_item.vendor_name,
        ap_bill_item.created_at,
        ap_bill_item.modified_at,
        ap_bill.due_in_days,
        ap_bill.total_due,
        ap_bill.total_entered,
        ap_bill.total_paid,
        ap_bill.record_id,
        count(*) over (partition by ap_bill_item.bill_id) as number_of_items
    from ap_bill_item
    
    left join ap_bill
        on ap_bill_item.bill_id = ap_bill.bill_id
), 


{% if var('sage_intacct__using_invoices', True) %}
    ar_invoice_enhanced as (
      select 
        cast(null as {{ dbt_utils.type_string() }}) as bill_id,
        cast(null as {{ dbt_utils.type_string() }}) as bill_item_id,
        ar_invoice_item.invoice_id,
        ar_invoice_item.invoice_item_id,
        ar_invoice_item.account_no,
        ar_invoice_item.account_title,
        ar_invoice_item.amount,
        ar_invoice_item.class_id,
        ar_invoice_item.class_name,
        ar_invoice_item.currency,
        ar_invoice_item.customer_id,
        ar_invoice_item.customer_name,
        ar_invoice_item.department_id,
        ar_invoice_item.department_name,
        ar_invoice_item.entry_date_at,
        ar_invoice_item.entry_description,
        ar_invoice_item.item_id,
        ar_invoice_item.item_name,
        ar_invoice_item.line_no,
        ar_invoice_item.line_item,
        ar_invoice_item.location_id,
        ar_invoice_item.location_name,
        ar_invoice_item.offset_gl_account_no,
        ar_invoice_item.offset_gl_account_title,
        ar_invoice_item.total_item_paid,
        ar_invoice_item.vendor_id,
        ar_invoice_item.vendor_name,
        ar_invoice_item.created_at,
        ar_invoice_item.modified_at,
        ar_invoice.due_in_days,
        ar_invoice.total_due,
        ar_invoice.total_entered,
        ar_invoice.total_paid,
        ar_invoice.record_id,
        count(*) over (partition by ar_invoice_item.invoice_id) as number_of_items

        from ar_invoice_item
        left join ar_invoice
            on ar_invoice_item.invoice_id = ar_invoice.invoice_id
    ),
{% endif %}


ap_ar_enhanced as (
    select * 
    from ap_bill_enhanced
    {% if var('sage_intacct__using_invoices', True) %}
        union all
        select * 
        from ar_invoice_enhanced
    {% endif %}
), 


final as (
    select 
        coalesce(bill_id, invoice_id) as document_id,
        coalesce(bill_item_id, invoice_item_id) as document_item_id,
        case 
            when bill_id is not null then 'bill' 
            when invoice_id is not null then 'invoice'
        end as document_type,
        entry_date_at,
        entry_description,
        amount,
        due_in_days,
        item_id,
        item_name,
        line_no,
        line_item, 
        customer_id,
        customer_name,
        department_id,
        department_name,
        location_id,
        location_name,
        vendor_id,
        vendor_name,
        account_no,
        account_title,
        class_id,
        class_name,
        created_at,
        modified_at,
        total_due,
        total_entered,
        total_paid,
        number_of_items,
        total_item_paid,
        offset_gl_account_no,
        offset_gl_account_title,
        record_id
    from ap_ar_enhanced
)

select *
from final

