function IEEE_RTS_Data_Mine

clear
Test_Type = {'10s_Type_1','5s_Type_2','10s_Type_2','20s_Type_2','30s_Type_2','60s_Type_2','120s_Type_2'};
ps = case_ieee_rts_73;
n_relays = size(ps.branch,1);
n_pairs = 551;
n_delays = 7;
Data = struct('BOpair',[],'MW_lost',[],'MW_Base',[],'Buses',[],'Buses_Base',[],'Relays',[],'Relays_Base',[]);

for i = 364:-1:1
    for j = 24:-1:1
        for k = n_delays:-1:1
            Results.Day(i).Hour(j).Delay(k) = Data;
        end
    end
end

for Day = 1:364
    for Delay = 1:n_delays
        File = (['BOpairs_ieee_rts_73_n-2_Day_',num2str(Day),'_',cell2mat(Test_Type(Delay)),'.mat']);
        if exist(File,'file') ~=0
            load(File,'buses_count','buses_count_base','MW_lost','MW_lost_base','relay_count','relay_count_base');
            for Hour = 1:24
                if sum(MW_lost_base(:,Hour)) > 0
                    BOpair = find(MW_lost_base(:,Hour));        
                    Results.Day(Day).Hour(Hour).Delay(Delay).BOpair = BOpair';
                    Results.Day(Day).Hour(Hour).Delay(Delay).MW_lost = MW_lost(:,BOpair,Hour);                    
                    Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base = MW_lost_base(BOpair,Hour)';                            
                    Results.Day(Day).Hour(Hour).Delay(Delay).Buses = buses_count(:,BOpair,Hour);                                 
                    Results.Day(Day).Hour(Hour).Delay(Delay).Buses_Base = buses_count_base(BOpair,Hour)';                    
                    Results.Day(Day).Hour(Hour).Delay(Delay).Relays = relay_count(:,BOpair,Hour);                    
                    Results.Day(Day).Hour(Hour).Delay(Delay).Relays_Base = relay_count_base(BOpair,Hour)';                      
                end
            end
        end
    end
end
save('ieee_rts_n-2_results.mat','Results');
end