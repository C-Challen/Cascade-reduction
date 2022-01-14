load('BOpairs_RTS_n-2.mat','Cascade');
MW = zeros(120,6,sum(Cascade));
Values = [0,5,10,15,30,60];
for i = 1:8736
    if Cascade(i) == 1
        for j = 1:6
            load(['BOpairs_ieee_rts_73_n-2_',num2str(i),'_of_8736_',num2str(Values(j)),'s_Type_1.mat'],'MW_lost');
            MW(:,j,sum(Cascade(1:i))) = MW_lost;
        end
    end
end