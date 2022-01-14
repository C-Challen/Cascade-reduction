Blackout = zeros(120,8736);
Buses = zeros(120,8736);
MW = zeros(120,8736);
P = zeros(120,8736);
Relays = zeros(120,8736);
for i = 1:8736
    if exist(['BOpairs_ieee_rts_73_n-3_',num2str(i),'_of_8736_30s_Type_2.mat'])>0
        load(['BOpairs_ieee_rts_73_n-3_',num2str(i),'_of_8736_30s_Type_2.mat']);
        Blackout(:,i) = blackout;
        Buses(:,i) = buses_count;
        MW(:,i) = MW_lost;
        P(:,i) = p_out;
        Relays(:,i) = relay_count;
    end
end