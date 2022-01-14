function test_dcsimsep_mod_rts_110(Loadset,Delay,TestType)
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
%load BOpairs_RTS_n-2 BOpairs Cascade
%BOpairs_List = BOpairs;

%for Loadset = (ID*182-181):(ID*182)
%if Cascade(Loadset) == 1
%% Prepare and run the simulation for the Polish grid
fprintf('----------------------------------------------------------\n');
disp('loading the data');
tic
ps = case_ieee_rts_73;
ps.bus(:,C.bu.Pd) = P(:,Loadset)*1.1;
ps.bus(:,C.bu.Qd) = Q(:,Loadset)*1.1;
%ps = case2383_mod_ps;
%ps = case2383wp;
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
load BOpairs_RTS_n-3_110 BOpairs
%BOpairs = nchoosek(1:size(ps.branch,1),2);
n_iters = size(ps.branch,1);
for Case = 1:size(BOpairs,1)
    blackout = zeros(n_iters,1);
    relay_outages = zeros(2896,2,n_iters);
    relay_count = zeros(n_iters,1);
    MW_lost = zeros(n_iters,1);
    p_out = zeros(n_iters,1);
    busessep = zeros(2383,n_iters);
    buses_count = zeros(n_iters,1);
    [~,~,MW,~,~] = dcsimsep_mod(ps,BOpairs(Case,:),[],opt,[],B,Delay,Graph,TestType);
    if MW > 0
        tic
        fprintf('\n%ds Loadset %d Case %d ',Delay,Loadset,Case);
        for i = 1:n_iters
            [blackout(i),relay_outages_Temp,MW_lost(i),p_out(i),busessep_Temp] = dcsimsep_mod(ps,BOpairs(Case,:),[],opt,i,B,Delay,Graph,TestType);
            relay_outages(1:size(relay_outages_Temp,1),:,i) = relay_outages_Temp;
            relay_count(i,1) = nnz(relay_outages(:,2,i));
            busessep(1:size(busessep_Temp,1),i) = busessep_Temp;        
            buses_count(i,1) = nnz(busessep(:,i));
        end
        toc
        save(['BOpairs_ieee_rts_73_n-3_110_',num2str(Loadset),'_of_8736_',num2str(Delay),'s_Type_',num2str(TestType),'.mat'],'blackout','relay_count','MW_lost','p_out','buses_count');
    end
%end
%end
end
end
