function test_dcsimsep_mod_initial_rts
% Determines the BOPairs list
clc

%% get constants that help us to find the data
C = psconstants; % tells me where to find my data

%% set some options
opt = psoptions;
opt.verbose = false; % set this to false if you don't want stuff on the command line

ps = case_ieee_rts_73;

Rating = 0.6; % Percentage amount to adjust line rating by
k = 2; % k is the number of failed lines (n-k)
Initial_Lines = nchoosek(1:size(ps.branch,1),k);
n_iters = size(Initial_Lines,1);
blackout = zeros(n_iters,1);
relay_count = zeros(n_iters,1);
relay_outages = zeros(size(ps.branch,1),2,n_iters);
MW_lost = zeros(n_iters,1);
p_out = zeros(n_iters,1);
buses_count = zeros(n_iters,1);

%% Prepare and run the simulation for the Polish grid
fprintf('----------------------------------------------------------\n');
disp('loading the data');
tic
ps = case_ieee_rts_73;
ps.branch(:,C.br.rateA) = ps.branch(:,C.br.rateA) .* Rating;
ps.branch(:,C.br.rateB) = ps.branch(:,C.br.rateB) .* Rating;
ps.branch(:,C.br.rateC) = ps.branch(:,C.br.rateC) .* Rating;
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
    tic
    %fprintf('Testing pair (of %d):    ',n_iters);
    for i = 1:n_iters
        % run the simulator
        %fprintf('\b\b\b\b\b %4d',i);
        [blackout(i),relay_outages_Temp,MW_lost(i),p_out(i),busessep_Temp] = dcsimsep_mod(ps,Initial_Lines(i,:),[],opt,[],B,[],Graph,[]);
        relay_outages(1:size(relay_outages_Temp,1),:,i) = relay_outages_Temp;
        relay_count(i) = nnz(relay_outages_Temp(:,2));    
        buses_count(i) = nnz(busessep_Temp);
    end
    toc  
    save(['BOpairs_RTS_n-',num2str(k),'_',num2str(Rating*100),'%_Rating.mat'],'blackout','relay_count','relay_outages','MW_lost','p_out','buses_count','Initial_Lines');
end
