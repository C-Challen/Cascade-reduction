close all
clear

load('ieee_rts_n-2_results.mat')
load BOpairs_RTS_n-2_line_rating_60.mat BOpairs
Hours = 364*24;
Pairs = 551;
n_Delays = 7;
Lookup = zeros(Hours,Pairs,10,n_Delays);
Lookup_Titles = {'Initial Relay 1';'Initial Relay 2';'Base MW Lost';'Base Relays Lost';'Base Buses Lost';'Intervention Relay';'Intervention MW Saved';'Intervention % Improvement';'Intervention Relays Lost';'Intervention Buses Lost'};
Cascade = false(Hours,1);
BOpair_Cascade = false(Hours,Pairs);
Output = cell(Hours,n_Delays);

for Day = 1:364
    for Hour = 1:24
        Time = Day*24-24+Hour;
        if ~isempty(Results.Day(Day).Hour(Hour).Delay(1).MW_Base) % If at least one cascade occurs
            Cascade(Time,1) = true; % A cascade occurs at this time
            BOpair_Cascade(Time,Results.Day(Day).Hour(Hour).Delay(1).BOpair) = true; % A cascade occurs at this time due to these BOpairs
            BOpair_Temp = find(BOpair_Cascade(Time,:));
            for Delay = 1:n_Delays % For varying amounts of delay before intervention
                Lookup(Time,BOpair_Temp,1:2,Delay) = BOpairs(BOpair_Cascade(Time,:),1:2); % Record initiating BOpairs
                Lookup(Time,BOpair_Temp,3,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base; % Record base MW load shed
                Lookup(Time,BOpair_Temp,4,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).Relays_Base; % Record base number of relays tripped
                Lookup(Time,BOpair_Temp,5,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).Buses_Base; % Record base number of buses disconnected

                [Value,Intervention] = min(Results.Day(Day).Hour(Hour).Delay(Delay).MW_lost); % Find and record the most effective relay to remove
                False_Reading = Value >= Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base;
                Value(False_Reading) = NaN;
                Intervention(False_Reading) = NaN;

                for i = 1:length(Intervention)  
                    if ~isnan(Intervention(i))
                        Lookup(Time,BOpair_Temp(i),6,Delay) = Intervention(i);
                        Lookup(Time,BOpair_Temp(i),7,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base(i) - Value(i); % Record the predicted impact in load shedding
                        Lookup(Time,BOpair_Temp(i),8,Delay) = (Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base(i) - Value(i)) / Results.Day(Day).Hour(Hour).Delay(Delay).MW_Base(i) * 100; % Record the predicted impact in load shedding as a percentage of the original outage
                        Lookup(Time,BOpair_Temp(i),9,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).Relays(Intervention(i),i); % Record the predicted number of relays tripped after intervention
                        Lookup(Time,BOpair_Temp(i),10,Delay) = Results.Day(Day).Hour(Hour).Delay(Delay).Buses(Intervention(i),i); % Record the predicted number of buses disconnected after intervention
                    end
                end

                if sum(BOpair_Cascade(Time,:)) == 1 % If only one set of cascades at this time
                    Output(Time,Delay) = {[Lookup_Titles,num2cell(squeeze(Lookup(Time,BOpair_Temp,:,Delay)))]}; % No need to rotate matrix after squeeze
                else
                    Output(Time,Delay) = {[Lookup_Titles,num2cell(squeeze(Lookup(Time,BOpair_Temp,:,Delay))')]}; % Rotate matrix
                end
            end
        end
    end
end

Type = {'Lookup(:,:,3,1)';'Lookup(:,:,3,1)-Lookup(:,:,7,7)';'Lookup(:,:,3,1)-Lookup(:,:,7,6)';'Lookup(:,:,3,1)-Lookup(:,:,7,5)';'Lookup(:,:,3,1)-Lookup(:,:,7,4)';'Lookup(:,:,3,1)-Lookup(:,:,7,3)';'Lookup(:,:,3,1)-Lookup(:,:,7,2)';'Lookup(:,:,3,1)-Lookup(:,:,7,1)';'Lookup(:,:,8,7)';'Lookup(:,:,8,6)';'Lookup(:,:,8,5)';'Lookup(:,:,8,4)';'Lookup(:,:,8,3)';'Lookup(:,:,8,2)';'Lookup(:,:,8,1)'};
Title = {'Base Case MW Lost';'120s Delay After t2, MW Improvement';'60s Delay After t2, MW Improvement';'30s Delay After t2, MW Improvement';'20s Delay After t2, MW Improvement';'10s Delay After t2, MW Improvement';'5s Delay After t2, MW Improvement';'10s Delay After t1, MW Improvement';'120s Delay After t2, Percentage Improvement';'60s Delay After t2, Percentage Improvement';'30s Delay After t2, Percentage Improvement';'20s Delay After t2, Percentage Improvement';'10s Delay After t2, Percentage Improvement';'5s Delay After t2, Percentage Improvement';'10s Delay After t1, Percentage Improvement'};
Z_Axis = {'Base MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement'};
Limits(1:n_Delays+1) = max(max(Lookup(:,:,3,1))); % Highest intial MW lost
Limits(n_Delays+2:2*n_Delays+1) = max(max(Lookup(:,:,8,1))); % Highest percentage improvement

n = 50;                
Map_1(1,:) = [0 0.75 0];  
Map_1(2,:) = [1 1 0];  
Map_1(3,:) = [1 0 0];   
[X,Y] = meshgrid(1:3,1:50); 
Map_1 = interp2(X([1,25,50],:),Y([1,25,50],:),Map_1,X,Y);
Map_2 = flip(Map_1);

for i = 1:n_Delays+1 % n_Delays*2+1
    figure('WindowState','maximized');
    Graph = surf(eval(cell2mat(Type(i))),'EdgeColor','none');
    title(cell2mat(Title(i)));
    xlabel('Blackout Pair');
    ylabel('Hour');
    zlabel(cell2mat(Z_Axis(i)));
    Graph.AlphaData = (Graph.ZData > 0);
    Graph.FaceColor = 'interp';
    Graph.FaceAlpha = 'interp';
    if i <= n_Delays + 1
        colormap(Map_1);
    else
        colormap(Map_2);
    end
    shading interp;
    colorbar;
    caxis([0 Limits(i)]);
    xlim([0 551]);
    ylim([0 8736]);
    zlim([0 Limits(i)]);
end

% Hour = [270,45]; % Co-ordinates for View function
% Pairs = [0,45];

clearvars Day Pair Type Title Z_Axis i Count Data Graph Limits Time Map_1 Map_2 X Y n Hours Delay BOpairs Value Intervention InterventionID Hour Pairs n_delays BOpair_Temp False_Reading