close all
clear

load Polish_Results_Initial BOpairs

Pairs = size(BOpairs,1);
n_Delays = 7;
Lookup = zeros(Pairs,10,n_Delays);
Lookup_Titles = {'Initial Relay 1';'Initial Relay 2';'Base MW Lost';'Base Relays Lost';'Base Buses Lost';'Intervention Relay';'Intervention MW Saved';'Intervention % Improvement';'Intervention Relays Lost';'Intervention Buses Lost'};
Output = cell(1,n_Delays);
Delay_Val = [0,10,20,30,60,90,120];

for Delay = 1:7
    
    load(['Polish_Results_',num2str(Delay_Val(Delay)),'s_After.mat'],'BOpairs','Buses','Buses_Initial','MW','MW_Initial','Relays','Relays_Initial')
    
    Lookup(:,1:2,Delay) = BOpairs'; % Record initiating BOpairs
    Lookup(:,3,Delay) = MW_Initial'; % Record base MW load shed
    Lookup(:,4,Delay) = Relays_Initial'; % Record base number of relays tripped
    Lookup(:,5,Delay) = Buses_Initial'; % Record base number of buses disconnected

    [Value,Intervention] = min(MW); % Find and record the most effective relay to remove                
    False_Reading = Value >= MW_Initial;                
    Value(False_Reading) = NaN;                
    Intervention(False_Reading) = NaN;

    for i = 1:length(Intervention)                  
        if ~isnan(Intervention(i))                    
            Lookup(i,6,Delay) = Intervention(i);                    
            Lookup(i,7,Delay) = MW_Initial(i) - Value(i); % Record the predicted impact in load shedding                    
            Lookup(i,8,Delay) = (MW_Initial(i) - Value(i)) / MW_Initial(i) * 100; % Record the predicted impact in load shedding as a percentage of the original outage                    
            Lookup(i,9,Delay) = Relays(Intervention(i),i); % Record the predicted number of relays tripped after intervention                    
            Lookup(i,10,Delay) = Buses(Intervention(i),i); % Record the predicted number of buses disconnected after intervention                
        end        
    end      
    Output(1,Delay) = {[Lookup_Titles,num2cell(squeeze(Lookup(:,:,Delay))')]}; % Rotate matrix           
end

Type = {'Lookup(:,3,1)';'Lookup(:,3,1)-Lookup(:,7,7)';'Lookup(:,3,1)-Lookup(:,7,6)';'Lookup(:,3,1)-Lookup(:,7,5)';'Lookup(:,3,1)-Lookup(:,7,4)';'Lookup(:,3,1)-Lookup(:,7,3)';'Lookup(:,3,1)-Lookup(:,7,2)';'Lookup(:,3,1)-Lookup(:,7,1)';'Lookup(:,8,7)';'Lookup(:,8,6)';'Lookup(:,8,5)';'Lookup(:,8,4)';'Lookup(:,8,3)';'Lookup(:,8,2)';'Lookup(:,8,1)'};
Title = {'Base Case MW Lost';'120s Delay After t2, MW Improvement';'60s Delay After t2, MW Improvement';'30s Delay After t2, MW Improvement';'20s Delay After t2, MW Improvement';'10s Delay After t2, MW Improvement';'5s Delay After t2, MW Improvement';'10s Delay After t1, MW Improvement';'120s Delay After t2, Percentage Improvement';'60s Delay After t2, Percentage Improvement';'30s Delay After t2, Percentage Improvement';'20s Delay After t2, Percentage Improvement';'10s Delay After t2, Percentage Improvement';'5s Delay After t2, Percentage Improvement';'10s Delay After t1, Percentage Improvement'};
Y_Axis = {'Base MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Lowest MW Lost';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement';'Highest Percentage Improvement'};
Limits(1:n_Delays+1) = max(max(Lookup(:,3,1))); % Highest intial MW lost
Limits(n_Delays+2:2*n_Delays+1) = max(max(Lookup(:,8,1))); % Highest percentage improvement

n = 50;                
Map_1(1,:) = [0 0.75 0];  
Map_1(2,:) = [1 1 0];  
Map_1(3,:) = [1 0 0];   
[X,Y] = meshgrid(1:3,1:50); 
Map_1 = interp(X([1,25],:),Map_1,X);
Map_2 = flip(Map_1);

for i = 1:n_Delays+1 %n_Delays*2+1
    figure('WindowState','maximized');
    Graph = bar(eval(cell2mat(Type(i))));
    Graph.FaceColor = 'interp';
    title(cell2mat(Title(i)));
    xlabel('Blackout Pair');
    ylabel(cell2mat(Y_Axis(i)));
%    if i <= n_Delays + 1
%        Graph.FaceColor = colormap(Map_1);
%    else
%        Graph.FaceColor = colormap(Map_2);
%    end
%    shading interp;
%    colorbar;
    caxis([0 Limits(i)]);
    xlim([0 Pairs]);
    ylim([0 Limits(i)]);
end

% Hour = [270,45]; % Co-ordinates for View function
% Pairs = [0,45];

clearvars Day Pair Type Title Z_Axis i Count Data Graph Limits Time Map_1 Map_2 X Y n Hours Delay BOpairs Value Intervention InterventionID Hour Pairs n_delays BOpair_Temp False_Reading