function ieee_rts_73_n4_search(ID)
% Determines the BOPairs list
clc

%% get constants that help us to find the data
C = psconstants; % tells me where to find my data

%% set some options
opt = psoptions;
opt.verbose = false; % set this to false if you don't want stuff on the command line

%% Prepare and run the simulation for the Polish grid
fprintf('----------------------------------------------------------\n');
disp('loading the data');
tic
ps = case_ieee_rts_73;
k = 4; % k is the number of failed lines (n-k)
Initial_Lines = nchoosek(1:size(ps.branch,1),k);

toc
fprintf('----------------------------------------------------------\n');
tic

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

n_iters = size(Initial_Lines,1)/91;
Initial_Lines = Initial_Lines(n_iters*ID-n_iters+1:n_iters*ID,:);

    blackout = zeros(n_iters,1);
    relay_count = zeros(n_iters,1);
    MW_lost = zeros(n_iters,1);
    p_out = zeros(n_iters,1);
    buses_count = zeros(n_iters,1);
    tic
    fprintf('Testing pair (of %d):    ',n_iters);
    for i = 1:n_iters
        % run the simulator
        fprintf('\b\b\b\b\b %4d',i);
        [blackout(i),relay_outages_Temp,MW_lost(i),p_out(i),busessep_Temp] = dcsimsep_mod(ps,Initial_Lines(i,:),[],opt,[],B,[],Graph,[]);
        relay_count(i) = nnz(relay_outages_Temp(:,2));    
        buses_count(i) = nnz(busessep_Temp);
    end
    toc
    save(['ieee_rts_73_n-',num2str(k),'_search_',num2str(ID),'_of_91.mat'],'blackout','relay_count','MW_lost','p_out','buses_count','Initial_Lines');
end
