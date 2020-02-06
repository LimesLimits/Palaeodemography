; Model name: BatavianDemographyRecruitment v4.nlogo
; Version: 4 (27 Nov 2018)
; Author: Philip Verhagen (VU University Amsterdam, Faculty of Humanities)

; This model is an appendix to the paper
; Verhagen, P. 2019. 'Modelling the dynamics of demography in the Dutch limes zone' in: Verhagen, P., J. Joyce & M.R. Groenhuijzen (eds) Finding the limits of the limes. Modelling economy, demography and transport on the edge of the Roman Empire'. Springer, New York.

; list of global variables
; [n-deaths] number of deaths per tick/year (an integer number)
; [f-deaths] number of adult female deaths per year (an integer number)
; [sum-age-at-death] the summed age of all humans who died (an integer number)
; [sum-n-children-at-death] the sum of the number of children per deceased adult female per year (an integer number)
; [sum-n-spouses-at-death] the sum of the number of spouses per deceased adult female per year (an integer number)
; [n-spinsters-at-death] the number of deceased adult females that never married in a year (an integer number)
; [sum-n-spinsters-at-death] the total number of deceased adult females that never married (an integer number)
; [n-children-per-female] the number of children per deceased adult female per year (an integer number)
; [n-spouses-per-female] the number of spouses per deceased adult female per year (an integer number)
; [sum-n-children-per-female] total number of children per deceased adult female over all runs (an integer number)
; [sum-n-spouses-per-female] total number of spouses per deceased adult female over all runs (an integer number)
; [n-born] the number of children born per year (an integer number)
; [disease-mortality] mortality multiplier because of disease (a floeating point number)
; [disease-recurrence] the return period of a disease (an integer number)
; [disease-year] determines whether the current year is a disease year (an integer number)
; [f-marriage-age] determines the minimum age of marriage for femalies (an integer number)
; [marriage-time-scale-factor] the compression of the time scale of first marriage, compared to Coale's (1971) standard scheme (a floating point number)
; [marriage-age-difference] determines the minimum allowed age difference between spouses (an integer number, positive numbers indicate that the male is older than the female)
; [fertility-rate-modifier] reduces the fertility rate (a floating point number)
; [stopping-behaviour] sets the maximum number of children to be born to a female (an integer number)
; [available-partners] sets the maximum number of males available for marriage

globals [n-deaths f-deaths sum-age-at-death sum-marriage-age-at-death sum-n-children-at-death sum-n-spouses-at-death n-spinsters-at-death sum-n-spinsters-at-death n-children-per-female n-spouses-per-female sum-n-children-per-female sum-n-spouses-per-female n-born disease-year]

; list of agent-sets
; [humans] are agents representing a single human
; [households] are agents representing a single household, containing a certain number of humans

breed [humans human]
breed [households household]

; attributes for the agent-set 'humans':
; [age] records the age of each human in number of years (an integer number; = number of ticks)
; [is-dead] records if the human is dead or not (a binary number 0/1)
; [dying-age] sets the dying age of each human (an integer number)
; [gender] records the gender of each human (a string; options are "F" (female) or "M" (male))
; [fertility] records the fertility rate of a female human (a floating point number between 0.0 and 1.0)
; [recruit] records the number of years that a recruited male human has served in the army (an integer number)
; [widowed] records whether the human is widowed (a binary number 0/1)
; [n-spouses] number of spouses (an integer number)
; [n-children] records the number of children born to a human (an integer number)
; [n-children-alive] records the number of children born and alive to a human (an integer number)
; [my-household] records the household of the human (a single agent from the agent-set households)
; [my-mother] records the mother of the human (a single agent)
; [my-father] records the father of the human (a single agent)
; [my-spouse] records the spouse of the human (a single agent; can be no-one)

humans-own [age dying-age is-dead gender fertility recruit widowed n-spouses n-children n-children-alive my-household my-mother my-father my-spouse]

; attributes for the agent-set 'households':
; [household-members] records the agents who form part of the households (a number of agents from the agent-set humans)

households-own [household-members]

to setup

; setup creates a base set of 200 humans
; first, the ages of the humans are determined in the procedure 'to age-determination', and are taken from the life table chosen in the graphical interface
; (see 'to-report mortality' for details on the life tables)

; then, all females over [f-marriage-age] will be coupled to a spouse of the right age bracket (when available) and they will form a household
; humans who are not married will be distributed at random over the households; this is not a realistic assumption, but is done for quick model initialisation
; for the same reason, there are in this stage no widows and no recruits, and [n-children] equals 0

  ca

  create-humans 200
  [

    ; determination of the biological sex of each human, with a 50% chance of them being either male of female

;    ifelse random-float 1 < 0.5
;     [ set gender "M" ]
;     [ set gender "F" ]

    ; adaptation to reflect 'natural sex ratio' of 105:100 M:F (see Bagnall & Frier 1994:95)

    ifelse random-float 1 < 0.5125
     [ set gender "M" ]
     [ set gender "F" ]

    ; determination of the age of each human is done in the module age-determination

    age-determination

    ; the value of the variables [is-dead], [widowed], [n-spouses], [recruit], [n-children], [n-children-alive] and [my-household] are set to 0

    set is-dead 0
    set widowed 0
    set n-spouses 0
    set recruit 0
    set n-children 0
    set n-children-alive 0
    set my-household 0

  ]

  ; mother and father are assigned randomly; this is not important for the initialization

  ask humans
  [
    set my-mother one-of humans with [gender = "F"]
    set my-father one-of humans with [gender = "M"]
  ]

  ask humans with [gender = "F" and age >= f-marriage-age]

  ; all females over [f-marriage-age] are coupled to a spouse, if available; there should be roughly between 35 and 55 females of this age in the initial sample
  ; this procedure should result in less households than the number of marriageable females, depending on [marriage-age-difference]

  [
    ; a male is eligible as a husband when he is [marriage-age-difference] years older than the female, but no more than 15 years - this slightly offsets the couple ages from the rules applied later in the marriage module!

    let f-age age
    let husband one-of humans with [gender = "M" and my-spouse = 0 and age - f-age >= marriage-age-difference and age - f-age < 16]

    ; if a husband is found, he is coupled to the female, and vice versa

    if husband != nobody
    [
      set my-spouse husband
      set n-spouses 1

      ask husband [
        set n-spouses 1
        set my-spouse myself
      ]

      ; the couple (a temporary agent-set) then will 'hatch' a new household, which only consists of the couple itself

      let couple (turtle-set self husband)

      hatch-households 1
      [
        set household-members couple
        ask couple
        [
          set my-household myself
        ]
      ]
    ]
  ]

  ask humans with [my-household = 0]

  ; those humans who could not be married are now added to a random household; this is not realistic, but serves for initialisation purposes

  [
    ask one-of households [
      set household-members (turtle-set household-members myself)
      ask myself [
        set my-household myself]
    ]
  ]

  ; the global variables are now all initialized to 0

  set n-deaths 0
  set f-deaths 0
  set sum-age-at-death 0
  set sum-marriage-age-at-death 0
  set sum-n-children-at-death 0
  set sum-n-spouses-at-death 0
  set n-spinsters-at-death 0
  set sum-n-spinsters-at-death 0
  set n-children-per-female 0
  set n-spouses-per-female 0
  set sum-n-children-per-female 0
  set sum-n-spouses-per-female 0
  set disease-year 1

  reset-ticks

end

to go

; the model is run in four consecutive steps, executing the procedures 'to reproducing', 'to dying', 'to recruiting' and 'to marrying'
; each tick represents one year
; the order of execution implies that the steps are taken consecutively for the whole agentset of humans, so not for one human at a time
; 1 - it is determined which new humans will be hatched this year
; 2 - it is determined which humans will die this year
; 3 - it is determined which males in age 18-25 will be recruited for military service this year (making them unavailable as spouses)
; 4 - it is determined which females will marry this year

  reproducing

  dying

  recruiting

  marrying

  tick

; collect all necessary information for display at the end of each tick; collecting totals will only start at tick 100

  if f-deaths > 0 [
   set n-children-per-female sum-n-children-at-death / f-deaths
   set n-spouses-per-female sum-n-spouses-at-death / f-deaths
   if ticks > 99
    [
      set sum-n-children-per-female sum-n-children-per-female + n-children-per-female
      set sum-n-spouses-per-female sum-n-spouses-per-female + n-spouses-per-female
      set sum-n-spinsters-at-death sum-n-spinsters-at-death + n-spinsters-at-death
    ]
  ]

  ; the model will stop after 200 ticks/years

  if ticks = 201 [

    print sum-n-children-per-female / 100
    print sum-n-spouses-per-female / 100
    print sum-n-spinsters-at-death / 100
    stop

  ]

; reset all 'annual' global variables for the next tick

  set n-deaths 0
  set f-deaths 0
  set sum-age-at-death 0
  set sum-n-children-at-death 0
  set sum-n-spouses-at-death 0
  set n-spinsters-at-death 0
  ifelse disease-year = disease-recurrence
   [set disease-year 0 ]
   [set disease-year (disease-year + 1)]

end

to age-determination

; determine the age structure of the initial population
; for each human, an age is attributed according to the following rules:
; the probability of having an age in a 5-year cohort is determined on the basis
; of the life table selected at set up (see 'to-report mortality' for more details)
; the age within the 5-year cohort is then determined at random, so a human
; in the age cohort 25-29 years will have an equal (20%) chance of being either 25, 26, 27, 28 or 29 years old

   ask humans
   [
     let a-number random-float 1

     if Life_table = "West 3 Female"[

      if a-number < 0.1472
      [ set age 0 ]
      if a-number >= 0.1472 and a-number < 0.2900
      [ set age random 4 + 1 ]
      if a-number >= 0.2900 and a-number < 0.4190
      [ set age random 5 + 5 ]
      if a-number >= 0.4190 and a-number < 0.5319
      [ set age random 5 + 10 ]
      if a-number >= 0.5319 and a-number < 0.6294
      [ set age random 5 + 15 ]
      if a-number >= 0.6294 and a-number < 0.7124
      [ set age random 5 + 20 ]
      if a-number >= 0.7124 and a-number < 0.7821
      [ set age random 5 + 25 ]
      if a-number >= 0.7821 and a-number < 0.8396
      [ set age random 5 + 30 ]
      if a-number >= 0.8396 and a-number < 0.8860
      [ set age random 5 + 35 ]
      if a-number >= 0.8860 and a-number < 0.9226
      [ set age random 5 + 40 ]
      if a-number >= 0.9226 and a-number < 0.9505
      [ set age random 5 + 45 ]
      if a-number >= 0.9505 and a-number < 0.9707
      [ set age random 5 + 50 ]
      if a-number >= 0.9707 and a-number < 0.9843
      [ set age random 5 + 55 ]
      if a-number >= 0.9843 and a-number < 0.9926
      [ set age random 5 + 60 ]
      if a-number >= 0.9926 and a-number < 0.9971
      [ set age random 5 + 65 ]
      if a-number >= 0.9971 and a-number < 0.9991
      [ set age random 5 + 70 ]
      if a-number >= 0.9991 and a-number < 0.9998
      [ set age random 5 + 75 ]
      if a-number >= 0.9998 and a-number < 0.99998
      [ set age random 5 + 80 ]
      if a-number >= 0.99998
      [ set age random 10 + 85 ]

     ]

     if Life_table = "Pre-industrial Standard"[

      if a-number < 0.1346
      [ set age 0 ]
      if a-number >= 0.1346 and a-number < 0.2661
      [ set age random 4 + 1 ]
      if a-number >= 0.2661 and a-number < 0.3867
      [ set age random 5 + 5 ]
      if a-number >= 0.3867 and a-number < 0.4945
      [ set age random 5 + 10 ]
      if a-number >= 0.3867 and a-number < 0.4945
      [ set age random 5 + 15 ]
      if a-number >= 0.4945 and a-number < 0.5899
      [ set age random 5 + 20 ]
      if a-number >= 0.5899 and a-number < 0.6732
      [ set age random 5 + 25 ]
      if a-number >= 0.6732 and a-number < 0.7452
      [ set age random 5 + 30 ]
      if a-number >= 0.7452 and a-number < 0.8063
      [ set age random 5 + 35 ]
      if a-number >= 0.8063 and a-number < 0.8573
      [ set age random 5 + 40 ]
      if a-number >= 0.8573 and a-number < 0.8988
      [ set age random 5 + 45 ]
      if a-number >= 0.8988 and a-number < 0.9316
      [ set age random 5 + 50 ]
      if a-number >= 0.9316 and a-number < 0.9565
      [ set age random 5 + 55 ]
      if a-number >= 0.9565 and a-number < 0.9744
      [ set age random 5 + 60 ]
      if a-number >= 0.9744 and a-number < 0.9864
      [ set age random 5 + 65 ]
      if a-number >= 0.9864 and a-number < 0.9936
      [ set age random 5 + 70 ]
      if a-number >= 0.9936 and a-number < 0.9991
      [ set age random 5 + 75 ]
      if a-number >= 0.9991 and a-number < 0.9997
      [ set age random 5 + 80 ]
      if a-number >= 0.9997
      [ set age random 10 + 85 ]

     ]

     if Life_table = "Woods 2007 South 25"[

      if a-number < 0.1547
      [ set age 0 ]
      if a-number >= 0.1547 and a-number < 0.3046
      [ set age random 4 + 1 ]
      if a-number >= 0.3046 and a-number < 0.4389
      [ set age random 5 + 5 ]
      if a-number >= 0.4389 and a-number < 0.5547
      [ set age random 5 + 10 ]
      if a-number >= 0.5547 and a-number < 0.6528
      [ set age random 5 + 15 ]
      if a-number >= 0.6528 and a-number < 0.7345
      [ set age random 5 + 20 ]
      if a-number >= 0.7345 and a-number < 0.8015
      [ set age random 5 + 25 ]
      if a-number >= 0.8015 and a-number < 0.8557
      [ set age random 5 + 30 ]
      if a-number >= 0.8557 and a-number < 0.8987
      [ set age random 5 + 35 ]
      if a-number >= 0.8987 and a-number < 0.9320
      [ set age random 5 + 40 ]
      if a-number >= 0.9320 and a-number < 0.9571
      [ set age random 5 + 45 ]
      if a-number >= 0.9571 and a-number < 0.9750
      [ set age random 5 + 50 ]
      if a-number >= 0.9750 and a-number < 0.9870
      [ set age random 5 + 55 ]
      if a-number >= 0.9870 and a-number < 0.9943
      [ set age random 5 + 60 ]
      if a-number >= 0.9943 and a-number < 0.9979
      [ set age random 5 + 65 ]
      if a-number >= 0.9979 and a-number < 0.9994
      [ set age random 5 + 70 ]
      if a-number >= 0.9994 and a-number < 0.9999
      [ set age random 5 + 75 ]
      if a-number >= 0.9999 and a-number < 0.999996
      [ set age random 5 + 80 ]
      if a-number >= 0.999996
      [ set age random 10 + 85 ]

     ]

     if Life_table = "Egypt (Bagnall & Frier 1994)" and gender = "M" [

       ; this is actually the same as Coale & Demeny's Model West Level 4 males

      if a-number < 0.32257
      [ set age 0 ]
      if a-number >= 0.32257 and a-number < 0.45483
      [ set age random 4 + 1 ]
      if a-number >= 0.45483 and a-number < 0.48268
      [ set age random 5 + 5 ]
      if a-number >= 0.48268 and a-number < 0.50197
      [ set age random 5 + 10 ]
      if a-number >= 0.50197 and a-number < 0.52696
      [ set age random 5 + 15 ]
      if a-number >= 0.52696 and a-number < 0.56059
      [ set age random 5 + 20 ]
      if a-number >= 0.56059 and a-number < 0.59553
      [ set age random 5 + 25 ]
      if a-number >= 0.59553 and a-number < 0.63264
      [ set age random 5 + 30 ]
      if a-number >= 0.63264 and a-number < 0.67198
      [ set age random 5 + 35 ]
      if a-number >= 0.67198 and a-number < 0.71409
      [ set age random 5 + 40 ]
      if a-number >= 0.71409 and a-number < 0.75627
      [ set age random 5 + 45 ]
      if a-number >= 0.75627 and a-number < 0.80108
      [ set age random 5 + 50 ]
      if a-number >= 0.80108 and a-number < 0.84489
      [ set age random 5 + 55 ]
      if a-number >= 0.84489 and a-number < 0.88996
      [ set age random 5 + 60 ]
      if a-number >= 0.88996 and a-number < 0.93081
      [ set age random 5 + 65 ]
      if a-number >= 0.93081 and a-number < 0.96408
      [ set age random 5 + 70 ]
      if a-number >= 0.96408 and a-number < 0.98649
      [ set age random 5 + 75 ]
      if a-number >= 0.98649 and a-number < 0.99654
      [ set age random 5 + 80 ]
      if a-number >= 0.99654
      [ set age random 10 + 85 ]

     ]

      if Life_table = "Egypt (Bagnall & Frier 1994)" and gender = "F" [

       ; this is actually Model West Level 2 females

      if a-number < 0.33399
      [ set age 0 ]
      if a-number >= 0.33399 and a-number < 0.49224
      [ set age random 4 + 1]
      if a-number >= 0.49224 and a-number < 0.52604
      [ set age random 5 + 5 ]
      if a-number >= 0.52604 and a-number < 0.5507
      [ set age random 5 + 10 ]
      if a-number >= 0.5507 and a-number < 0.58101
      [ set age random 5 + 15 ]
      if a-number >= 0.58101 and a-number < 0.61614
      [ set age random 5 + 20 ]
      if a-number >= 0.61614 and a-number < 0.6521
      [ set age random 5 + 25 ]
      if a-number >= 0.6521 and a-number < 0.68883
      [ set age random 5 + 30 ]
      if a-number >= 0.68883 and a-number < 0.72465
      [ set age random 5 + 35 ]
      if a-number >= 0.72465 and a-number < 0.75832
      [ set age random 5 + 40 ]
      if a-number >= 0.75832 and a-number < 0.78966
      [ set age random 5 + 45 ]
      if a-number >= 0.78966 and a-number < 0.8244
      [ set age random 5 + 50 ]
      if a-number >= 0.8244 and a-number < 0.86053
      [ set age random 5 + 55 ]
      if a-number >= 0.86053 and a-number < 0.90113
      [ set age random 5 + 60 ]
      if a-number >= 0.90113 and a-number < 0.93876
      [ set age random 5 + 65 ]
      if a-number >= 0.93876 and a-number < 0.96884
      [ set age random 5 + 70 ]
      if a-number >= 0.96884 and a-number < 0.9887
      [ set age random 5 + 75 ]
      if a-number >= 0.9887 and a-number < 0.99724
      [ set age random 5 + 80 ]
      if a-number >= 0.99724
      [ set age random 10 + 85 ]

     ]

   ]

end

to reproducing

  ; procedure to determine if any females reproduce
  ; this depends on whether the female is married and on her age; fertility ratios are determined in the procedure 'to report fertility-rate'

  ; first, set the number of newborns for this year to 0

  set n-born 0

  ; determine the fertility rate of all females for this year

  fertility-rate

  ; then determine for each married female whether she will give birth

  ask humans with [gender = "F" and my-spouse != 0 and is-dead = 0]
  [

    ; N.B. my-spouse is set to 0 when the spouse dies; the way the model is set up implies that spouses may die in the current year, but will still reproduce

    ; the fertility rate is a floating-point number between 0.0 and 1.0 determined in 'to-report fertility-rate', and is based on age and the true fertility estimates from Coale and Trussell (1978)
    ; for each married female, a random number will then determine whether she will become a mother
    ; the fertility rate modifier can be used to mimic the effect of lengthening the interval between births
    ; stopping behaviour prevents children from being born after a certain number of children have been born which have survived up to the current tick

    if random-float 1 < fertility * fertility-rate-modifier and n-children-alive <= stopping-behaviour

    [

      let mother self
      let father my-spouse

      hatch-humans 1 ; the possibility of having twins is not incorporated, as it is not clear how this relates to the fertility estimates used; see notes in info-section for details

      [

        ; hatched humans automatically inherit the attributes of their parents, so these should be adapted where necessary

        set age 0
        set my-spouse 0
        set fertility 0
        set n-spouses 0
        set n-children 0
        set n-children-alive 0
        set my-mother mother
        set my-father father

        if random-float 1 < 0.5125 ; the child's biological sex needs to be determined; since the child is produced by a female human, it will automatically be hatched with gender "F"
        [
          set gender "M"
        ]

        ; add the newborn to the household of its parents; the child will automatically be hatched with my-household of the mother

        ask my-household [
         set household-members (turtle-set household-members myself)
        ]
      ]

      ; update the count of newborns for this year

      set n-born n-born + 1

      ; update the count of children of the mother

      set n-children n-children + 1
      set n-children-alive n-children-alive + 1

      ; update the count of children of the father (this feature is not used for output in the current version of the model)

      ask humans with [my-spouse = myself]
      [
        set n-children n-children + 1
        set n-children-alive n-children-alive + 1
      ]
    ]
  ]

end

to dying

; procedure to determine which humans will die this year
; the risk of dying is determined on the basis of the model life table selected at setup
; the mortality regime can be adapted to catastrophic events by manipulating the [disease-mortality] and [disease-recurrence] in the interface; these could however also refer to other causes of increased mortality, such as famine or warfare
; statistics will be collected to determine the number of children left behind per adult female

  ask humans with [is-dead = 0]
  [

    ; the risk of dying for each human is a floating-point number between 0.0 and 1.0 determined in 'to-report mortality', and is based on age and the life table chosen at setup

     let risk-of-dying mortality

     ; if the current year is a 'disease year', adapt the mortality rate

    if disease-year = disease-recurrence
    [
      set risk-of-dying (mortality * disease-mortality)
    ]

    ; instead of setting the mortality and disease recurrency at equal levels over the whole of the model run, specific experiments could be carried out by adapting this piece of the code
    ; this is an example for an experiment trying to emulate the effects of the 'Antonine Plague'

;    if ticks = 100
;    [
;      set risk-of-dying (mortality * 2.5)
;    ]
;    if ticks = 104
;    [
;      set risk-of-dying (mortality * 2.0)
;    ]
;    if ticks = 110
;    [
;      set risk-of-dying (mortality * 1.5)
;    ]
;    if ticks = 113
;    [
;      set risk-of-dying (mortality * 2.5)
;    ]

    ; for each human, a random number will determine whether they will die
    ; the turtles will not really 'die', but [is-dead] will be set to 1 - the reason being that we need to collect data on the dead humans as well, and once they die in NetLogo they cannot be analysed anymore
    ; this obviously increases the number of agents, but it is easier than keeping track of everything through output to an external file

    if random-float 1 < risk-of-dying

    [

      set n-deaths n-deaths + 1 ; increase the number of humans who died by 1
      set sum-age-at-death sum-age-at-death + age ; get the sum of ages of humans who died

      if gender = "F" and age >= f-marriage-age [
        set f-deaths f-deaths + 1 ; increase the number of adult females who died by 1
        set sum-n-children-at-death sum-n-children-at-death + n-children ; get the sum of the number of offspring of adult females who died
        set sum-n-spouses-at-death sum-n-spouses-at-death + n-spouses ; get the sum of the number of spouses of adult females who died
        if n-spouses = 0 [set n-spinsters-at-death n-spinsters-at-death + 1] ; get the sum of the number of adult females who died without having married at least once
      ]

      ; the spouse, if applicable, will become widowed

      ask humans with [my-spouse = myself and is-dead = 0]
      [
        set my-spouse 0
        set widowed 1
      ]

      ; reset the count for children alive in the family

      ask my-mother
      [
        set n-children-alive n-children-alive - 1
      ]

      ask my-father
      [
        set n-children-alive n-children-alive - 1
      ]

      set dying-age age
      set is-dead 1

    ]

    ; for those humans who did not die, increase age by 1 year/tick

    set age age + 1

  ]

end

to recruiting

  ; this procedures determines whether unmarried males between 18 and 25 years old will be recruited for army service
  ; this age is thought to be a realistic reflection of actual recruitment practices of the Roman army
  ; the recruitment rate is set using the slider at setup, and can vary between 0.0 and 0.2 per year (with steps of 0.01)
  ; recruited males are not available as spouses until they have finished their service term
  ; this assumption can be debated, but it is used here to understand the
  ; consequences of removing a certain proportion of males from the reproduction pool

  ; recruitment will start after stabilization of the model at ticks = 100

  if ticks > 100 [

   ask humans with [gender = "M" and age > 17 and age < 26 and my-spouse = 0 and is-dead = 0]

   ; for each unmarried male between 18 and 25 years old, a random number will determine whether he will be recruited

   [
     if random-float 1 < recruitment
     [
       set recruit 1
     ]
   ]

   ; for every year served, the value of [recruit] will be increased by 1
   ; after serving a 25-years term in the army, the male will be added to the reproduction pool, and will be available for marriage again
   ; these parameters could be adapted if necessary

   ask humans with [recruit > 0 and is-dead = 0]
   [
     set recruit recruit + 1
     if recruit > 25
     [
       set recruit 0
     ]
   ]

  ]

end

to marrying

  ; this procedure will try to get unmarried females married; they will start a new household if necessary
  ; a number of scenarios for marriage strategies can be explored here
  ; the minimum female marriage age [f-marriage-age] can be set in the interface

  ask humans with [gender = "F" and age >= f-marriage-age and my-spouse = 0 and is-dead = 0]

  [

  ; determine marriage-probability for each female selected
  ; scenario 1: work with marriage probabilities for first marriage
  ; marriage probabilities are calculated according to Coale (1971)
  ; for this model, the variables to be included are a0 (= f-marriage-age) and k (= marriage-time-scale-factor)

   let k marriage-time-scale-factor
   let marriage-probability ((0.174 / k) * exp(-4.411 * exp((-0.309 / k) * (age - f-marriage-age))))

  ; scenario 2: work without marriage probabilities

   ; let marriage-probability 1

   ; check if remarriage of females is allowed or not, and adapt marriage-probability accordingly

   if allow_remarriage = false and n-spouses > 0
   [
     set marriage-probability 0
   ]
   if allow_remarriage = true and n-spouses > 0
   [
     set marriage-probability 1
   ]

   let f-age age
   let husband nobody

   if (n-spouses = 0) and (random-float 1 < marriage-probability)

   ; find a suitable husband
   ; any unmarried adult male is a potential partner; this includes widowers and soldiers returning from army service; N.B. this differs from the setup conditions
   ; in the interface, the minimum age difference [marriage-age-difference] can be set if desired

   [set husband one-of humans with [gender = "M" and (age - f-age) >= marriage-age-difference and my-spouse = 0 and recruit = 0 and is-dead = 0]]

   ; when a suitable husband is found, determine if a new household should be started

   if husband != nobody
   [
     set my-spouse husband
     set n-spouses n-spouses + 1
     set widowed 0

     let couple (turtle-set self husband)

    ; if the male is widowed, then the female will be added to his household
    ; else the couple will start a new household
    ; in this model, this feature is not used for any particular purpose, but it serves to keep the number of agents as low as possible

     ask husband [
       set n-spouses n-spouses + 1
       set my-spouse myself
       ifelse widowed = 0
        [
          hatch-households 1
          [
           set household-members couple
           ask couple
           [
            set my-household myself
           ]
          ]
        ]
        [
         ask my-household [
           set household-members (turtle-set household-members self)
         ]
         set widowed 0
        ]
      ]
     ]
   ]

end

to-report mortality

  ; in this procedure, the mortality rate (risk of dying) of each human is determined; it is based on one the three life tables from which the user can choose at setup; these are:

  ; Coale and Demeny's (1966) Model West Level 3 Female
  ; Wood's (2007) South High Mortality with e0=25, and
  ; and Séguy and Buchet's (2013) Pre-Industrial Standard table
  ; N.B. the first two are adapted versions taken from Hin (2013)!

  ; the life tables used here represent mortality rates per 5-year cohort, so mortality will only change when the human has lived for another 5 years (passes into the next cohort)
  ; this could be a little bit more sophisticated (see e.g. Danielisová et al. 2015)

  let mortality-5year 0

  if Life_table = "West 3 Female" [

   if age = 0 [set mortality-5year 0.3056]
   if age > 0 and age <= 4 [set mortality-5year 0.2158 / 4]
   if age > 4 and age <= 9 [set mortality-5year 0.0606 / 5]
   if age > 9 and age <= 14 [set mortality-5year 0.0474 / 5]
   if age > 14 and age <= 19 [set mortality-5year 0.0615 / 5]
   if age > 19 and age <= 24 [set mortality-5year 0.0766 / 5]
   if age > 24 and age <= 29 [set mortality-5year 0.0857 / 5]
   if age > 29 and age <= 34 [set mortality-5year 0.0965 / 5]
   if age > 34 and age <= 39 [set mortality-5year 0.1054 / 5]
   if age > 39 and age <= 44 [set mortality-5year 0.1123 / 5]
   if age > 44 and age <= 49 [set mortality-5year 0.1197 / 5]
   if age > 49 and age <= 54 [set mortality-5year 0.1529 / 5]
   if age > 54 and age <= 59 [set mortality-5year 0.1912 / 5]
   if age > 59 and age <= 64 [set mortality-5year 0.2715 / 5]
   if age > 64 and age <= 69 [set mortality-5year 0.3484 / 5]
   if age > 69 and age <= 74 [set mortality-5year 0.4713 / 5]
   if age > 74 and age <= 79 [set mortality-5year 0.6081 / 5]
   if age > 79 and age <= 84 [set mortality-5year 0.7349 / 5]
   if age > 84 and age <= 89 [set mortality-5year 0.8650 / 5]
   if age > 89 and age <= 94 [set mortality-5year 0.9513 / 5]
   if age > 94 [set mortality-5year 1.000 / 5]
  ]

   if Life_table = "Pre-Industrial Standard" [

   if age = 0 [set mortality-5year 0.200]
   if age > 0 and age <= 4 [set mortality-5year 0.150 / 4]
   if age > 4 and age <= 9 [set mortality-5year 0.052 / 5]
   if age > 9 and age <= 14 [set mortality-5year 0.029 / 5]
   if age > 14 and age <= 19 [set mortality-5year 0.038 / 5]
   if age > 19 and age <= 24 [set mortality-5year 0.049 / 5]
   if age > 24 and age <= 29 [set mortality-5year 0.054 / 5]
   if age > 29 and age <= 34 [set mortality-5year 0.060 / 5]
   if age > 34 and age <= 39 [set mortality-5year 0.068 / 5]
   if age > 39 and age <= 44 [set mortality-5year 0.079 / 5]
   if age > 44 and age <= 49 [set mortality-5year 0.093 / 5]
   if age > 49 and age <= 54 [set mortality-5year 0.115 / 5]
   if age > 54 and age <= 59 [set mortality-5year 0.152 / 5]
   if age > 59 and age <= 64 [set mortality-5year 0.202 / 5]
   if age > 64 and age <= 69 [set mortality-5year 0.275 / 5]
   if age > 69 and age <= 74 [set mortality-5year 0.381 / 5]
   if age > 74 and age <= 79 [set mortality-5year 0.492 / 5]
   if age > 79 and age <= 84 [set mortality-5year 0.657 / 5]
   if age > 84 [set mortality-5year 1.00 / 5]
  ]

  if Life_table = "Woods 2007 South 25"[
   if age = 0 [set mortality-5year 0.2900]
   if age > 0 and age <= 4 [set mortality-5year 0.1900 / 4]
   if age > 4 and age <= 9 [set mortality-5year 0.0546 / 5]
   if age > 9 and age <= 14 [set mortality-5year 0.0429 / 5]
   if age > 14 and age <= 19 [set mortality-5year 0.0707 / 5]
   if age > 19 and age <= 24 [set mortality-5year 0.1065 / 5]
   if age > 24 and age <= 29 [set mortality-5year 0.1234 / 5]
   if age > 29 and age <= 34 [set mortality-5year 0.1301 / 5]
   if age > 34 and age <= 39 [set mortality-5year 0.1366 / 5]
   if age > 39 and age <= 44 [set mortality-5year 0.1392 / 5]
   if age > 44 and age <= 49 [set mortality-5year 0.1490 / 5]
   if age > 49 and age <= 54 [set mortality-5year 0.1655 / 5]
   if age > 54 and age <= 59 [set mortality-5year 0.1857 / 5]
   if age > 59 and age <= 64 [set mortality-5year 0.2613 / 5]
   if age > 64 and age <= 69 [set mortality-5year 0.3853 / 5]
   if age > 69 and age <= 74 [set mortality-5year 0.5288 / 5]
   if age > 74 and age <= 79 [set mortality-5year 0.6403 / 5]
   if age > 79 and age <= 84 [set mortality-5year 0.7431 / 5]
   if age > 84 [set mortality-5year 1.00 / 5]
  ]

  if Life_table = "Egypt (Bagnall & Frier 1994)" and gender = "M"[
   if age = 0 [set mortality-5year 0.32257]
   if age > 0 and age <= 4 [set mortality-5year 0.19523 / 4]
   if age > 4 and age <= 9 [set mortality-5year 0.05141 / 5]
   if age > 9 and age <= 14 [set mortality-5year 0.03697 / 5]
   if age > 14 and age <= 19 [set mortality-5year 0.05017 / 5]
   if age > 19 and age <= 24 [set mortality-5year 0.07110 / 5]
   if age > 24 and age <= 29 [set mortality-5year 0.07951 / 5]
   if age > 29 and age <= 34 [set mortality-5year 0.09175 / 5]
   if age > 34 and age <= 39 [set mortality-5year 0.10709 / 5]
   if age > 39 and age <= 44 [set mortality-5year 0.12838 / 5]
   if age > 44 and age <= 49 [set mortality-5year 0.14754 / 5]
   if age > 49 and age <= 54 [set mortality-5year 0.18383 / 5]
   if age > 54 and age <= 59 [set mortality-5year 0.22024 / 5]
   if age > 59 and age <= 64 [set mortality-5year 0.29059 / 5]
   if age > 64 and age <= 69 [set mortality-5year 0.37125 / 5]
   if age > 69 and age <= 74 [set mortality-5year 0.48085 / 5]
   if age > 74 and age <= 79 [set mortality-5year 0.62398 / 5]
   if age > 79 and age <= 84 [set mortality-5year 0.74408 / 5]
   if age > 84 and age <= 89 [set mortality-5year 0.82924 / 5]
   if age > 89 and age <= 94 [set mortality-5year 0.95201 / 5]
   if age > 94 [set mortality-5year 1.00 / 5]
  ]

    if Life_table = "Egypt (Bagnall & Frier 1994)" and gender = "F"[
   if age = 0 [set mortality-5year 0.33399]
   if age > 0 and age <= 4 [set mortality-5year 0.23760 / 4]
   if age > 4 and age <= 9 [set mortality-5year 0.06657 / 5]
   if age > 9 and age <= 14 [set mortality-5year 0.05205 / 5]
   if age > 14 and age <= 19 [set mortality-5year 0.06744 / 5]
   if age > 19 and age <= 24 [set mortality-5year 0.08385 / 5]
   if age > 24 and age <= 29 [set mortality-5year 0.09369 / 5]
   if age > 29 and age <= 34 [set mortality-5year 0.10558 / 5]
   if age > 34 and age <= 39 [set mortality-5year 0.11511 / 5]
   if age > 39 and age <= 44 [set mortality-5year 0.12227 / 5]
   if age > 44 and age <= 49 [set mortality-5year 0.12967 / 5]
   if age > 49 and age <= 54 [set mortality-5year 0.16518 / 5]
   if age > 54 and age <= 59 [set mortality-5year 0.20571 / 5]
   if age > 59 and age <= 64 [set mortality-5year 0.29144 / 5]
   if age > 64 and age <= 69 [set mortality-5year 0.37118 / 5]
   if age > 69 and age <= 74 [set mortality-5year 0.49858 / 5]
   if age > 74 and age <= 79 [set mortality-5year 0.6372 / 5]
   if age > 79 and age <= 84 [set mortality-5year 0.75601 / 5]
   if age > 84 and age <= 89 [set mortality-5year 0.87919 / 5]
   if age > 89 and age <= 94 [set mortality-5year 0.95785 / 5]
   if age > 94 [set mortality-5year 1.00 / 5]
  ]

  report mortality-5year

end

to fertility-rate

  ; in this procedure, the fertility rate (probability of reproducing) of each female is determined, based on the figures given in Coale & Trussell (1978) derived from Henry's (1961) 'natural fertility rate'
  ; the Total Fertility Rate (TFR) resulting from this scheme is 11.05
  ; note that fertility will be determined once a female has reached age 15; however, in this model reproduction is not allowed until the female is married

  ; the second schedule (greyed out in this version) is based on Bagnall & Frier's (1994) Egypt data (TFR 6.27); this already takes into account nuptiality and possible contraceptive measures
  ; the figures used here represent fertility rates per 5-year cohort, so fertility will only change when the female has lived for another 5 years (passes into the next cohort)

  ; a more realistic approach would take into account the time that has passed since the previous birth
  ; however, this would make the model much slower, since we would then have to use time steps of one month

  ask humans with [gender = "F"]
  [
     if age < 15
     [
       set fertility 0.000
;       set fertility 0.0259
     ]
     if age > 14 and age <= 19
     [
       set fertility 0.411
;       set fertility 0.1596
     ]
     if age > 19 and age <= 24
     [
      set fertility 0.46
;       set fertility 0.2311
     ]
     if age > 24 and age <= 29
     [
       set fertility 0.431
;       set fertility 0.2776
     ]
     if age > 29 and age <= 34
     [
       set fertility 0.395
;       set fertility 0.2129
     ]
     if age > 34 and age <= 39
     [
       set fertility 0.322
;       set fertility 0.1633
     ]
     if age > 39 and age <= 44
     [
       set fertility 0.167
;       set fertility 0.1300
     ]
     if age > 45 and age <= 49
     [
       set fertility 0.024
;       set fertility 0.0631
     ]
     if age > 49
     [
       set fertility 0.000
     ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
277
29
439
192
-1
-1
154.0
1
0
1
1
1
0
0
0
1
0
0
0
0
0
0
1
ticks
30.0

BUTTON
23
37
86
70
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
107
38
170
71
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
228
10
815
470
Demographic characteristics
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"population size" 1.0 0 -16448764 true "" "plot count humans with [is-dead = 0]"
"number of deaths" 1.0 0 -7500403 true "" "plot n-deaths"
"number of newborns" 1.0 0 -2674135 true "" "plot n-born"
"number of elderly (50 years and older)" 1.0 0 -14730904 true "" "plot count humans with [age > 49 and is-dead = 0]"
"number of adults (18 years and older)" 1.0 0 -14439633 true "" "plot count humans with [age > 17 and age < 50 and is-dead = 0]"
"number of children (under 18 years old)" 1.0 0 -955883 true "" "plot count humans with [age < 18 and is-dead = 0]"
"unmarried females (over 18 years old)" 1.0 0 -6459832 true "" "plot count humans with [gender = \"F\" and my-spouse = 0 and age > 17 and is-dead = 0]"
"males between 18 and 25 years old" 1.0 0 -12186836 true "" "plot count humans with [gender = \"M\" and age > 17 and age < 26 and is-dead = 0]"
"number of couples" 1.0 0 -5825686 true "" "plot (count humans with [my-spouse != 0 and is-dead = 0] / 2)"
"number of widow(er)s" 1.0 0 -13791810 true "" "plot (count humans with [widowed = 1 and is-dead = 0])"

CHOOSER
-1
84
203
129
Life_table
Life_table
"West 3 Female" "Pre-industrial Standard" "Woods 2007 South 25" "Egypt (Bagnall & Frier 1994)"
2

SLIDER
0
136
172
169
recruitment
recruitment
0
0.2
0.0
0.01
1
NIL
HORIZONTAL

PLOT
822
267
1225
468
Recruits
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Number of males in army service" 1.0 0 -16777216 true "" "plot count humans with [recruit > 0 and is-dead = 0]"

PLOT
821
10
1225
262
Annual population growth
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% population growth" 1.0 0 -16777216 true "" "plot 100 * (n-born - n-deaths) / count humans with [is-dead = 0]"

PLOT
821
470
1226
620
Children per female
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Number of children" 1.0 0 -16777216 true "" "plot n-children-per-female"
"Number of spouses" 1.0 0 -2674135 true "" "plot n-spouses-per-female"

SLIDER
1
215
173
248
disease-recurrence
disease-recurrence
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1
178
173
211
disease-mortality
disease-mortality
1
5
1.0
0.1
1
NIL
HORIZONTAL

PLOT
1232
11
1428
261
Annual mortality rate
NIL
NIL
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (n-deaths / count humans with [is-dead = 0])"

PLOT
1232
268
1430
467
Unmarried rate (f = grey, m = red)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"unmarried females" 1.0 0 -7500403 true "" "plot count humans with [gender = \"F\" and age >= f-marriage-age and n-spouses = 0 and is-dead = 0] / count humans with [gender = \"F\" and age >= f-marriage-age and is-dead = 0]"
"unmarried males" 1.0 0 -2674135 true "" "plot count humans with [gender = \"M\" and age >= (f-marriage-age + marriage-age-difference) and n-spouses = 0 and is-dead = 0] / count humans with [gender = \"M\" and age >= (f-marriage-age + marriage-age-difference) and is-dead = 0]"

PLOT
1232
471
1430
619
male-female ratio
NIL
NIL
0.0
10.0
0.5
1.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count humans with [gender = \"M\" and is-dead = 0]) / (count humans with [gender = \"F\" and is-dead = 0])"

SWITCH
3
258
153
291
allow_remarriage
allow_remarriage
0
1
-1000

SLIDER
4
375
223
408
marriage-age-difference
marriage-age-difference
-5
15
10.0
1
1
years
HORIZONTAL

SLIDER
4
295
176
328
f-marriage-age
f-marriage-age
12
30
15.0
1
1
years
HORIZONTAL

SLIDER
4
414
176
447
fertility-rate-modifier
fertility-rate-modifier
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
4
449
207
482
stopping-behaviour
stopping-behaviour
0
20
20.0
1
1
children
HORIZONTAL

SLIDER
5
333
201
366
marriage-time-scale-factor
marriage-time-scale-factor
0
1
0.5
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model is simulating the demographic development of a hypothetical human population. The main goal is to simulate and understand the mechanisms that influence population growth and decline, and to assess the effects of changing the relevant parameters. For this, a distinction can be made between 'natural' demographic factors (mortality and fertility), and 'social' factors (in particular marriage rules).  

The model was originally applied in the context of recruitment practices of the Roman army in the Dutch limes zone. In the Early and Middle Roman period (15 BC - 275 AD), the Roman authorities levied soldiers from the local, Batavian population. The effects of this practice on demography and economy are poorly understood. The model is specifically intended to simulate what happens to the reproduction rate if a proportion of the male population is recruited, and taken from the marriage pool.

The model presented here is a revised model of the model 'Batavian Demography and Army Recruitment' (http://modelingcommons.org/browse/one_model/4678), that was presented as an appendix to Verhagen et al. (2016). This earlier model showed that, if the assumption of non-marriage of soldiers is correct, then the effects of recruitment on population growth will be considerable. The model results indicate that there is an 'optimal' recruitment that will leave the population stationary, and will guarantee the steady supply of recruits. This optimal level depends on the natural population growth. With higher levels of recruitment, the populations will quickly go in decline. Very low levels of recruitment on the other hand will require very large populations to supply sufficient recruits.

This models is now extended with options to include more sophisticated marriage rules and the effects of mortality crises on population growth and decline (Verhagen 2019). It shows that the effects of marriage strategies and birth control on population growth are considerable, thus suggesting that ancient populations had plenty of options available to control population growth. Mortality crises, while clearly felt on the short term, will only have a long-term negative effect when they have a short return period.

## HOW IT WORKS

The model has two entities, humans and households. The households are collectives, composed of a limited number of humans (usually a couple with a number of children, but grandparents might be part of a household as well).

The basic principle of the model is to let a starting population reproduce and die under various regimes of mortality, fertility and recruitment. From this, demographic characteristics will emerge that may be relevant to the economic sphere as well, like the number of people available for labour.

The female agents only have one objective: to find a spouse, so that they can reproduce. The agents don't have any adaptive behaviours, there is no learning involved, and they don't interact. All patterns emerging from the model are therefore governed by external factors (in this case, recruitment rate and mortality regime). Stochasticity is involved in determining mortality, fertility and recruitment rate. All are defined as probabilities, and the chances of dying, reproducing and being recruited are determined by comparison of these probabilities to a random number.

The following procedures are part of the model: dying, reproducing, recruiting and marrying. Each is executed consecutively at each time step. Each time step represents one year.

<b>Initialization</b>
The starting population is composed of 200 humans. Each is attributed a biological sex ('natural sex ratio' of 105:100 M:F - see Bagnall and Frier 1994:95) and an age (based on one of three model life tables selected by the user). Furthermore, it will be registered whether the humans are widowed, recruited (only for males), how many children they have, and what household they belong to.

Next, females of marriageable age (set by the user) are coupled to a male that is a minimum age difference (set by the user) older, and together they will form a household. The remaining humans are distributed randomly over the households. This is not a realistic assumption, but suffices for the initialization phase of the model.

<b>Submodels</b>

<i>Reproducing</i>
In this procedure, it will be determined which females will give birth this year. The probability of reproducing is determined on the basis of the fertility rates suggested by Coale and Trussell (1978), which can be modified by setting the fertility rate modifier to mimic the effects of longer birth spacings. Stopping behaviour can be set by the user to maximize the number of children per household.

If a female gives birth, a new human of age 0 will be hatched with biological sex male or female and it will be added to the households of its parents.

<i>Dying</i>
In this procedure, it will be determined which humans will die this year. The probability of dying is determined on the basis of one of three model life tables select by the user (named West 3 Female, Pre-industrial standard, and Woods 2007 South 25). All three have been suggested as plausible mortality regimes for the Roman period. Mortality can be modified by introducing mortality crises (named disease mortality and disease recurrence in the interface, but they could be due to other causes as well).

For females who die, it will be registered how many children they have had.

<i>Recruiting</i>
In this procedure, a number of males of age 18-25 will be 'recruited' for the army. The probability of recruitment is pre-set by the user, and can vary between 0 and 0.2 with steps of 0.01. Upon recruitment, the male will stay in the army for the next 25 years. During this time, he will not be available as a spouse. Recruitment will only start after 100 ticks, in order to give the model sufficient time to stabilize.

<i>Marrying</i>
In this procedure, any unmarried female of first-marriage-age or older will look for an unmarried male that is older by marriage-age-difference or more years. The marriage time scale factor can be used to reduce marriage probability depending on age, following Coale (1971) - not all females will get married at the same age. There are no further restrictions on the selection of a husband. Only after marriage a female will have the opportunity to reproduce.

## HOW TO USE IT

The model has ten user inputs: 
<list>
- selection of the model life table to be used (drop-down menu)
- recruitment rate (slider)
- disease mortality (slider)
- disease recurrence (slider)
- allow remarriage (switch)
- first marriage age (slider)
- marriage time scale factor (slider)
- marriage age difference (slider)
- fertility rate modifier (slider)
- stopping behaviour (slider)
</list>

Other inputs (like initial population size, age limitations etc.) can be set in the code section if so desired.

The model produces seven plots. The main plot shows the following demographic characteristics of the population:
<list>
- population size
- annual number of deaths
- annual number of births
- number of elderly (50 years and older)
- number adults (18 years and older)
- number of children (under 18 years old)
- the number of unmarried females (of 18 years and older)
- the number of males between 18 and 25 years old
- the number of married couples
- number of widow(er)s
</list>

The minor plots show the annual population growth (upper center), the number of recruits in the army (middle centre), the number of children per female (lower center), the annual mortality rate (upper right), unmarried rate (centre right) and male-female ratio (lower right).

## THINGS TO NOTICE

After initialization, the model should be run for 100 ticks in order to stabilize before collecting output statistics. There are no specific rules for collecting outputs, only the plots will be updated.

The model will stop after 200 ticks, but could be run longer if so desired. However, with high population growth rates, execution could then become very slow because of the large number of agents.

The model has no spatial component, so the World View is minimized.

## THINGS TO TRY

The model interface has ten options for the user to play with. These options can be used to run various scenarios using the BehaviorSpace add-on, the results of which are reported in the paper accompanying the model.

## EXTENDING THE MODEL

A number of possible improvements to the model are suggested here:

<b>Mortality</b>
Mortality rates are now given per 5-year age cohort, these could be recalculated to reflect mortality rates per year (as was done by Danielisová et al. 2015).

The mortality modifier used to simulate the mortality crises is extremely simple and could be extended to include differential mortality among age groups, and to simulate varying recurrence and mortality rates in order to mimic the effects of specific catastrophic events.

<b>Reproduction</b>
<i>More realistic reproduction models</i>
More realistic reproduction models could take into account more realistic effects of the time lag between giving birth and the next pregnancy. This would however make the model much harder to handle, since the time steps would have to be much smaller (in the order of months; see e.g. White 2014 for an attempt at such an approach).

<i>Twins</i>
A more realistic model of household demographics should also include the possibility to give birth to twins. While the chances of twins being born are not very high (approx. 3%), it could slightly change the behaviour of the model. The fertility rates applied here are averages per five years for females over their whole reproductive period, that can be used to to estimate the number of children born in this period, but without any indication about when these will be born. For obtaining general figures of demographic development, this will be good enough - but it will not be good enough if we want to zoom in to the level of the individual household.

<i>Recruitment</i>
A possible extension to the recruitment procedure could include the option for recruits
to marry (for which some evidence is found in historical sources). The effect of a shorter service term (20 instead of 25 years) can easily be implemented.

In the current model, recruitment rates are set as proportions. It may be that the Roman authorities did not bother about this, but just demanded a fixed number of soldiers per year. This can be implemented quite easily as well. Furthermore, recruitment requirements might have been more dynamic, and fluctuating through time depending on the needs of the army. Again, this could be implemented quite easily.

Also note that the mortality of recruits is equal to the mortality of those who stayed at home. This may not be fully realistic, but it is assumed that during peace time mortality will not have been different for the soldier population.

<b>Marriage</b>
The marriage rules applied here do not consider more complex factors involved such as geographical distance and economic and social position of the partners. This could be a rich field of experimentation for future models, since the influence of these factors on reproduction is generally not very well understood.

## NETLOGO FEATURES

There are no particular NetLogo features used that need to be addressed here.

## RELATED MODELS

White's ForagerNet model (2014), coded in Repast, deals with a number of similar issues.

<i>White, Andrew A. (2014, February 13). "ForagerNet3_Demography_V2" (Version 1). CoMSES Computational Model Library. Retrieved from: https://www.openabm.org/model/4087/version/1</i>

## CREDITS AND REFERENCES

This model comes as an appendix to the following paper:

<i>Verhagen P 2019: 'Modelling the dynamics of demography in the Dutch limes zone' in Verhagen P, J Joyce & MR Groenhuijzen (ed), Finding the limits of the limes. Modelling economy, demography and transport on the edge of the Roman Empire'. Springer, New York.</i>

The first version of the model was described in:
<i>Verhagen P, Joyce J, Groenhuijzen MR 2016: Modelling the dynamics of demography in the Dutch limes zone, in Multi-, inter- and transdisciplinary research in landscape archaeology. Proceedings of LAC 2014 Conference, Rome, 19-20 September 2014. Vrije Universiteit Amsterdam, Amsterdam. doi:10.5463/lac.2014.62</i>

In these papers, the archaeological background and assumptions used for this model are described in more detail.

The following references were used for setting up the mortality and fertility estimates:
<list><i>
Bagnall RS & BW Frier 1994: The demography of Roman Egypt. Cambridge University Press, Cambridge.
Coale AJ 1971: Age Patterns of Marriage. Population Studies 25(2):193-214.
Coale AJ & P Demeny 1966: Regional Model Life Tables and Stable Populations, Princeton University Press, Princeton.
Coale AJ & TJ Trussell 1974: Model Fertility Schedules: Variations in The Age Structure of Childbearing in Human Populations, Population Index 40, 185–258.
Danielisová A, K Olševičová, R Cimler & T Machálek 2015: Understanding the Iron Age Economy: Sustainability of Agricultural Practices under Stable Population Growth, in Wurzer G, K Kowarik & H Reschreiter (ed), Agent-based Modeling and Simulation in Archaeology, 205-241. Springer, Cham.
Hin S 2013: The Demography of Roman Italy. Population Dynamics in an Ancient Conquest Society 201 BCE–14 CE, Cambridge University Press, Cambridge.
Séguy I & L Buchet 2013: Handbook of Palaeodemography, Springer, Cham.
Woods R 2007: Ancient and early modern mortality: experience and understanding, The Economic History Review 60, 373–399.
White AA 2014: Mortality, Fertility, and the OY Ratio in a Model Hunter-Gatherer System, American Journal of Physical Anthropology 154, 222-231. http://onlinelibrary.wiley.com/doi/10.1002/ajpa.22495/abstract</i></list>

Thanks go to Tom Brughmans (University of Konstanz) for reviewing an earlier version of this model. All errors remain the responsiblity of the author.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="recruitment Woods 2007" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans</metric>
    <metric>count humans with [recruit &gt; 0]</metric>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.06"/>
      <value value="0.07"/>
      <value value="0.08"/>
      <value value="0.09"/>
      <value value="0.1"/>
      <value value="0.11"/>
      <value value="0.12"/>
      <value value="0.13"/>
      <value value="0.14"/>
      <value value="0.15"/>
      <value value="0.16"/>
      <value value="0.17"/>
      <value value="0.18"/>
      <value value="0.19"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="recruitment Pre-industrial Standard" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans</metric>
    <metric>count humans with [recruit &gt; 0]</metric>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.06"/>
      <value value="0.07"/>
      <value value="0.08"/>
      <value value="0.09"/>
      <value value="0.1"/>
      <value value="0.11"/>
      <value value="0.12"/>
      <value value="0.13"/>
      <value value="0.14"/>
      <value value="0.15"/>
      <value value="0.16"/>
      <value value="0.17"/>
      <value value="0.18"/>
      <value value="0.19"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Pre-industrial Standard&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="recruitment West 3 Female" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans</metric>
    <metric>count humans with [recruit &gt; 0]</metric>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.06"/>
      <value value="0.07"/>
      <value value="0.08"/>
      <value value="0.09"/>
      <value value="0.1"/>
      <value value="0.11"/>
      <value value="0.12"/>
      <value value="0.13"/>
      <value value="0.14"/>
      <value value="0.15"/>
      <value value="0.16"/>
      <value value="0.17"/>
      <value value="0.18"/>
      <value value="0.19"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;West 3 Female&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="marriage time scale factor" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fertility rate modifier" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
      <value value="0.9"/>
      <value value="0.8"/>
      <value value="0.7"/>
      <value value="0.6"/>
      <value value="0.5"/>
      <value value="0.4"/>
      <value value="0.3"/>
      <value value="0.2"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="stopping behaviour" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="8"/>
      <value value="7"/>
      <value value="6"/>
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="disease mortality" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-mortality">
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-recurrence">
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="remarriage" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allow_remarriage">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="marriage age difference" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count humans with [is-dead = 0]</metric>
    <enumeratedValueSet variable="marriage-time-scale-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Life_table">
      <value value="&quot;Woods 2007 South 25&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marriage-age-difference">
      <value value="0"/>
      <value value="3"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recruitment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fertility-rate-modifier">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopping-behaviour">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
