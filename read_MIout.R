library(tidyverse)
library(rgcam)

nutcont<-read_csv("inputs/NutCont_region_commod.csv")
nfix<-read_csv("inputs/Nfix_commod_region.csv")

Nout1<-read_csv('outdata/Ncons_DT.csv', skip = 1)%>% mutate(scenario="DietTrans")
Nout2<-read_csv('outdata/Ncons_PotYld.csv', skip = 1)%>% mutate(scenario="PotYld")
Nout3<-read_csv('outdata/Ncons_Ref.csv', skip = 1)%>% mutate(scenario="Ref")

Ncons<-Nout1 %>% bind_rows(Nout2) %>% bind_rows(Nout3)

Pout1<-read_csv('outdata/Pcons_DT.csv', skip = 1) %>% mutate(scenario="DietTrans")
Pout2<-read_csv('outdata/Pcons_PotYld.csv', skip = 1) %>% mutate(scenario="PotYld")
Pout3<-read_csv('outdata/Pcons_Ref.csv', skip = 1) %>% mutate(scenario="Ref")

Pcons<-Pout1 %>% bind_rows(Pout2) %>% bind_rows(Pout3)

Prod1<-read_csv('outdata/Prod_DT.csv', skip = 1)%>% mutate(scenario="DietTrans")
Prod2<-read_csv('outdata/Prod_PotYld.csv', skip = 1)%>% mutate(scenario="PotYld")
Prod3<-read_csv('outdata/Prod_Ref.csv', skip = 1)%>% mutate(scenario="Ref")

Prod<-Prod1 %>% bind_rows(Prod2) %>% bind_rows(Prod3)

Prod %>%
  pivot_longer(cols=`1990`:`2095`,names_to="year") %>%
  rename("prodMt"=value)->cropprod

Ncons %>%
  pivot_longer(cols=`1990`:`2095`,names_to="year") %>%
  rename("NfertMt"=value)->Nfert

Pcons %>%
  pivot_longer(cols=`1990`:`2095`,names_to="year") %>%
  rename("PfertMt"=value)->Pfert

