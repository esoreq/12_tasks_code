function output = wrapStackedMCModels(id,n,mc,name,data,root,dataID)
tic
%% o = run.wrapStackedMCModels(1,1000,2,'DG_set',{'/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ML/Data/BA/DG_set.mat','/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ML/Data/BAvx/DG_set.mat','/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ML/Data/PPI/DG_set.mat'},'/group/hampshire_hub/oldeyal/data/12Tasks/exploratory/ML',{'BA','BAvx','PPI'})
% (X,Y,S,seed,dataID,k,ho,coding,v)
fprintf('\nLoading Data\n')
X = {};
for ii=1:numel(data)
Data.(['I',num2str(ii)]) = load(data{ii});
X{ii} = Data.(['I',num2str(ii)]).X;
end
fprintf('\nPrepare Data\n')
D=new.folder(name,root,{'results'});
if ~exist(sprintf('%s/output%i.mat',D.results,id),'file')
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for jj=1:mc % montecarlo steps 
rng(seeds(jj));
seed = randi([1e8,1e9],1);
tic
out = ml.fit.stacked_eco(X,categorical(Data.I1.Y),categorical(Data.I1.S),seed,dataID);
toc
perf = [perf;[table(repmat(jj,height(out),1),repmat(seed,height(out),1),'VariableNames',{'Iter','Seed'}),out]];
if mod(ii,50)&ii~=mc;fprintf(char(9783));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save(sprintf('%s/output%i.mat',D.results,id),'output');
else
output =0;
end
end