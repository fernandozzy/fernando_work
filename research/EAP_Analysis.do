/*****************************************************************
 * 论文: The Impact of Digital Transformation Policy on 
 *       Enterprise Informatization Investment
 * 期刊: Economic Analysis and Policy (EAP)
 * 方法: Multi-period DID + PSM-DID + Robustness + Heterogeneity
 * 数据: CSMAR A-share listed firms, 2013-2023
 *****************************************************************/

clear all
set more off
cd "/Users/Fernando/Desktop/EAP_Research"    // ← 改成你的工作目录

/*****************************************************************
 *  PART 1: 数据合并与预处理
 *****************************************************************/

* --- 1.1 导入各模块数据 ---
import excel "module1_company_info.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Province province
rename Industry_code industry_code
rename Listdate listdate
keep stkcd province industry_code listdate
duplicates drop stkcd, force
save "d_company.dta", replace

* 财务数据
import excel "module2_financial.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen size = ln(A001000)           // 总资产对数
gen lev = F091301A               // 资产负债率
gen roa = F050301A               // 总资产收益率
gen revenue = F010101A           // 营业收入
keep stkcd year size lev roa revenue
save "d_financial.dta", replace

* 无形资产（IT投资代理变量）
import excel "module3_intangible.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen it_asset = software + system  // 软件+系统类无形资产（根据实际字段调整）
gen it_invest = it_asset / A001000  // IT资产/总资产
keep stkcd year it_invest it_asset
save "d_intangible.dta", replace

* 公司治理
import excel "module4_governance.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen boardsize = Bddsize
gen indepd = Inddnum
keep stkcd year boardsize indepd
save "d_governance.dta", replace

* 股权性质
import excel "module5_ownership.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen top1 = Shrcrf1
gen soe = (actual_controller_nature == "国有")
keep stkcd year top1 soe
save "d_ownership.dta", replace

* 数字化转型指数
import excel "module6_digital.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen digital_trans = digital_transformation_index
keep stkcd year digital_trans
save "d_digital.dta", replace

* 政府补贴
import excel "module7_subsidy.xlsx", sheet("Sheet1") firstrow clear
rename Stkcd stkcd
rename Accper year
gen subsidy = government_subsidy_total
keep stkcd year subsidy
save "d_subsidy.dta", replace

* --- 1.2 合并所有数据 ---
use "d_financial.dta", clear
merge 1:1 stkcd year using "d_company.dta", keep(match) nogen
merge 1:1 stkcd year using "d_intangible.dta", keep(match) nogen
merge 1:1 stkcd year using "d_governance.dta", keep(match) nogen
merge 1:1 stkcd year using "d_ownership.dta", keep(match) nogen
merge 1:1 stkcd year using "d_digital.dta", keep(match) nogen
merge 1:1 stkcd year using "d_subsidy.dta", keep(match) nogen

* 计算上市年限
gen age = year - year(listdate)

* 计算营收增长率
sort stkcd year
by stkcd: gen growth = (revenue - L.revenue) / L.revenue

* 计算独董比例
gen indep_ratio = indepd / boardsize

* --- 1.3 样本筛选 ---
* 剔除金融行业
drop if substr(industry_code,1,1) == "J"

* 剔除 ST 公司（如有标识变量）
* drop if st == 1

* 保留 2013-2023 年
keep if year >= 2013 & year <= 2023

* 剔除关键变量缺失
dropmissing stkcd year size lev roa it_invest soe top1 boardsize

* 缩尾处理 (1%)
winsor2 size lev roa growth it_invest subsidy top1 indep_ratio, cut(1 99)

* 保存合并后数据
save "d_merged.dta", replace

/*****************************************************************
 *  PART 2: 构建 DID 核心变量
 *****************************************************************/

* 导入政策时间线（手工整理的各省份政策出台年份）
* 格式: province | policy_year
import excel "policy_timeline.xlsx", sheet("Sheet1") firstrow clear
rename province policy_province
rename policy_year policy_yr
save "d_policy.dta", replace

* 回到主数据，生成 Treat × Post
use "d_merged.dta", clear
merge m:1 province using "d_policy.dta", keep(match) nogen

gen post = (year >= policy_yr) if policy_yr != .
gen treat = (policy_yr != .)
gen treat_post = treat * post

* 如果没有政策记录的省份视为对照组 (treat=0, post=0)
replace treat = 0 if treat == .
replace post = 0 if post == .
replace treat_post = 0 if treat_post == .

save "d_final.dta", replace

/*****************************************************************
 *  PART 3: 描述性统计
 *****************************************************************/

use "d_final.dta", clear

* 3.1 描述性统计
estpost summarize stkcd year it_invest digital_trans treat_post size lev roa growth age top1 indep_ratio boardsize subsidy soe
esttab using "results/Table1_Descriptive.rtf", replace ///
    cells("mean(fmt(4)) sd(fmt(4)) min(fmt(4)) max(fmt(4)) p50(fmt(4))") ///
    title("Table 1: Descriptive Statistics")

* 3.2 相关系数矩阵
pwcorr it_invest treat_post size lev roa growth age top1 indep_ratio subsidy, sig star(0.05)
estpost correlate it_invest treat_post size lev roa growth top1 subsidy soe, matrix
esttab using "results/Table2_Correlation.rtf", replace ///
    cells("b(fmt(3))") ///
    title("Table 2: Correlation Matrix")

* 3.3 VIF 检验（检验多重共线性）
reg it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe
vif

/*****************************************************************
 *  PART 4: 基准回归 (Baseline DID)
 *****************************************************************/

use "d_final.dta", clear

* 4.1 主回归 - IT_Invest 为因变量
xtset stkcd year
reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio boardsize subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store m1
outreg2 [m1] using "results/Table3_Baseline.doc", replace ///
    addtext(Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* 4.2 不加控制变量
reghdfe it_invest treat_post, absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store m0
outreg2 [m0 m1] using "results/Table3_Baseline.doc", replace ///
    addtext(Firm FE, YES, Year FE, YES, Controls, "NO/YES") ///
    dec(3) starlevels(0.1 0.05 0.01)

* 4.3 以 ERP_Dummy 为因变量（Logit 模型）
* 注：需要先通过年报文本挖掘生成 erp_dummy 变量
logit erp_dummy treat_post size lev roa growth age top1 indep_ratio subsidy soe ///
    i.stkcd i.year, vce(cluster stkcd)

* 4.4 以 Digital_Trans 为因变量
reghdfe digital_trans treat_post size lev roa growth age top1 indep_ratio boardsize subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store m3
outreg2 [m3] using "results/Table3_Baseline.doc", append ///
    addtext(Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

/*****************************************************************
 *  PART 5: 稳健性检验
 *****************************************************************/

* 5.1 平行趋势检验（Event Study）
use "d_final.dta", clear

* 生成事件年相对变量
gen rel_year = year - policy_yr
* 生成各年虚拟变量
forvalues k = -5/5 {
    gen D_`k' = (rel_year == `k') if treat == 1
    replace D_`k' = . if treat == 0 & `k' < 0
    replace D_`k' = 0 if treat == 0 & `k' >= 0
}

reghdfe it_invest D_-5 D_-4 D_-3 D_-2 D_-1 D_1 D_2 D_3 D_4 D_5 ///
    size lev roa growth age top1 indep_ratio subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)

* 画图
coefplot, keep(D_-5 D_-4 D_-3 D_-2 D_-1 D_1 D_2 D_3 D_4 D_5) ///
    vertical yline(0) title("Figure 1: Parallel Trend Test") ///
    scheme(s1mono)

* 5.2 PSM-DID
* 第一步：PSM 匹配
psmatch2 treat size lev roa growth age top1 soe, out(it_invest) ///
    logit noreplacement caliper(0.01) common

* 第二步：保留匹配样本，重新跑 DID
keep if _support == 1 & _treated == 1
merge 1:1 stkcd year using "d_final.dta", keep(match) nogen
reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store psm_did
outreg2 [psm_did] using "results/Table6_Robustness.doc", replace ///
    addtext(PSM-DID, YES, Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* 5.3 安慰剂检验（随机分配政策时间）
preserve
clear
set obs 1000
gen beta = .
forvalues i = 1/1000 {
    use "d_final.dta", clear
    * 随机打乱政策年份
    set seed `i'
    gen rand_policy = policy_yr + int(uniform()*6) - 3
    gen fake_post = (year >= rand_policy)
    gen fake_treat_post = treat * fake_post
    reghdfe it_invest fake_treat_post size lev roa, ///
        absorb(i.stkcd i.year) vce(cluster stkcd)
    matrix b = e(b)
    replace beta = b[1,1] in `i'
}
histogram beta, normal title("Figure 2: Placebo Test") scheme(s1mono)
graph export "results/Figure2_Placebo.png", replace
restore

* 5.4 替换因变量（用 Digital_Trans 代替 IT_Invest）
reghdfe digital_trans treat_post size lev roa growth age top1 indep_ratio subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)

* 5.5 排除直辖市样本
drop if inlist(province, "北京", "上海", "天津", "重庆")
reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)

/*****************************************************************
 *  PART 6: 异质性分析
 *****************************************************************/

* 6.1 按产权性质分组（H2）
* 非国有企业样本
reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe ///
    if soe == 0, absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store non_soe

* 国有企业样本
reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe ///
    if soe == 1, absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store soe

outreg2 [non_soe soe] using "results/Table7_Heterogeneity.doc", replace ///
    addtext(Group, "Non-SOE / SOE", Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* Chow 检验（组间差异）
* 使用 suest 或交互项方法
gen treat_post_nonsOE = treat_post * (1 - soe)
gen treat_post_SOE = treat_post * soe
reghdfe it_invest treat_post_nonsOE treat_post_SOE ///
    size lev roa growth age top1 indep_ratio subsidy, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
test treat_post_nonsOE = treat_post_SOE

* 6.2 按高科技行业分组（H3）
* 需要先定义高科技行业标识
gen high_tech = inlist(substr(industry_code,1,2), "C6", "C7", "I65", "I63")

reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe ///
    if high_tech == 1, absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store high_tech

reghdfe it_invest treat_post size lev roa growth age top1 indep_ratio subsidy soe ///
    if high_tech == 0, absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store non_high_tech

outreg2 [high_tech non_high_tech] using "results/Table7_Heterogeneity.doc", append ///
    addtext(Group, "High-Tech / Non-High-Tech", Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* 6.3 按市场化程度分组（H5）
* 使用樊纲市场化指数（需要额外数据）
* 假设已有市场化指数数据 d_marketization.dta: province | year | market_index
* merge m:1 province year using "d_marketization.dta"
* gen high_market = (market_index > median(market_index))

/*****************************************************************
 *  PART 7: 机制检验（中介效应 - H4）
 *****************************************************************/

* 7.1 第一步：政策 → 政府补贴
reghdfe subsidy treat_post size lev roa growth age top1 indep_ratio soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store med1
outreg2 [med1] using "results/Table8_Mechanism.doc", replace ///
    addtext(DepVar, "Subsidy", Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* 7.2 第二步：补贴 → IT投资（控制政策）
reghdfe it_invest treat_post subsidy size lev roa growth age top1 indep_ratio soe, ///
    absorb(i.stkcd i.year) vce(cluster stkcd)
estimates store med2
outreg2 [med2] using "results/Table8_Mechanism.doc", append ///
    addtext(DepVar, "IT_Invest", Firm FE, YES, Year FE, YES) ///
    dec(3) starlevels(0.1 0.05 0.01)

* 7.3 Sobel 检验
* 需要安装 sgmediation（如未安装：ssc install sgmediation）
sgmediation it_invest, mv(subsidy) iv(treat_post) ///
    cv(size lev roa growth age top1 indep_ratio soe)

/*****************************************************************
 *  PART 8: 结果输出汇总
 *****************************************************************/

* 确保所有结果文件已保存
* results/Table1_Descriptive.rtf
* results/Table2_Correlation.rtf
* results/Table3_Baseline.doc
* results/Table6_Robustness.doc
* results/Table7_Heterogeneity.doc
* results/Table8_Mechanism.doc
* results/Figure1_ParallelTrend.png
* results/Figure2_Placebo.png

* 完成！
display "=== All analyses completed. Check results/ folder for output files ==="
