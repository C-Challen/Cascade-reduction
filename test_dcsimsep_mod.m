function test_dcsimsep_mod(Delay,Start,TestType)

clc

%% Options
%Delay = 30; % Time between initiating outages and intervention response in seconds
%Start = 220; % Starting case


%% get constants that help us to find the data
C = psconstants; % tells me where to find my data

%% set some options
opt = psoptions;
opt.verbose = false; % set this to false if you don't want stuff on the command line

%% Prepare and run the simulation for the Polish grid
fprintf('----------------------------------------------------------\n');
disp('loading the data');
tic
%ps = case_RTS_GMLC_mod;
ps = case2383_mod_ps;
%ps = case2383wp;
toc
fprintf('----------------------------------------------------------\n');
tic
ps.branch = sortrows(ps.branch,C.br.to);
ps.branch = sortrows(ps.branch,C.br.from);
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

load Polish_Results_Initial BOpairs BOpairs_Buses BOpairs_MW BOpairs_Relay
%BOpairs = nchoosek(1:size(ps.branch,1),2);
n_iters = size(ps.branch,1);

for Case = Start:length(BOpairs)
    blackout = zeros(n_iters,1);
    relay_outages = zeros(2896,2,n_iters);
    relay_count = zeros(n_iters,1);
    MW_lost = zeros(n_iters,1);
    p_out = zeros(n_iters,1);
    busessep = zeros(2383,n_iters);
    buses_count = zeros(n_iters,1);
    tic
    fprintf('\n%ds Case %d ',Delay,Case);
    for i = 1:n_iters
        [blackout(i),relay_outages_Temp,MW_lost(i),p_out(i),busessep_Temp] = dcsimsep_mod(ps,BOpairs(Case,:),[],opt,i,B,Delay,Graph,TestType);
        relay_outages(1:size(relay_outages_Temp,1),:,i) = relay_outages_Temp;
        relay_count(i,1) = nnz(relay_outages(:,2,i));
        busessep(1:size(busessep_Temp,1),i) = busessep_Temp;        
        buses_count(i,1) = nnz(busessep(:,i));
    end
    toc
    save(['DCSimSepMod_Results_',num2str(Delay),'s_After_Case_',num2str(Case),' of ',num2str(length(BOpairs)),'.mat'],'blackout','relay_outages','relay_count','MW_lost','p_out','busessep','buses_count');
end

end
