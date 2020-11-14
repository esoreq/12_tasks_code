function output = wrapEcoStackBinModels(id,n,mc,name,data,root,dataID)
%(id,n,mc,name,data,root,dataID)
% fn = c3nl.select('pth','/home/es2814/work/data/12TASKS/ML/Data','name','L2_200_Diff*');
% output = run.wrapEcoStackBinModels(1,1,1,'test',fn,'/home/es2814/work/data/12TASKS','L2_200_Diff')
tic
fprintf('\nLoading Data\n')
r=0;
X = {};
for ii=1:numel(data)
Data.(['I',num2str(ii)]) = load(data{ii});
X{ii} = Data.(['I',num2str(ii)]).X;
end
fprintf('\nPrepareing Data\n')
D=new.folder(name,root,{'results'});
if ~exist(sprintf('%s/output%i.mat',D.results,id),'file')|r
Y = categorical(Data.I1.Y);
S = categorical(Data.I1.S);
rng(22041975);
seeds = randi([1e8,1e9],n,1);
rng(seeds(id));
perf = table();
pc = nchoosek(1:numel(unique(Y)),2);
y = categories(Y);
W = zeros(size(X,2),size(pc,1));
df = zeros(1,size(pc,1));
fprintf('\nModel Data\n')
seeds = randi([1e8,1e9],mc,1);
for ii=1:mc
rng(seeds(ii));
seed = randi([1e8,1e9],1);
tic
for jj=1:size(pc,1)
ix = c3nl.strDetect(cellstr(Y),[y{pc(jj,1)},'|',y{pc(jj,2)}]);
%out = ml.fit.RUSlc(X(ix,:),categorical(cellstr(Y(ix))),S(ix),seed);
xx = {};
for ii=1:numel(X)
    xx{ii} =  X{ii}(ix,:);
end
out = ml.fit.stacked_eco(xx,categorical(cellstr(Y(ix))),categorical(cellstr(S(ix))),seed,dataID);
perf = [perf;[table(repmat(jj,height(out),1),repmat(seed,height(out),1),'VariableNames',{'Iter','Seed'}),out]];

if mod(jj,50);fprintf(char(9783));else; fprintf('\n');end
end
toc
%W(:,ii)= out.W;
if mod(ii,50);fprintf(char(9786));else; fprintf('\n');end
end
fprintf('\nSave results\n')
output.perf = perf;
save([D.results,filesep,sprintf('output%i.mat',id)],'output');

end