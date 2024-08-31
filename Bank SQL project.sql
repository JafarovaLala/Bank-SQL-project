-- 1. customer_id = 1001 olan müştərinin son 6 ayda etdikləri əməliyyatların ümumi məbləği haqqın informasiyanı təyin edən sorğunu
--    yazın.
            select customer_id,
                   sum(t.amount)
              from transactıons t
            join accounts a on a.account_id=t.account_id
            where t.transaction_date between add_months(sysdate,-6) and sysdate
                  and a.customer_id=1001
            group by customer_id;
      
-- 2. Hər müştərinin hesablarında olan ümumi balansı və aktiv kredit məbləğini göstərmək: 

     select a.customer_id,
            sum(a.balance) as total_balance,
            sum(l.loan_amount) as total_loan
      from  accounts a
       join loans l 
         on  a.customer_id = l.customer_id
    group by a.customer_id;
  
-- 3. Aktiv depoziti olan müştərilərin depozit və kredit məlumatlarının siyahısını çıxarmaq:  
        
        select 
    c.customer_id,
    c.first_name,
    c.last_name,
    coalesce(d.deposit_amount, 0) as deposit_amount,
    coalesce(cl.credit_limit, 0) as credit_limit
          from  customers c 
left join 
    deposits d 
on 
    c.customer_id = d.customer_id
    and d.end_date > sysdate  
    and d.start_date <= sysdate
left join 
    credit_lines cl
on 
    c.customer_id = cl.customer_id;
         
-- 4. Hər müştərinin son 1 ildə açdığı bütün hesabları və bu hesablara görə edilən əməliyyatların ümumi məbləğini göstərmək:
      
select  c.first_name,
        a.customer_id,
        a.account_id,
        a.date_opened,
        coalesce(sum(t.amount), 0) as total_transaction_amount
  from  accounts a
left join
    transactions t on a.account_id = t.account_id
join
    customers c on a.customer_id = c.customer_id
where
    a.date_opened between ADD_MONTHS(SYSDATE, -12) and SYSDATE
group by
    c.first_name,
    a.customer_id,
    a.account_id,
    a.date_opened;


      
-- 5. Hər müştərinin son 1 ildə etdikləri əməliyyatların növlərinə görə ümumi məbləğini göstərmək:    

select c.first_name,
       c.customer_id,
       t.transaction_type,
       sum(t.amount) as total_amount
from   transactions t
join   accounts a
on     a.account_id=t.account_id
join   customers c 
on     c.customer_id=a.customer_id
where 
       transaction_date between add_months(sysdate,-12) and sysdate  
group by 
       c.first_name,c.customer_id,transaction_type
       ;        
      
-- 6. Hər müştəri üçün son 6 ayda əməliyyatların ən yüksək məbləğli əməliyyatını təyin edən sorğu yazın:

select c.customer_id,
       c.first_name,
       max(t.amount) as max_transaction_amount
from   transactions t
join
    accounts a on t.account_id = a.account_id
join
    customers c on a.customer_id = c.customer_id
where
    t.transaction_date between ADD_MONTHS(sysdate, -6) and sysdate
group by
    c.customer_id,
    c.first_name;


     
-- 7. Hər müştəri üçün son 1 il ərzində hər ay üzrə ümumi balans və depozit məbləğini göstərmək üçün sorğu yazın:   
     
 select 
         c.first_name, 
         extract(month from t.transaction_date) as months,
         sum(a.balance),
         sum(d.deposit_amount) 
from customers c
join accounts a on a.customer_id=c.customer_id
join deposits d on d.customer_id=a.customer_id
join transactions t on t.account_id=a.account_id
where t.transaction_date between add_months(sysdate,-12)  and sysdate
group by c.first_name,extract(month from t.transaction_date);    
     
     
     
-- 8. Hər müştərinin son 3 ay ərzində hər bir aya görə ən çox əməliyyat edən hesabının məbləğini göstərmək.

with cte as (select  c.customer_id,
                     c.first_name,
                    extract(month from t.transaction_date) as months,
                    a.account_id,
                    sum(t.amount),
          row_number() over (partition by first_name,extract(month from t.transaction_date) order by sum(t.amount) desc) as v
             from transactions t
             join accounts a on a.account_id=t.account_id
             join customers c on c.customer_id=a.customer_id
             where t.transaction_date between add_months(sysdate,-3) and sysdate
             group by first_name,extract(month from t.transaction_date),a.account_id,c.customer_id)
    select * from cte
    where v=1;
   


     
-- 9. Hər müştərinin son 3 ay ərzində müştərilərin ünvanlarına görə hər ay ümumi balansını və ünvanın tipini göstərmək.

select first_name,
       sum(t.amount),
       at.type_name,
       ad.address_name
from customers c
join address ad on ad.customer_id=c.customer_id
join address_type at on ad.type_id=at.type_id
join accounts ac on ac.customer_id=c.customer_id
join transactions t on ac.account_id=t.account_id
where t.transaction_date between  add_months(sysdate,-3) and sysdate
group by at.type_name,
         c.first_name,
         ad.address_name;
              
        
        
        
-- 11. Hər müştərinin son 1 il ərzində ən çox əməliyyat edilən günü göstərmək.   

    select row_number() over (order by count(*) desc) as rn,
           a.customer_id,
           t.transaction_date,
           count(*)
      from accounts a
join transactions t
on a.account_id=t.account_id
where t.transaction_date between  add_months(sysdate,-12) and sysdate
group by a.customer_id,
       t.transaction_date;

                                      
-- 12. Son 6 ayda ən yüksək kredit məbləğinə sahib olan müştəri haqqında məlumatlar və kredit məbləğini göstərmək.
   
select   first_name,
         last_name,
         c.customer_id,
         loan_amount,
         rank() over(order by  loan_amount desc) as v
from customers c
join loans l on l.customer_id=c.customer_id
where l.start_date between add_months(sysdate,-6) and sysdate 
and  l.end_date is null or  l.end_date >= add_months(sysdate, -6)
fetch first row only;
   
   

-- 13. Son 1 il ərzində hər müştəri üçün ən çox balans artımı olan ayı göstərmək.

select * from (select c.customer_id,
                      c.first_name,
                      t.transaction_type,
                      t.amount,
                      extract(month from t.transaction_date),
                      dense_rank() over(partition by c.customer_id order by t.amount desc) as v
                 from customers c
                  join accounts a on a.customer_id=c.customer_id
                  join transactions t on t.account_id=a.account_id
            where  t.transaction_date between add_months(sysdate,-12) and sysdate and t.transaction_type='Deposit')
where v=1;

       
-- 14. Hər müştərinin son 1 il ərzində ən çox istifadə edilən əməliyyat növlərini və həmin növlərə görə əməliyyatların sayını 
--     göstərmək.       

select * from (select c.customer_id,
                      c.first_name,
       t.transaction_type,
       count(t.transaction_type),
       dense_rank() over(partition by c.customer_id order by count(t.transaction_type) desc) as v
from customers c
join accounts a 
on a.customer_id=c.customer_id
join transactions t
on t.account_id=a.account_id
where  t.transaction_date between add_months(sysdate,-12) and sysdate
group by c.customer_id,c.first_name,
         t.transaction_type)
where v=1;


   
-- 15. Son 6 ay ərzində hər müştərinin ən uzun müddətli aktif kreditini tapmaq.
            
select *
from (select
        c.customer_id,
        c.first_name,
        l.loan_id,
        coalesce(l.end_date, sysdate) - l.start_date as days,
        row_number() over (partition by c.customer_id 
                     order by (coalesce(l.end_date, sysdate) - l.start_date) desc) as v
       from customers c
        join loans l on l.customer_id = c.customer_id
        where l.start_date between add_months(sysdate, -6) and sysdate
              and (l.end_date is null or l.end_date >= sysdate))
where
    v = 1
order by
    customer_id;
            
                       
            
-- 16. Son 1 il ərzində hər müştərinin hər ay ən çox balansı olan hesabını göstərmək. 

select * from 
         (select c.customer_id,
                 t.transaction_date,
                 balance,
                extract(month from transaction_date),
                row_number() over ( partition by extract(month from transaction_date) order by balance  desc) as rn
            from customers c
             join accounts a on a.customer_id=c.customer_id
             join transactions t on a.account_id=t.account_id
             where t.transaction_date between  add_months(sysdate,-12) and sysdate)
where rn=1;
    
   

     




  

