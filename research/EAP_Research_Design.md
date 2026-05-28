# Research Design — Finalized

## Title (Chinese)
数字化转型政策对企业信息化投资的影响——来自中国上市公司的准自然实验证据

## Title (English)
The Impact of Digital Transformation Policy on Enterprise Informatization Investment: 
Quasi-Natural Experimental Evidence from Chinese Listed Firms

## Journal Target
Economic Analysis and Policy (EAP) — Elsevier, SSCI/SCI Q1

---

## Research Question
中国各级政府出台的数字化转型政策是否显著促进了企业的信息化投资（ERP/IT系统）？

## Theoretical Framework
- 制度理论 (Institutional Theory): 政策压力 → 组织响应
- 资源基础观 (RBV): 数字化资源 → 竞争优势
- 信号传递理论: 政策信号 → 企业预期改变 → 投资决策

## Hypotheses
- **H1**: 数字化转型政策显著提升了企业信息化投资水平
- **H2**: 该效应在非国有企业中更为显著
- **H3**: 该效应在高科技行业中更为显著
- **H4**: 政府补贴在政策效应中起到中介作用
- **H5**: 市场化程度正向调节政策效应

---

## Methodology
**Multi-period DID (多期双重差分)**

- **政策冲击**: 各省市陆续出台的"数字化转型"/"数字经济"相关政策
- **处理组**: 政策出台省份的上市公司
- **对照组**: 尚未出台政策的省份的上市公司
- **时间窗口**: 2013-2023年
- **数据来源**: CSMAR + 手工整理政策文件

## Variables

### Dependent Variables (Y)
1. **IT_Invest**: 企业信息化投资 = 无形资产中"软件/系统"占比（或 IT资产/总资产）
2. **ERP_Dummy**: 是否实施 ERP（年报文本挖掘，虚拟变量）
3. **Digital_Trans**: 数字化转型指数（CSMAR 现成指标）

### Independent Variable (X)
- **Treat×Post**: DID核心交互项 = 是否处于已出台数字化政策的省份 × 政策出台后

### Control Variables
- Size: 总资产对数
- Lev: 资产负债率
- ROA: 总资产收益率
- Growth: 营业收入增长率
- Age: 上市年限
- Top1: 第一大股东持股比例
- BoardSize: 董事会规模
- Indep: 独立董事比例
- SOE: 国有企业虚拟变量
- Industry: 行业固定效应（证监会2012分类）
- Year: 年度固定效应

---

## Empirical Models

**Model 1 — Baseline DID:**
$$Y_{it} = \beta_0 + \beta_1 (Treat_i \times Post_{it}) + \gamma X_{it} + \mu_i + \delta_t + \varepsilon_{it}$$

**Model 2 — Heterogeneity (分组检验):**
按 SOE / 高科技行业 / 地区市场化程度分组回归

**Model 3 — Mechanism (中介效应):**
政府补贴 → 信息化投资

**Model 4 — Robustness:**
- PSM-DID
- 替换被解释变量
- 缩尾处理 (Winsorize 1%)
- 排除直辖市样本
- 平行趋势检验

---

## Paper Structure (EAP Format)
1. Introduction (~800 words)
2. Literature Review & Hypotheses (~1500 words)
3. Research Design (~1200 words)
4. Empirical Results (~2000 words)
5. Robustness Checks (~1000 words)
6. Heterogeneity Analysis (~800 words)
7. Conclusion & Policy Implications (~600 words)
