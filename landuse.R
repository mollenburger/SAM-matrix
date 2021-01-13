landbycrop<-getQuery(SAMout,"land allocation by crop")

forest<-landbycrop %>% filter(landleaf=="Forest") %>%
  select(-Units, -landleaf)

crops_all<-landbycrop %>% filter(landleaf %in% allcrops, year %in% modelfuture) %>%
  group_by(scenario,region,year) %>%
  summarize(cropland=sum(value)) %>%
  ungroup()

forest %>%
  mutate(year=year+5) %>%
  rename('forest_prev'=value)->forest_lag

forest %>%
  left_join(forest_lag, by = c("scenario", "region", "year")) %>%
  filter(year %in% modelfuture) %>%
  mutate(forest_change=value-forest_prev) %>%
  rename("forest_cur"=value) %>%
  left_join(crops_all, by = c("scenario", "region", "year")) %>%
  mutate(forest_frac=forest_change/cropland)->forest_change
