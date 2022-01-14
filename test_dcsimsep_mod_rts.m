function test_dcsimsep_mod_rts(Delay,TestType,Day,Rating)
% Usage test_dcsimsep_mod_rts(ID,Delay,TestType)
% ID = job number for parallel processing
% Delay = delay in seconds before intervention
% TestType = 1 for intervention after initiating event, 2 for intervention after start of cascade

clc

%% get constants that help us to find the data
C = psconstants; % tells me where to find my data

%% set some options
opt = psoptions;
opt.verbose = false; % set this to false if you don't want stuff on the command line
load ieee_rts_73_varied_load P Q
load BOpairs_RTS_n-2_line_rating_60 BOpairs
ps = case_ieee_rts_73;
BOpairs = BOpairs(:,1:2);
n_Cases = size(BOpairs,1);
n_Hours = 24;
n_relays = size(ps.branch,1);
MW_lost_base = zeros(n_Cases,n_Hours); 
relay_count_base = zeros(n_Cases,n_Hours); 
buses_count_base = zeros(n_Cases,n_Hours); 
blackout = zeros(n_relays,n_Cases,n_Hours);
relay_count = zeros(n_relays,n_Cases,n_Hours);
p_out = zeros(n_relays,n_Cases,n_Hours);
MW_lost = zeros(n_relays,n_Cases,n_Hours);
buses_count = zeros(n_relays,n_Cases,n_Hours);

for Hour = 1:n_Hours
%% Prepare and run the simulation for the Polish grid
fprintf('----------------------------------------------------------\n');
disp('loading the data');
tic
ps = case_ieee_rts_73;
ps.bus(:,C.bu.Pd) = P(:,(Day-1)*24 + Hour);
ps.bus(:,C.bu.Qd) = Q(:,(Day-1)*24 + Hour);
ps.branch(:,C.br.rateA) = ps.branch(:,C.br.rateA)*Rating;
ps.branch(:,C.br.rateB) = ps.branch(:,C.br.rateB)*Rating;
ps.branch(:,C.br.rateC) = ps.branch(:,C.br.rateC)*Rating;
toc
fprintf('----------------------------------------------------------\n');
tic
ps.branch = sortrows(ps.branch,C.br.to);
ps.branch = sortrows(ps.branch,C.br.from);
if ~isfield(ps,'shunt')
    Shunt = ps.bus(:,C.bu.Pd) > 0;
    Shunt_Count = sum(Shunt);
    ps.shunt = [ps.bus(Shunt,C.bu.id),ps.bus(Shunt,C.bu.Pd),ps.bus(Shunt,C.bu.Qd),ones(Shunt_Count,1),zeros(Shunt_Count,1),ones(Shunt_Count,2),ones(Shunt_Count,1)*1000];
    clearvars Shunt Shunt_Count
end
ps = updateps(ps);
ps = redispatch(ps);
Graph = graph(ps.branch(:,C.br.from),ps.branch(:,C.br.to));
ps = dcpf_mod(ps,[],[],[],[],Graph);
toc
fprintf('----------------------------------------------------------\n');

n = size(ps.bus,1);
F = ps.branch(:,C.br.from);
T = ps.branch(:,C.br.to);
X = ps.branch(:,C.br.X);
inv_X = (1./X);
B = sparse(F,T,-inv_X,n,n) + ...
    sparse(T,F,-inv_X,n,n) + ...
    sparse(T,T,+inv_X,n,n) + ...
    sparse(F,F,+inv_X,n,n);


%% Run several cases
opt.verbose = false;
%BOpairs = [nonzeros(BOpairs_List(:,1,Loadset)),nonzeros(BOpairs_List(:,2,Loadset))];
%load(['BOpairs_ieee_rts_73_n-2_',num2str(Loadset),'of_1'],BOpairs);
%BOpairs = nchoosek(1:size(ps.branch,1),2);


for Case = 1:n_Cases
    [~,relay_outages_Temp,MW_lost_base(Case,Hour),~,busessep_Temp] = dcsimsep_mod(ps,BOpairs(Case,:),[],opt,[],B,Delay,Graph,TestType);
    relay_count_base(Case,Hour) = nnz(relay_outages_Temp);      
    buses_count_base(Case,Hour) = nnz(busessep_Temp);

    if MW_lost_base(Case,Hour) > 0
        tic
        fprintf('\n%ds Hour %d Case %d ',Delay,Hour,Case);
        for Relay = 1:n_relays
            [blackout(Relay,Case,Hour),relay_outages_Temp,MW_lost(Relay,Case,Hour),p_out(Relay,Case,Hour),busessep_Temp] = dcsimsep_mod(ps,BOpairs(Case,:),[],opt,Relay,B,Delay,Graph,TestType);
            relay_count(Relay,Case,Hour) = nnz(relay_outages_Temp);      
            buses_count(Relay,Case,Hour) = nnz(busessep_Temp);
        end
        toc
    end
end
end

if sum(sum(MW_lost_base)) > 0 % If there has been at least one cascade, save the results
    save(['BOpairs_ieee_rts_73_n-2_Day_',num2str(Day),'_',num2str(Delay),'s_Type_',num2str(TestType),'.mat'],'blackout','relay_count','relay_count_base','MW_lost','MW_lost_base','p_out','buses_count','buses_count_base');
end
%{
Test_Type = {'10s_Type_1','10s_Type_2','20s_Type_2','30s_Type_2'};
for Delay = 1:4
    File = (['BOpairs_ieee_rts_73_n-2_Day_',num2str(Day),'_',cell2mat(Test_Type(Delay)),'.mat']);
    if exist(File,'file') ~=0
        load(File,'blackout','buses_count','MW_lost','MW_lost_base','p_out','relay_count');
        save(File,'blackout','buses_count','MW_lost','MW_lost_base','p_out','relay_count','relay_count_base','buses_count_base');
    end
end
%}
end
