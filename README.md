# 2024 SOA Challenge - CC24
# Let Your Health Work For You
## Health Check and Travel Discounts Scheme

![image](https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/e54e7f26-8773-450a-9cd7-31430e58733f)

# Group Members
* Zi Qing (Nick) Ng
* Crystal Chong
* Yaxiao (Albert) Liu
* Natalie Khalil 
* Hasibul Alam

# Report Overview

## Table of Contents
* [Objectives](#objectives)
* [Program Design](#program-design)
* [Pricing/Costs](#pricingcosts)
* [Risk and Risk Mitigation](#risk-and-risk-mitigation)
* [Assumptions](#assumptions)

## Objectives

Main Objectives
* Reduce the mortality rate of current SuperLife policyholders 
* Attract and retain healthy and health-conscious clients 
* Increase SuperLife's economic value

Metrics 
* Extent of reductions in mortality rate
* Profitability of the program
* Customer acquisition rates

**EXPLORATORY DATA ANALYSIS (EDA) & DATA CLEANING**

The file was loaded straight into R after downloading in their original format. The in force dataset was csv and the rest were xlsx Excel files. Data cleaning included removing empty rows and columns so that the data could be displayed better in RStudio. 

**Data Preparation and Cleaning**

For DB modelling, it’s very important to include as many policyholders as possible who are dead, lapsed, and still alive as of 2023. If we naively only analysed dead people, then that would underestimate the “true” average years before death of the sample given. This is because the years before death of people who are still alive or have lapsed is unknown and could possibly take high values. There cannot be too many missing NA values in the predictors and the response as it would propagate (especially in models with thousands of trees) and predictions would have many NA’s. At the same time, by keeping all columns and removing all NA values results in a totally empty dataset. Here, a balance is achieved by removing the year of lapse column, since 
that has the highest percentage of NA values.

Figure 1 below

<img width="794" alt="Screenshot 2024-04-07 at 11 03 13 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/284330db-656c-4ac6-a8c8-31932a7bbc19">

From above, the horizontal black line denotes the median, and the black star the mean of each cause of death. The median and mean lifespans for each disease are quite similar. Outliers are shown as individual dots when they are Q3 + 1.5*IQR or greater, or Q1-1.5*IQR or smaller. The disease O00-O99 has obviously a very small IQR (spread), and the lifespans of those afflicted are very short. This could be quite a severe disease that kills people at younger ages, however its frequency will be explored more in the corresponding barplot below. According to the ICD-10, O00-O99 refers to “personal history of complications of pregnancy, childbirth and the puerperium”.

Figure 2 below

<img width="528" alt="Screenshot 2024-04-07 at 11 03 35 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/df6f015a-a6fd-4f64-9315-0f95a2f1c39f">

From figure 2 above, note that the rates increase and decrease together and seem to be highly correlated with one another. In 2015 when the 1 year risk free (r.f) annual spot rate and overnight rate starts to increase again. Interestingly, the 10-year r.f annual spot rate still has not started increasing yet even at 2023. For more EDA plots and further analysis, see Appendix 1.

## Program Design 

We propose a joint venture between SuperLife Insurance and a Lumarian airline company, in which policyholders are awarded travel points for completing a health checklist. The checklist will monitor blood pressure, cholesterol and other markers of a healthy circulatory system and include preventative scans for various conditions such as cancer. Neoplasms (C00-D48) and circulatory system diseases (I00-I99) are responsible for 63% of policyholder deaths between 2001 and 2023, with the average age of death being 59.8 and 60.5, respectively. These ages are below the average Lumarian life expectancy, 78.4, indicating that mortality improvements are achievable. Early detection of these two primary causes of death will reduce mortality rates by 10-20% according to similar Lumarian intervention schemes. The checklist is an online document that can be printed by the policyholder and presented to the relevant medical practitioner, who will sign, stamp and date the appropriate area of the form to confirm the policyholder’s completion of a checklist task. SuperLife Insurance only incentivises the completion of this checklist without funding the scans or tests. 

The travel-based incentive program is designed to support the travel plans of policyholders, enabling them to spend and accumulate points across years to suit their unique schedules and reasons for travel. Surveys indicate that people who have entered retirement or have children are likely to increase the frequency of air travel when ticket prices decrease by just 20 pounds (AUD 38) (Davison & Ryley, 2013). Life insurance products are primarily aimed at these two demographics as the policyholder would require a beneficiary and will likely maintain a life insurance policy post-retirement. Additionally, the GDP per capita of the United Kingdom, in which the study was produced, is larger than that of Lumaria, suggesting that the economic response to discounted air travel in Lumaria may be more pronounced than that in the survey. Consequently, the program's flexibility and the reward system's relevance would produce a compelling incentive to encourage participation in this program. 

**Partnership**

The criteria upon which the Lumarian Airline will be selected include having a positive reputation, reasonable environmental awareness and an intention to expand its customer base. The joint venture will encourage current SuperLife policyholders to use the selected Airline as the checklist program exclusively awards travel points to this Airline. Through this, SuperLife Insurance will provide marketing for the Airline and additional customers and revenue. In exchange, the two partner companies will share the expenses incurred from the travel points.

**Evaluation**

Short-term evaluations will occur in 3-5 years. This will provide sufficient time for mortality reductions, through early disease detection, to occur and enable awareness of the program, through word-of-mouth and media outlets, to contribute towards a higher customer base for SuperLife Insurance. Long-term evaluations will occur in 5-10 years. This period was selected to facilitate the observation of trends in mortality data as well as the risk profile and rate of new policyholders.

## Pricing/Costs

**Death Benefits (DB) calculation**

An important part of finding the profit for each year is to find the death benefit for that particular year. In this case, prediction is more important than inference, but the latter is still always useful to have to communicate to managers and stakeholders how the result was obtained. Note that whilst the current year may be 2024, that does not matter because the most recent data available is up to and including 2023 only. Hence there is no randomness in calculating DB for 2023, but there is for 2024 onwards due to the uncertainty of the future lifetimes. The total death benefits (DB) (aggregating all policyholders who are still in force) in a particular year T is given by

<img width="893" alt="Screenshot 2024-04-07 at 10 57 07 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/0370a8e7-72d9-4f7f-94c7-1f362e34b2f5">

From the in force data the face amounts of both policies are varying but are known for sure (deterministic). The randomness comes from the variables inside the indicator functions I(.) above. So to calculate profits, one needs DB. But since the latter is random, the best one can do is find its expected value E[DB] using machine learning (ML) techniques. For full details and maths derivations see Appendix 2.

**Economic Value**

The Present Value of Profit for each policy type is calculated by categorising our data into 4 different age groups 26 ~35, 36 ~ 45, 46 ~ 55, and 56 ~ 65 with different face amounts. Where the formula used to calculate is Pt – Ct – Et – CLt – CRt + It (Details for each case refer to appendix). Premiums, commission, reserve increase, and expenses are set by assumption. When the policyholder is integrated into the program, the mortality cost associated with the individual is reduced due to the decrease in mortality rate. Thus, PV of profit will decrease after the program is implemented if the mortality rate decreases the benefit claims.

Figure 3 (left) and Figure 4 (right) below

<img width="936" alt="Screenshot 2024-04-07 at 11 04 51 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/84137b83-caa8-456d-88d5-b11b132ad4f7">

For the T20 assurance above on the left (Figure 3), there are now less deaths within the 20 year term with the program compared to without. This is because with the predicted increase in health check ups, people have increased awareness and are able to detect possibly fatal diseases earlier. This leads them to act and seek medical intervention before the condition deteriorates. The biggest improvement is in the 46-55 age group, where the PV of profit jumps from 800 million Lumarian Crowns (LC) to 2400 million. 
For the SPWL assurance on the top right (Figure 4), initially for the younger age group, the aggregate PV of profit is more or less similar pre and post program. As younger Lumarians are more healthy and have lower hazard rates than older ones (all else equal), health checks usually would reveal no fatal diseases at that point in time. So the program would not do much to decrease the mortality of younger people. The gap of improvement for the 3 older age groups seems to be around the same, with a 1.15 billion extra PV profit after program implementation. This means that those health checks really do help older generations detect and combat diseases early, meaning on average they die later leading to lower PV of death benefit.

**Mortality Savings**

Mortality Savings are calculated by the differences between PV of Profit before the program was implemented and after. The graph below on the left (Figure 5) below clearly shows that the 20-year term insurance mortality savings increased across older age groups. However, for the SPWL insurance on the bottom right (Figure 6), the mortality saving is decreasing then spiking at age group 46-55 and then decreasing once again. Although the program being implemented does have a positive effect on the mortality savings as demonstrated by the positive magnitudes, it does not seem to be as effective as the 20-year term. 

Figure 5 (left) and Figure 6 (right) below

<img width="929" alt="Screenshot 2024-04-07 at 11 05 25 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/cae92be9-d054-4ac2-9fe3-03d32387d086">

**Pricing Changes**

Implementing a dynamic pricing model to adjust prices based on real-time changes in various factors such as age group, mortality savings, economic value, and market conditions can be an ideal method in optimising sales.For instance,  adjusting prices to attract customers in age brackets where mortality savings are higher, SuperLife can effectively capitalise on the marketability of these policies. This can be done by offering more competitive premiums for younger age groups, where mortality savings are typically lower, can incentivise customers to purchase policies, thereby optimising sales and profitability.

## Risk and Risk Mitigation 

**Risks**

In the case of implementing a health program and partnering with a chosen airline, an RDC categorisation method was used to classify the risks.

<img width="361" alt="Screenshot 2024-04-07 at 11 47 33 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/86cf144a-6843-4472-a0c7-d2f2eb814e96">


**Key Risk Mitigation Strategies**

**Fraudulence Risk:**

Make the checklist short and beneficial, thereby discouraging fraud. Conduct randomized audits where policyholders will be asked to provide proof of the consultation with the healthcare provider who signed the document.

**Economic Risk:**

It is highly unlikely that the interest rate will rise significantly all of a sudden, with an estimated probability of 2% that the annual rate would rise over 10%. The 97.5% Value-at-Risk was tested on the discount rate, and the profit margins for all insurance products after our program was implemented are positive, and higher than if our program was never implemented. 
	To further mitigate such risks, the investment strategy of premiums and/or other cash received needs to be adjusted, such as diversifying invested assets or investing into inflation-protected assets. 
	Conducting situational planning and doing regular stress testing exercises to assess the impact of different inflation scenarios on the financial performance of the insurance products and the overall business. SuperLife can develop multiple contingency plans and risk management strategies to mitigate the risk.

**Market Risk:**
	Doing adequate market research to identify potential target demographics, market trends, and competitor strategies. This includes analysing customer preferences, customer demands and regulatory considerations to ensure the program aligns with the market’s needs.
	Adopting an efficient and versatile approach in program designing and implementation; this allows for flexibility and adaptation based on market feedback and changing dynamics. Potential mitigation examples could include incorporating feedback loops, pilot testing, and iterative improvements to optimise program effectiveness and again aligning with the market’s needs.
	Using numerous marketing strategies to enhance program visibility and attract a broader customer base. This may involve using various channels such as digital marketing, social media, television advertising, and the strategic partnership with the Lumarian airline.

**Technology Risk:**

* Implementing a system for the continuous monitoring of technological advancements, cybersecurity threats, and industry innovations. This could include the regular update of the systems, software, and infrastructure supporting the health incentive program

* Implementing strict access controls and data encryption practices to safeguard sensitive information collected throughout the program. 

* Providing training to employees on cybersecurity best practices to minimise the risk of human error leading to vulnerabilities and malpractices.


**Sensitivity Analysis**

In order to test whether assumptions may be too unrealistic, sensitivity analysis is performed on discount (interest) rates, expenses, and percentage increase/decrease in new customers. 


**Interest/Discount Rates**

Discount rates ranging close to the assumed rate (2% - 5%) and 97.5% VaR (upper tail) are tested for both the whole life and 20-year insurance product. Test results show that compared to 20-year term insurance, the profitability of whole life insurance is more sensitive to interest rate changes. 
Additionally, insurance for older age groups generally is more sensitive to price change than younger age group due to a worse mortality. However, for each insurance product sold, the new program is able to generate a higher profit margin for all tested interest rates. 

Figure 7 below

<img width="388" alt="Screenshot 2024-04-07 at 11 12 10 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/2c65b140-c84d-48e7-8915-06a87daea367">

As seen above (Figure 7), regardless of interest rate and age group, the new product for whole life insurance is able to generate a higher profit margin. Moreover, the profit margin roughly forms a linear relationship as interest rates increase. The profit margin of the new program remains positive as long as interest rate is above 3%, which has more than 85% possibility of happening. So in other words, the degree of certainty that our proposed program can generate a positive profit and exceed profit without proposed program is greater than 85%.

**Expenses**

In the hypothetical scenario that the budgeted expense per policy year is too little for each policy sold, a test was run on 1.5 times and 2 times the original expense respectively. The insurance products for the 26-35 age group is presented below (see other age groups in appendix). 

Figure 8 (left) and Figure 9 (right) below

<img width="911" alt="Screenshot 2024-04-07 at 11 06 40 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/79f803dc-7ae6-4fd9-b04b-d54dabf915cd">

The graphs show that when multiplying the assumed annual expense by 1.5, the impact is minimal in SPWL, as well as the T20 for higher face values. However this impact is catastrophic for the 100,000 and 50,000 face value policies as it may cause a significantly lower, or even a negative profit margin. The impact on whole life insurance with other age groups are not as drastic as shown in Figure 9, but for both 36-45 and 46-55 age groups, profit margin less than halved when annual expenses are doubled. Thus, if expenses are indeed underestimated, the pricing solution would need to be re-evaluated. 

**Potential Decrease in New Customers**

There is a relatively high chance of attracting new customers with our new product as it does improve mortality, however, due to potential strategic risk, there is a chance for the company to lose customers. After testing, even if the amount of policyholders dropped by 67% for 20-year term insurance and 32% for whole life insurance, the newly implemented program is still able to generate similar profits as before the program was implemented. However, 
If customers rise by 10%, the profit gap between the new and old program increases by 14% for the 20-year term insurance and 30% for the whole life insurance.
If customers rise by 25%, the profit gap between the new and old program increases by 37% for the 20-year term insurance and 73% for the whole life insurance.
In other words, any increase in customers can magnify the difference in profit between the new program and the old program. 



## Assumptions

**Modelling**

That insurers do not wrongly classify deaths as lapses in T20 premiums. Sometimes in life insurance, the policyholder dies but no one reports the event to the life insurer. This usually occurs when that person is living by themselves with no close family or friends. For simplicity that event is excluded here. So when someone lapses, they are alive at that time. Further when they lapse they are no longer eligible for death benefit (DB), hence data is no longer collected on them

Ages and years are treated as discrete variables for modelling. Of course theoretically one can have fractional years (for example 0.5 years), but monthly and daily data are not given in the dataset anyways. For instance if someone is alive during 2023, then assume they are alive for the entire year.

**Program Cost**

Lumaria has a universal healthcare system. Similar to other countries with a universal healthcare system, such as Australia and Canada, it is assumed that Lumarian health check-ups including blood pressure readings, cholesterol level tests and age-specific preventative scans, are provided without upfront fees. 

The travel points expense is only incurred once the policyholder completes the checklist and earns the reward. Therefore, the participation rate in the checklist program impacts the total expenses for SuperLife insurance. Travel is assumed to be an appropriate incentive for all ages, hence the willingness to complete the health check-ups will determine the participation rate in the program. The checklist participation rate was informed by the participation rate in Australian government-funded cancer screening programs, namely bowel cancer, breast cancer and cervical cancer. Similar to Lumaria’s health care, these programs were free, focused on early disease detection and were reasonably marketed as this program would be among SuperLife policyholders. The underlying trend in the data indicated increased participation with age, which was replicated in the assumed participation rate for the checklist program. Additionally, the participation rates for the screening programs were roughly increased by a factor of 0.3 to account for the incentivised nature of the checklist program and adjusted to a more linear trend for ease of use. 

**Pricing**

* Investment return used to calculate the present value of profit is 4% higher than the interest rate for 20-year term Insurance and 5% higher for Single Whole Life Insurance (SPWL). The reason that SPWL Insurance investment rate is higher is that it invested in a longer period thus higher return

* Premiums are calculated by setting the pre-program profit margin to be 5%

* Commissions are assumed to be 80% of the premium for duration 1 and 2% afterward

* Pre-programme expenses are assumed to be 200 Crowns for duration 1 and 25 Crowns afterwards

* Post-Programme Expenses are assumed to be 200 + expenses load*80 Crowns for duration 1 and 25 Crowns afterwards. Where the expense load is the probability that the age group policyholder will finish the checklist is 50% for the age group 26-35,  60% for the age group 36-45, 70% for the age group 46-55, and 85% for the age group 56-65

* Premium, commission, reserve increase and interest are assumed to be constant across pre and post program implementation

* The effect of two interventions on mortality are assumed to be independent. 

**EXTERNAL DATA AND DATA LIMITATIONS**

Additional Data Used 
Participation rate data for Australian government-funded cancer screening programs was used to determine the probability that policyholders will complete the health checklist. This data was from the Australian Institute of Health and Welfare (AIHW). This was incorporated in the calculation of the expenses of the program. 

**Data Limitations**

The Lumaria mortality table is provided according to integer ages only. Policyholders of all sexes, smoke status, and regions are aggregated together. This makes it really difficult to perform data analysis because one cannot differentiate if mortality rate is different between males and females, smokers and non-smokers, and so on.




**Appendix**

For the R code and Excel spreadsheets used in the analysis, please see those files in GitHub classroom. Generative AI was not used in this assignment.

<img width="907" alt="Screenshot 2024-04-07 at 11 08 36 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/345af4af-bb08-4f17-9c6a-edbb24e41cd5">

 

From the frequency barplot of each cause of death above (Figure 10), over from 2001-2023, the most common cause of death (given that it occurred) with 13,000 counts is C00-D48 (neoplasms). The second most frequent one is I00-I99 (circulatory system diseases) with 12,000 cases. Interestingly enough, the O00-O99 that kills people at younger ages (mentioned at the very start in the main report), is the rarest disease.

<img width="926" alt="Screenshot 2024-04-07 at 11 09 57 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/e544737d-8c93-4918-9a9d-5fe57f6e28d9">



From the frequency histogram above (Figure 11), the most popular issue ages of life policy are 38-42 and 50-54 age groups. Intuitively, this could be due to the so-called “mid-life crisis” phenomenon, where illnesses come more frequently than before when they were younger. Up until age 37 the rate of issues increases quite steadily (like an increasing step function). And from age 55 onwards it decreases quite steadily too (decreasing step function). If a straight vertical line were drawn at age 46, this histogram looks almost symmetrical.

 <img width="882" alt="Screenshot 2024-04-07 at 11 10 10 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/87927d5d-8d29-4fb9-975f-cb9bb76b77f2">

From Figure 12, this shows the mortality rate (curve) increasing at an increasing rate as people grow older. This is a typical convex curve used to model human mortality. Notice how the graduated smooth curve fits nicely over the plotted points, with the exception of the outlier at age 120 (maximum age where everyone must die before).


2) **Modelling Death Benefits (DB) Using Survival Analysis Regression**
   
To model the expected death benefit E[DB], survival analysis regression was performed to predict the response Y = years before death = Year of Death (YoD) - Issue year. Importantly, notice how years before death and YoD are two different quantities (eventhough they sound the same).

Where issue year is defined to be the start time (at time t = 0), and YoD is the end time (as usual in life insurance settings). The issue year varies among observations, but that does not matter as only the duration of time elapsed matters here. Since from the mortality data, the maximum age is 120 (with 100% mortality).

<img width="701" alt="Screenshot 2024-04-07 at 11 13 30 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/98bffb9d-e900-4ad7-b54c-43c51ef445a1">


<img width="726" alt="Screenshot 2024-04-07 at 11 14 23 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/fa3f4a31-4f75-4b15-b578-52c6e8cabe93">

**Why Interval censored data but not right censored?**

Usually in life insurance, there are right censored people who have the response values ranging from Y ∈ [Issue year+1,+∞). This is only if they assume that there is no theoretical maximum age (or no upper bound). However, from the in force data that is not the case because from above the maximum age is 120 years. Also there is no left censoring/truncation, nor right censored observations in in force data.


**Model Selection**

The in force data was split into 75% training and validation (for model selection and hyperparameter tuning), and 25% testing (for model assessment on unseen data). This was done via random shuffling and sampling to ensure that the training/validation/test distribution’s are as empirically similar as possible. Ultimately the “best” predictive model would be selected based on its ability to generalise on new data. Survival analysis is a very “special” type of regression, because the response years before death are interval censored for some rows. Hence, traditional regression metrics like RMSE and MAE are unsuitable because they rely on having a single number for observed Y. The first way is to find the negative log likelihood for each model on the validation data (this is equivalent to maximising the log likelihood function). So in this case the lower the better. Similarly, the second method is to compute the Uno’s C-index (lies between 0 and 1) for each model, and in this case the higher the better. Where c = 0.5 is the expected performance from pure random guessing.



**Nested 8-Fold Cross Validation (CV)**

Importantly, it is very important throughout this whole process to leave the test set untouched (until the very end) to prevent overly-optimistic predictions (information leakage into test data). 

In the first step (inner loop), the hyperparameters above are tuned, and 8 estimates of the NLL and 8 UCI’s are obtained for each model and averaged to obtain CV measures. Then choose the optimal hyperparameters (via grid searching) for each model so that NLL is minimised, and UCI is maximised. 

In the next step (outer loop), construct a new training set made up of the above so that new train = old train + old validation set. Recall that is 75% of the in force data is (new train + new validation) = old train + old validation + new validation. Obtain the NLL and UCI for each model (each with its own set of optimal hyperparameters). Then finally, pick the best/winner model with the lowest NLL and/or highest Uno’s C-index.


<img width="589" alt="Screenshot 2024-04-07 at 11 33 12 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/24135940-e9af-43b7-a93d-1a4fe8c65dd4">


Importantly, a model with the highest UCI tends to give good predicted rankings of death, but not necessarily good predicted death times. It does not care about their actual/observed times, but rather the order in which they happened (scale and shift invariant). This could be problematic in calculating DB, because for that you need to predict in which particular year they died in. So NLL is a more important metric in this case, and UCI is only used as a tiebreaker if the models have the same NLL.

From above, notice how XGboost with AFT (normally distributed noise) gives the lowest NLL and highest UCI on the new validation set (which directly estimates test error). Hence, XGboost (winner or best model) is expected to give the best performance in predicting both the YoD (by NLL) and the order in which it happens among policyholders (by UCI).


**Feature Selection and Model Assessment on XGboost with AFT (normally distributed noise)**

Feature selection is performed to remove variables with low importance in XGboost, keeping only the top 3 most important predictors. Importance is measured using gain, which is the average loss reduction gained when using a feature for splitting. These are in descending order issue age, online distribution channel, and face amount.
Finally, model assessment is performed on the test set (untouched before this!) to obtain generalisation error. This gives a final NLL = 6.505×10^(-5).

**XGboost with Accelerated Failure Time (AFT) model**

For prediction, generally more complex models perform better than the simpler ones (all else equal). Hence XGboost (extreme gradient boosting)  is used as an extension of GBM (gradient boosting machine), in which trees are grown sequentially on the residuals (or weaknesses) of the previous tree. AFT is commonly used in survival analysis and so used here. The general equation is

<img width="863" alt="Screenshot 2024-04-07 at 11 17 22 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/8bf2ba0b-8521-416a-b790-0019946866c9">




Intuitively, Z represents the random noise that pulls the predictions away from the true ln(Y). To incorporate XGboost into the AFT framework, the dot product (w,x) is replaced with a transformation (or mapping) x →T(x). Where T(x) is the output from a decision tree ensemble. The equation now becomes 

<img width="220" alt="Screenshot 2024-04-07 at 11 40 23 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/33b15e7f-ec4b-4662-b220-5aa8726b81a5">



 The objective is to find a good T(x) so that it maximises the likelihood function (or equivalently log-likelihood) of Z. Said otherwise, it is to minimise the negative log-likelihood function which was implemented. So the lower the metric the better. 


3) **Further Pricing Details and Formulas**
   
Cash flow for the year t CFt ,  reserve increase for that year CRt and interest accumulated  It . The cash flow CFt can be further broken down into different parts which include premium Pt, commission Ct, expenses Et , claims CLt .

<img width="732" alt="Screenshot 2024-04-07 at 11 18 33 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/9307cdf2-8da7-4e41-8346-839ebb0c3616">


<img width="947" alt="Screenshot 2024-04-07 at 11 34 13 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/3da9defc-c63e-411d-8d45-3f16eb1a0030">


With both expenses and claims being respectively loaded to account for the programme implementation.

 <img width="809" alt="Screenshot 2024-04-07 at 11 20 25 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/bfd75e0a-cb21-4dc4-9a9c-c5653364f8ab">

<img width="532" alt="Screenshot 2024-04-07 at 11 21 01 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/63b060a7-8fd1-4d5a-8f55-5929142f7a97">

 
 

4) Expense sensitivity analysis additional graphs
   
 <img width="354" alt="Screenshot 2024-04-07 at 11 21 45 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/44ca3cd3-8176-441d-89b4-020bb46736c1">

 
 <img width="309" alt="Screenshot 2024-04-07 at 11 21 56 pm" src="https://github.com/Actuarial-Control-Cycle-T1-2024/group-page-showcase-cc24/assets/68623529/9b7c6b31-6e6a-4bc3-818e-163432e55cc0">

 

**Harvard Style Reference List**

1) Australian Institute of Health and Welfare (AIHW) 2023, Cancer screening programs: quarterly data, viewed 24 March 2024, <https://www.aihw.gov.au/reports/cancer-screening/national-cancer-screening-programs-participation>







