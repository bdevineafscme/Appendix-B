/*
updated source code list:

RECURRING/ONLINE
1004914 Payroll Deduction
1004923 Salsa On-Line Recurring
1004924 PledgeUp Source
1004926 EFTS
1004992 UPay Source
--NEW
1004999 Payroll Deduction NonFederal
1005003 IEB Payroll
1005004 Affiliate Staff Payroll Deduction
1005005 AFSCME INTERNATIONAL payroll deduction
1005007 Payroll Deduction Retiree
1005009 WePay Recurring RETIREE
1005010 UPAY RETIREE
1004998 WePay Recurring
1004916 Monthly Credit Card
1004921 Fundraiser


DIRECT CONTRIBUTIONS
1004925 Direct Contribution
1005008 WePay Direct RETIREE
1005006 Retiree Direct Contributions
1004997 WePay Direct
1004927 Salsa On-Line Direct


PASS THE HAT
1004919


--ADDED 11/6: suppression source codes
1004995 Loan Payments
1004994 Loan Proceeds
1004993 Erroneous Deposit
1004996 refund
1005012 Interest Income


BEFORE RUNNING: CHANGE DATES IN 2 LOCATIONS:
--line 157
--line 226
*/

--create temp table new_appx_b as 
select ao.finish_affpk
--make IU staff contributions cleaner in-line, pt 1
,case 
	when ao.finish_affpk = 6837 then 100523425
	else a.vanid 
end as vanid
,ao.aff_statenat_type as aff_state
,case  
        when nullif(ao.aff_councilretiree_chap, '') is not null and ao.aff_councilretiree_chap  != '1000' then 'C'||ao.aff_councilretiree_chap
        when nullif(ao.aff_councilretiree_chap, '')  is null and nullif(ao.aff_localsubchapter,'') is not null and ao.aff_type in ('R', 'O') then 'C'||ao.aff_councilretiree_chap
        when nullif(ao.aff_councilretiree_chap, '')  is not null and ao.aff_councilretiree_chap = '1000' then 'L1000'
        when nullif(ao.aff_councilretiree_chap, '')  is null and nullif(ao.aff_localsubchapter,'') is not null then 'L'||ao.aff_localsubchapter
end as aff_name
,case 
        when ao.aff_type = 'C' then 'Council'
        when ao.aff_type = 'L' then 'Local'
        when ao.aff_type in ('R','S', 'O') then 'Retiree'
        when ao.aff_type = 'U' and aff_localsubchapter = 1199 then 'Local'
        else ao.aff_type
end as aff_type 
--make IU staff contributions cleaner in-line, pt 2
,ao.aff_abbreviated_nm as formal_aff_name
,ao.aff_status
,case 
	when x.finish_affpk = 6837 then 'AFSCME International Staff'
	else coalesce(a.vanofficialname,attrib_name) 
end as attrib
/*
,sum(amt_recurring_or_online) as amt_recurring_or_online
,sum(amt_direct_contrib) as amt_direct_contrib
,sum(amt_pass_the_hat) as amt_pass_the_hat
,sum(amt_other) as amt_other
,sum(total_contrib_amt) as total_contrib_amt
*/
,stataverage_rollup
--new 
			,sum(payroll_deduction) AS payroll_deduction
		        ,sum(payroll_deduction_retirees) AS payroll_deduction_retirees
		        ,sum(upay) AS upay
		        ,sum(upay_retirees) AS upay_retirees
		        ,sum(efts) AS efts
		        ,sum(payroll_deduction_non_federal) as payroll_deduction_non_federal
		        ,sum(IEB_payroll) AS IEB_payroll
		        ,sum(affiliate_state_payroll_deduction) AS affiliate_staff_payroll_deduction
		        ,sum(AFSCME_INTL_payroll_deduction) AS AFSCME_INTL_payroll_deduction
		        ,sum(wepay_recurring) AS wepay_recurring
		        ,sum(wepay_recurring_retiree) AS wepay_recurring_retiree
		        ,sum(direct_contribution) AS direct_contribution
		        ,SUM(direct_contribution_retirees) AS direct_contribution_retirees
		        ,sum(wepay_direct) AS wepay_direct
		        ,sum(wepay_direct_retirees) AS wepay_direct_retirees
		        ,sum(pass_the_hat) AS pass_the_hat
		        ,sum(late_backup) AS late_backup
		        ,sum(no_backup_retirees) AS no_backup_retirees
		        ,sum(no_backup) AS no_backup
		        ,sum(sales) AS sales
		        ,sum(fundraiser) AS fundraiser
			,sum(Federal_contrib_amt) AS Federal_contrib_amt
			,sum(NonFederal_contrib_amt) AS NonFederal_contrib_amt
		        --end new
from (
	select distinct finish_affpk
	,ao.aff_type
	,ao.aff_statenat_type
	,ao.aff_councilretiree_chap
	,ao.aff_localsubchapter
	,ao.aff_abbreviated_nm
	,c.com_cd_desc as aff_status
	--need to stop MN65 retirees from rolling up to the Council
	from (select start_affpk, case when start_affpk = 6863 then 6863 else finish_affpk end as finish_affpk from enterprise.aff_pk_rollup) e
	left join enterprise_replica.aff_organizations ao on e.finish_affpk = ao.aff_pk
	left join enterprise_replica.common_codes c on c.com_cd_pk = ao.aff_status
	--include chartered, not chartered, administratorship, and Administrative/Legislative Council affiliates
	where aff_status in (17002, 17007, 17010, 17001)
) ao
left join (
		--this section is a bit verbose but is useful for calculating amt_other as well as easily unrolling for auditing
		select distinct
                case 
			--mergers that haven't made it into Enterprise yet
			when finish_affpk = 673 then 4575
			when finish_affpk = 4579 then 4576
			when finish_affpk = 6694 then 6693
			when finish_affpk = 15416 then 675
			when finish_affpk = 4602 then 4596
			when finish_affpk = 700 then 6857
			when finish_affpk = 4595 then 4598
			when finish_affpk = 691 then 6880
			when finish_affpk = 4562 then 15525
			when finish_affpk = 9869 then 4597
			--correction for WV77 non-retiree attributions to roll to OH 8
			when finish_affpk = 674 then 4568
			--stop C65 retirees from rolling up higher, fold in C6 retirees
			when c.aff_pk = 6863 then 6863
			when finish_affpk = 6847 then 6863
			--roll up MD 2250 retirees to C1 retirees
			when finish_affpk = 8942 then 6842
			--NUUCHE rollup to national
			--when finish_affpk in (2355,2356,8612,208,2357) then 207
			when finish_affpk IN (4593,4601,4603) THEN 15525
			else finish_affpk
		end as finish_affpk
		,attributed
		,attrib_name
		
		--new 
		,payroll_deduction
		,payroll_deduction_retirees
		,upay
		,upay_retirees
		,efts
		,payroll_deduction_non_federal
		,IEB_payroll
		,affiliate_state_payroll_deduction
		,AFSCME_INTL_payroll_deduction
		,wepay_recurring
		,wepay_recurring_retiree
		,direct_contribution
		,direct_contribution_retirees
		,wepay_direct
		,wepay_direct_retirees
		,pass_the_hat
		,late_backup
		,no_backup_retirees
		,no_backup
		,sales
		,fundraiser
		,Federal_contrib_amt
		,NonFederal_contrib_amt
		--end new
		
		
		,amt_recurring_or_online
		,amt_direct_contrib
		,amt_pass_the_hat
		,(total_contrib_amt - (amt_recurring_or_online + amt_direct_contrib + amt_pass_the_hat)) as amt_other
		,total_contrib_amt
		from (
			select distinct attributed, attrib_name, aff_pk, finish_affpk
			--new 
	            	,sum(payroll_deduction) AS payroll_deduction
		        ,sum(payroll_deduction_retirees) AS payroll_deduction_retirees
		        ,sum(upay) AS upay
		        ,sum(upay_retirees) AS upay_retirees
		        ,sum(efts) AS efts
		        ,sum(payroll_deduction_non_federal) as payroll_deduction_non_federal
		        ,sum(IEB_payroll) AS IEB_payroll
		        ,sum(affiliate_state_payroll_deduction) AS affiliate_state_payroll_deduction
		        ,sum(AFSCME_INTL_payroll_deduction) AS AFSCME_INTL_payroll_deduction
		        ,sum(wepay_recurring) AS wepay_recurring
		        ,sum(wepay_recurring_retiree) AS wepay_recurring_retiree
		        ,sum(direct_contribution) AS direct_contribution
		        ,SUM(direct_contribution_retirees) AS direct_contribution_retirees
		        ,sum(wepay_direct) AS wepay_direct
		        ,sum(wepay_direct_retirees) AS wepay_direct_retirees
		        ,sum(pass_the_hat) AS pass_the_hat
		        ,sum(late_backup) AS late_backup
		        ,sum(no_backup_retirees) AS no_backup_retirees
		        ,sum(no_backup) AS no_backup
		        ,sum(sales) AS sales
		        ,sum(fundraiser) AS fundraiser
				,sum(Federal_contrib_amt) AS Federal_contrib_amt
				,sum(NonFederal_contrib_amt) AS NonFederal_contrib_amt
		        --end new
			, sum(amt_recurring_or_online) as amt_recurring_or_online, sum(amt_direct_contrib) as amt_direct_contrib, sum(amt_pass_the_hat)as amt_pass_the_hat, sum(total_contrib_amt) as total_contrib_amt
            		from (
				select coalesce(attributedvanid, contributorvanid) as attributed
				,c.organizationcontactofficialname as attrib_name
				,a.aff_pk
				,r.finish_affpk
				
				--new columns
				,nvl(sum (case when contrib_code in (1004914, 1005001) then amount else null end),0.0) as payroll_deduction
				,nvl(sum (case when contrib_code in (1005002, 1005007) then amount else null end),0.0) as payroll_deduction_retirees
				,nvl(sum (case when contrib_code in (1004992,1004924) then amount else null end),0.0) as upay
				,nvl(sum (case when contrib_code in (1005010) then amount else null end),0.0) as upay_retirees
				,nvl(sum (case when contrib_code in (1004926) then amount else null end),0.0) as efts
				,nvl(sum (case when contrib_code in (1004999) then amount else null end),0.0) as payroll_deduction_non_federal
				,nvl(sum (case when contrib_code in (1005003) then amount else null end),0.0) as IEB_payroll
				,nvl(sum (case when contrib_code in (1005004) then amount else null end),0.0) as affiliate_state_payroll_deduction
				,nvl(sum (case when contrib_code in (1005005) then amount else null end),0.0) as AFSCME_INTL_payroll_deduction
				,nvl(sum (case when contrib_code in (1004998,1004923,1004916) then amount else null end),0.0) as wepay_recurring
				,nvl(sum (case when contrib_code in (1005009) then amount else null end),0.0) as wepay_recurring_retiree
				,nvl(sum (case when contrib_code in (1004925) then amount else null end),0.0) as direct_contribution
				,nvl(sum (case when contrib_code in (1005006) then amount else null end),0.0) as direct_contribution_retirees
				,nvl(sum (case when contrib_code in (1004997,1004927) then amount else null end),0.0) as wepay_direct
				,nvl(sum (case when contrib_code in (1005008) then amount else null end),0.0) as wepay_direct_retirees
				,nvl(sum (case when contrib_code in (1004919) then amount else null end),0.0) as pass_the_hat
				,nvl(sum (case when contrib_code in (1005031) then amount else null end),0.0) as late_backup
				,nvl(sum (case when contrib_code in (1005011) then amount else null end),0.0) as no_backup_retirees
				,nvl(sum (case when contrib_code in (1004918) then amount else null end),0.0) as no_backup
				,nvl(sum (case when contrib_code in (1004920) then amount else null end),0.0) as sales
				,nvl(sum (case when contrib_code in (1004921) then amount else null end),0.0) as fundraiser
				,nvl(sum(case when  financialprogramid = 42 then amount else null::float end),0.0) AS Federal_contrib_amt
				,nvl(sum(case when financialprogramid = 43 then amount else null::float   end),0.0) AS NonFederal_contrib_amt
				--end new columns
				
                		,nvl(sum (case when contrib_code in (1004914, 1004923, 1004924, 1004926, 1004992,1004999,1005003,1005004,1005005,1005007,1005009,1005010,1004998,1004916) then amount else null end),0.0) as amt_recurring_or_online
				,nvl(sum (case when contrib_code in (1004925,1005008,1005006,1004997,1004927) then amount else null end),0.0) as amt_direct_contrib
				, nvl(sum (case when contrib_code = 1004919 then amount else null end),0.0) as amt_pass_the_hat
				, nvl(sum (amount),0.0) as total_contrib_amt
				from
				(	select
					distinct
					c.contactscontributionid
					,amount
					,c.datereceived
					,ccac.attributedvanid
					,ac.contactmodeid as attributedtype
					,financialprogramid 
					,paymenttypeid
					,cc.vanid as contributorvanid
					,cc.contactmodeid as contributortype
					,ccc.codeid as contrib_code
					,f.aff_pk
					from vansync.afscme_ea_contactscontributions c
					left join vansync.afscme_ea_contactscontributionsattributedcontacts ccac on c.contactscontributionid = ccac.contactscontributionid
					left join vansync.afscme_ea_contacts ac on ccac.attributedvanid = ac.vanid
					left join vansync.afscme_ea_contacts cc on c.vanid = cc.vanid
					left join vansync.afscme_ea_contactscontributionscodes ccc on ccc.contactscontributionid = c.contactscontributionid
					left join vansync.afscme_ea_contactscustomfields f on f.vanid = ccac.attributedvanid
					where extract (year from c.datereceived) = 2022
						and c.datereceived <= '09-30-2022'
						and ccac.datesuppressed is null
						and c.amount > 0
						and (ac.contactmodeid = 2 or (ccac.attributedvanid is null and cc.contactmodeid = 2))
					and financialprogramid in (42, 43)
					and c.datecanceled is null
				--	and paymenttypeid in (1,11,17)
				-- ADD 3/4/21: also suppress DC37 pac-to-pac transfers to union on separately for proper accounting 
					and ccc.codeid not in (1004993,1004994,1004995,1004996,1005001, 1005002,1005012)
				) a
				left join vansync.afscme_ea_contacts c on coalesce(attributedvanid, contributorvanid) = c.vanid
				left join enterprise.aff_pk_rollup r on r.start_affpk = a.aff_pk
				group by 1,2,3,4
				
				UNION 

				select attributed
				,attrib_name
				,c.aff_pk
				,r.finish_affpk
				--new columns
						,payroll_deduction
						,payroll_deduction_retirees
						,upay
						,upay_retirees
						,efts
						,payroll_deduction_non_federal
						,IEB_payroll
						,affiliate_state_payroll_deduction
						,AFSCME_INTL_payroll_deduction
						,wepay_recurring
						,wepay_recurring_retiree
						,direct_contribution
						,direct_contribution_retirees
						,wepay_direct
						,wepay_direct_retirees
						,pass_the_hat
						,late_backup
	                                       	,no_backup_retirees
	                                       	,no_backup
		                                ,sales
		                                ,fundraiser
						,Federal_contrib_amt
						,NonFederal_contrib_amt
					--end new columns
				,amt_recurring_or_online
				,amt_direct_contrib
				,amt_pass_the_hat
				,total_contrib_amt
				from (
					select 
					contrib_code,
					case 
						when contrib_code = 1005001 and contributorvanid = 100525978 then 100508423
						when contrib_code = 1005002 and contributorvanid = 100525978 then 100508653
						else null end
					as attributed
					,case 
						when contrib_code = 1005001 and contributorvanid = 100525978 then 'Nyc Dst Cn Afscme Unions'
						when contrib_code = 1005002 and contributorvanid = 100525978 then 'Retirees Assoc Of Dc 37'
						else null end as attrib_name
					,case
					   when contrib_code = 1005002 and contributorvanid = 100525978 then '6857'
					   else aff_pk end
					   as aff_pk
					
					
					,nvl(sum (
						case
						when (financialprogramid = 42 and paymenttypeid in (1,7,11,17)) then amount
						else null::float end
					),0.0) as amt_recurring_or_online
					,nvl(sum (
						case 	
						when (financialprogramid = 42 and paymenttypeid in (1,5,6)) then amount
						else null::float end
					),0.0) as amt_direct_contrib
					, 0.0 as amt_pass_the_hat
					, nvl(sum (amount),0.0) as total_contrib_amt
					--new columns
						,nvl(sum (case when contrib_code in (1004914, 1005001) then amount else null end),0.0) as payroll_deduction
						,nvl(sum (case when contrib_code in (1005002, 1005007) then amount else null end),0.0) as payroll_deduction_retirees
						,nvl(sum (case when contrib_code in (1004992,1004924) then amount else null end),0.0) as upay
						,nvl(sum (case when contrib_code in (1005010) then amount else null end),0.0) as upay_retirees
						,nvl(sum (case when contrib_code in (1004926) then amount else null end),0.0) as efts
						,nvl(sum (case when contrib_code in (1004999) then amount else null end),0.0) as payroll_deduction_non_federal
						,nvl(sum (case when contrib_code in (1005003) then amount else null end),0.0) as IEB_payroll
						,nvl(sum (case when contrib_code in (1005004) then amount else null end),0.0) as affiliate_state_payroll_deduction
						,nvl(sum (case when contrib_code in (1005005) then amount else null end),0.0) as AFSCME_INTL_payroll_deduction
						,nvl(sum (case when contrib_code in (1004998,1004923,1004916) then amount else null end),0.0) as wepay_recurring
						,nvl(sum (case when contrib_code in (1005009) then amount else null end),0.0) as wepay_recurring_retiree
						,nvl(sum (case when contrib_code in (1004925) then amount else null end),0.0) as direct_contribution
						,nvl(sum (case when contrib_code in (1005006) then amount else null end),0.0) as direct_contribution_retirees
						,nvl(sum (case when contrib_code in (1004997,1004927) then amount else null end),0.0) as wepay_direct
						,nvl(sum (case when contrib_code in (1005008) then amount else null end),0.0) as wepay_direct_retirees
						,nvl(sum (case when contrib_code in (1004919) then amount else null end),0.0) as pass_the_hat
						,nvl(sum (case when contrib_code in (1005031) then amount else null end),0.0) as late_backup
		                      		,nvl(sum (case when contrib_code in (1005011) then amount else null end),0.0) as no_backup_retirees
				                ,nvl(sum (case when contrib_code in (1004918) then amount else null end),0.0) as no_backup
			                     	,nvl(sum (case when contrib_code in (1004920) then amount else null end),0.0) as sales
			                     	,nvl(sum (case when contrib_code in (1004921) then amount else null end),0.0) as fundraiser
						,nvl(sum (CASE WHEN financialprogramid = 42 THEN amount else null::float end),0.0) as Federal_contrib_amt
						,nvl(sum (CASE WHEN financialprogramid = 43 THEN amount  else null::float  end),0.0) as NonFederal_contrib_amt
					--end new columns
					from
					(	select
						distinct
						c.contactscontributionid
						,amount
						,c.datereceived
						,ccac.attributedvanid
						,ac.contactmodeid as attributedtype
						,financialprogramid 
						,paymenttypeid
						,cc.vanid as contributorvanid
						,cc.contactmodeid as contributortype
						,ccc.codeid as contrib_code
						,f.aff_pk
						from vansync.afscme_ea_contactscontributions c
						left join vansync.afscme_ea_contactscontributionsattributedcontacts ccac on c.contactscontributionid = ccac.contactscontributionid
						left join vansync.afscme_ea_contacts ac on ccac.attributedvanid = ac.vanid
						left join vansync.afscme_ea_contacts cc on c.vanid = cc.vanid
						left join vansync.afscme_ea_contactscontributionscodes ccc on ccc.contactscontributionid = c.contactscontributionid
						left join vansync.afscme_ea_contactscustomfields f on f.vanid = ccac.attributedvanid
					        where extract (year from c.datereceived) = 2022
						        and c.datereceived <= '09-30-2022'
							and ccac.datesuppressed is null
							and c.amount > 0
							and (ac.contactmodeid = 2 or (ccac.attributedvanid is null and cc.contactmodeid = 2))
						and financialprogramid in (42, 43)
						and c.datecanceled is null
					--	and paymenttypeid in (1,11,17)
					-- ADD 3/4/21: also suppress DC37 pac-to-pac transfers to union on separately for proper accounting 
						and ccc.codeid IN (1005001, 1005002)
					) a
					left join vansync.afscme_ea_contacts c on coalesce(attributedvanid, contributorvanid) = c.vanid
					group by 1,2,3,4
					order by 1,2,7
				     ) c
			      left join enterprise.aff_pk_rollup r on r.start_affpk = c.aff_pk
	                )
                group by 1,2,3,4
		) c
		where coalesce(amt_recurring_or_online,amt_direct_contrib,amt_pass_the_hat, amt_other) is not null
) x on x.finish_affpk = ao.finish_affpk
--ADDED 2/8/21: relying on a static table leaves some blanks over time.Need to probably find a better way to handle this moving forward
left join (
        select distinct vanid, state, vanofficialname, aff_pk 
        from people_portal.ea_top_level_attributions
)a on a.aff_pk = x.finish_affpk
left join (
	select finish_affpk
	, nvl(sum(stataverage),0.0) as stataverage_rollup
	from
	(
	      select gp_customer_id
	            ,affpk as aff_pk
	            ,localname
	            ,r.finish_affpk
	            ,ceil(avg(avunits::float)) as stataverage
	        from
	        (
	        select b.localname
	            ,b.affpk
	            ,b.gp_customer_id
	            ,a.avunits
	            ,a.averageid
	            ,a.avformonth
	            ,a.avforyear
	            ,datediff(month, (avforyear::varchar + '-' + avformonth::varchar + '-' + '1')::date, current_date) as difference
	            ,c.flagid
	            ,d.flagdesc
	        from stat.statlocalaverage a
	            left join stat.statlocal b
	                using (localid)
	            left join stat.stataverageflags c
	                using (averageid)
	            left join stat.statflags d
	                using (flagid)
	        where (difference <=13 and difference >=1)
	        )a
	        left join enterprise.aff_pk_rollup r on r.start_affpk = a.affpk
	        where (avunits != 0 or flagid = 9) 
	            and (flagid is null or flagid not in (2,3,5,6) or (flagid in (5,6) and avunits !=0))
	        group by 1,2,3,4
	)
	group by 1
) stat on stat.finish_affpk = x.finish_affpk
where ao.finish_affpk not in (692,6694,14429)
and ao.aff_abbreviated_nm not ilike 'PEOPLE UNKNOWN'
group by 1,2,3,4,5,6,7,8,9
order by 3,4,5
;
